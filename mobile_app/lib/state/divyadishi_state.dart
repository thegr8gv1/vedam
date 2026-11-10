import 'package:flutter/foundation.dart';
import '../core/models/bearing_result.dart';
import '../core/models/corrected_heading_reading.dart';
import '../core/models/declination_model.dart';
import '../core/models/heading_model.dart';
import '../core/models/sacred_origin.dart';
import '../core/models/temple.dart';
import '../core/services/compass_service.dart';
import '../core/services/geographic_bearing_calculator.dart';
import '../core/services/geomagnetic_declination_service.dart';
import '../core/services/temple_directory_service.dart';

/// State management for the DivyaDishi (Divine Direction) feature.
/// Manages the temple directory, origin selection (with zero device GPS permissions),
/// search/filtering, geographic bearing calculations, foreground live compass,
/// and offline geomagnetic declination for True North correction and relative sacred alignment.
class DivyaDishiState extends ChangeNotifier {
  final TempleDirectoryService _directoryService;
  final GeographicBearingCalculator _calculator;
  final CompassService compassService;
  final GeomagneticDeclinationService _declinationService;

  SacredOrigin? _selectedOrigin;
  DeclinationResult? _currentDeclination;
  String _searchQuery = '';
  String? _selectedCountry;
  TempleTradition? _selectedTradition;
  CoordinateVerificationStatus? _selectedStatus;

  List<Temple> _filteredTemples = [];

  DivyaDishiState({
    TempleDirectoryService? directoryService,
    GeographicBearingCalculator? calculator,
    CompassService? compassService,
    GeomagneticDeclinationService? declinationService,
    SacredOrigin? initialOrigin,
  })  : _directoryService = directoryService ?? TempleDirectoryService(),
        _calculator = calculator ?? const GeographicBearingCalculator(),
        compassService = compassService ?? CompassService(),
        _declinationService = declinationService ?? const GeomagneticDeclinationService(),
        _selectedOrigin = initialOrigin {
    if (_selectedOrigin != null) {
      _currentDeclination = _declinationService.calculateDeclination(origin: _selectedOrigin!);
    }
    _applyFilters();
  }

  // Getters
  SacredOrigin? get selectedOrigin => _selectedOrigin;
  DeclinationResult? get currentDeclination => _currentDeclination;
  GeomagneticDeclinationService get declinationService => _declinationService;
  String get searchQuery => _searchQuery;
  String? get selectedCountry => _selectedCountry;
  TempleTradition? get selectedTradition => _selectedTradition;
  CoordinateVerificationStatus? get selectedStatus => _selectedStatus;
  List<Temple> get temples => _filteredTemples;
  int get totalTempleCount => _directoryService.getAllTemples().length;

  List<String> get availableCountries => _directoryService.getAvailableCountries();
  List<TempleTradition> get availableTraditions => _directoryService.getAvailableTraditions();

  /// Updates the origin point for bearing and declination calculations.
  ///
  /// CRITICAL PRIVACY & INVARIANT:
  /// When origin changes, previous declination is immediately invalidated and recalculated
  /// for the new origin. Zero location history is stored.
  void setOrigin(SacredOrigin? origin) {
    if (_selectedOrigin != origin) {
      _selectedOrigin = origin;
      if (origin != null) {
        _currentDeclination = _declinationService.calculateDeclination(origin: origin);
      } else {
        _currentDeclination = null;
      }
      notifyListeners();
    }
  }

  /// Sets the search query filter.
  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  /// Sets the country filter ('India', 'Nepal', or null/empty for all).
  void setCountryFilter(String? country) {
    _selectedCountry = (country == null || country == 'All') ? null : country;
    _applyFilters();
  }

  /// Sets the spiritual tradition filter.
  void setTraditionFilter(TempleTradition? tradition) {
    _selectedTradition = tradition;
    _applyFilters();
  }

  /// Sets coordinate verification status filter.
  void setStatusFilter(CoordinateVerificationStatus? status) {
    _selectedStatus = status;
    _applyFilters();
  }

  /// Resets all search and filter parameters.
  void resetFilters() {
    _searchQuery = '';
    _selectedCountry = null;
    _selectedTradition = null;
    _selectedStatus = null;
    _applyFilters();
  }

  /// Calculates the initial forward azimuth and distance from the selected origin to the temple.
  /// If no origin is selected, returns [BearingResult.unavailable].
  BearingResult calculateBearing(Temple temple) {
    if (_selectedOrigin == null) {
      return BearingResult.unavailable(
        reason: 'Select an origin to calculate geographic direction',
      );
    }
    final isApprox = _selectedOrigin!.isApproximate ||
        temple.verificationStatus != CoordinateVerificationStatus.verified ||
        temple.pointType != CoordinatePointType.innerSanctum;

    return _calculator.calculateBearing(
      origin: _selectedOrigin!.coordinate,
      destination: temple.coordinate,
      isApproximate: isApprox,
      provisionalDisclaimer: isApprox
          ? 'Calculated from ${_selectedOrigin!.isApproximate ? "approximate city origin" : "origin"} to ${_selectedOrigin!.isApproximate ? "provisional temple coordinate" : "temple location"}. Devotional orientation aid only.'
          : null,
    );
  }

  /// Derives the true geographic heading from raw magnetic compass reading and current declination.
  CorrectedHeadingReading getCorrectedHeading(HeadingReading raw) {
    return CorrectedHeadingReading.fromReadingAndDeclination(
      raw: raw,
      declination: _currentDeclination,
      expectedOrigin: _selectedOrigin,
    );
  }

  /// Evaluates relative sacred alignment between current heading and a target temple.
  /// Requires explicit [userOptedIn] when target coordinates are provisional.
  RelativeSacredAlignment calculateRelativeAlignment(
    Temple temple,
    HeadingReading raw, {
    bool userOptedIn = false,
  }) {
    final corrected = getCorrectedHeading(raw);
    final bearing = calculateBearing(temple);
    return RelativeSacredAlignment.evaluate(
      correctedHeading: corrected,
      targetBearing: bearing,
      targetTemple: temple,
      currentOrigin: _selectedOrigin,
      userOptedIn: userOptedIn,
    );
  }

  void _applyFilters() {
    _filteredTemples = _directoryService.searchAndFilter(
      query: _searchQuery,
      country: _selectedCountry,
      tradition: _selectedTradition,
      status: _selectedStatus,
    );
    notifyListeners();
  }

  @override
  void dispose() {
    compassService.dispose();
    super.dispose();
  }
}

import 'package:flutter/foundation.dart';
import '../core/models/bearing_result.dart';
import '../core/models/sacred_origin.dart';
import '../core/models/temple.dart';
import '../core/services/compass_service.dart';
import '../core/services/geographic_bearing_calculator.dart';
import '../core/services/temple_directory_service.dart';

/// State management for the DivyaDishi (Divine Direction) feature.
/// Manages the temple directory, origin selection (with zero device GPS permissions),
/// search/filtering, geographic bearing calculations, and foreground-only live compass.
class DivyaDishiState extends ChangeNotifier {
  final TempleDirectoryService _directoryService;
  final GeographicBearingCalculator _calculator;
  final CompassService compassService;

  SacredOrigin? _selectedOrigin;
  String _searchQuery = '';
  String? _selectedCountry;
  TempleTradition? _selectedTradition;
  CoordinateVerificationStatus? _selectedStatus;

  List<Temple> _filteredTemples = [];

  DivyaDishiState({
    TempleDirectoryService? directoryService,
    GeographicBearingCalculator? calculator,
    CompassService? compassService,
    SacredOrigin? initialOrigin,
  })  : _directoryService = directoryService ?? TempleDirectoryService(),
        _calculator = calculator ?? const GeographicBearingCalculator(),
        compassService = compassService ?? CompassService(),
        _selectedOrigin = initialOrigin {
    _applyFilters();
  }

  // Getters
  SacredOrigin? get selectedOrigin => _selectedOrigin;
  String get searchQuery => _searchQuery;
  String? get selectedCountry => _selectedCountry;
  TempleTradition? get selectedTradition => _selectedTradition;
  CoordinateVerificationStatus? get selectedStatus => _selectedStatus;
  List<Temple> get temples => _filteredTemples;
  int get totalTempleCount => _directoryService.getAllTemples().length;

  List<String> get availableCountries => _directoryService.getAvailableCountries();
  List<TempleTradition> get availableTraditions => _directoryService.getAvailableTraditions();

  /// Updates the origin point for bearing calculations.
  void setOrigin(SacredOrigin? origin) {
    if (_selectedOrigin != origin) {
      _selectedOrigin = origin;
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

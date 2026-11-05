import 'package:flutter/foundation.dart';
import '../core/models/panchangam_data.dart';
import '../data/repositories/panchangam_repository.dart';

class PanchangamState extends ChangeNotifier {
  final PanchangamRepository _repository;

  DateTime _selectedDate;
  PanchangamLocation _selectedLocation;
  String _selectedAyanamsa;

  DailyPanchangamData? _data;
  bool _isLoading = false;
  bool _isUnavailable = false;
  String? _errorMessage;

  PanchangamState({
    required PanchangamRepository repository,
    DateTime? initialDate,
    PanchangamLocation? initialLocation,
    String initialAyanamsa = 'lahiri',
  })  : _repository = repository,
        _selectedDate = initialDate ?? DateTime.now(),
        _selectedLocation = initialLocation ?? PanchangamLocation.varanasi,
        _selectedAyanamsa = initialAyanamsa;

  // Getters
  DateTime get selectedDate => _selectedDate;
  PanchangamLocation get selectedLocation => _selectedLocation;
  String get selectedAyanamsa => _selectedAyanamsa;
  DailyPanchangamData? get data => _data;
  bool get isLoading => _isLoading;
  bool get isUnavailable => _isUnavailable;
  String? get errorMessage => _errorMessage;

  Future<void> loadPanchangam() async {
    _isLoading = true;
    _isUnavailable = false;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _repository.getDailyPanchangam(
        date: _selectedDate,
        location: _selectedLocation,
        ayanamsa: _selectedAyanamsa,
      );
      _data = result;
      _isLoading = false;
      _isUnavailable = false;
      _errorMessage = null;
    } catch (e) {
      _isLoading = false;
      _isUnavailable = true;
      if (e is PanchangamUnavailableException) {
        _errorMessage = '${e.message}\n${e.details}';
      } else {
        _errorMessage = e.toString();
      }
    }
    notifyListeners();
  }

  void goToNextDay() {
    _selectedDate = _selectedDate.add(const Duration(days: 1));
    loadPanchangam();
  }

  void goToPreviousDay() {
    _selectedDate = _selectedDate.subtract(const Duration(days: 1));
    loadPanchangam();
  }

  void goToDate(DateTime newDate) {
    _selectedDate = newDate;
    loadPanchangam();
  }

  void setLocation(PanchangamLocation location) {
    _selectedLocation = location;
    loadPanchangam();
  }

  void setAyanamsa(String ayanamsa) {
    _selectedAyanamsa = ayanamsa;
    loadPanchangam();
  }

  void refresh() {
    loadPanchangam();
  }
}

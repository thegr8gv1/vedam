import 'package:flutter/material.dart';
import '../core/models/scripture.dart';
import '../data/repositories/scripture_repository.dart';

class ScriptureState extends ChangeNotifier {
  final ScriptureRepository _repository;

  List<Scripture> _allScriptures = [];
  List<Scripture> _filteredScriptures = [];
  String _selectedCategory = 'All Categories';
  String _selectedDeity = 'All Deities';
  String _searchQuery = '';
  bool _isLoading = true;

  ScriptureState(this._repository) {
    loadScriptures();
  }

  List<Scripture> get filteredScriptures => _filteredScriptures;
  String get selectedCategory => _selectedCategory;
  String get selectedDeity => _selectedDeity;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;

  Future<void> loadScriptures() async {
    _isLoading = true;
    notifyListeners();
    _allScriptures = await _repository.getAllScriptures();
    _applyFilters();
    _isLoading = false;
    notifyListeners();
  }

  void setCategory(String category) {
    _selectedCategory = category;
    _applyFilters();
    notifyListeners();
  }

  void setDeity(String deity) {
    _selectedDeity = deity;
    _applyFilters();
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  void resetFilters() {
    _selectedCategory = 'All Categories';
    _selectedDeity = 'All Deities';
    _searchQuery = '';
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    _filteredScriptures = _allScriptures.where((s) {
      final matchesCategory = _selectedCategory == 'All Categories' ||
          s.category.toLowerCase() == _selectedCategory.toLowerCase();

      final matchesDeity = _selectedDeity == 'All Deities' ||
          s.deity.toLowerCase().contains(_selectedDeity.toLowerCase()) ||
          _selectedDeity.toLowerCase().contains(s.deity.toLowerCase());

      final cleanQuery = _searchQuery.trim().toLowerCase();
      final matchesQuery = cleanQuery.isEmpty ||
          s.canonicalTitle.toLowerCase().contains(cleanQuery) ||
          s.devanagariTitle.toLowerCase().contains(cleanQuery) ||
          s.deity.toLowerCase().contains(cleanQuery) ||
          s.composer.toLowerCase().contains(cleanQuery);

      return matchesCategory && matchesDeity && matchesQuery;
    }).toList();
  }
}

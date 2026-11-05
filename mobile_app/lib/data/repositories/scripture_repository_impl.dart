import '../../core/constants/app_constants.dart';
import '../../core/models/scripture.dart';
import '../../core/models/daily_darshan.dart';
import '../fixtures/authentic_scriptures_data.dart';
import 'scripture_repository.dart';

class ScriptureRepositoryImpl implements ScriptureRepository {
  final List<Scripture> _scriptures;

  ScriptureRepositoryImpl({List<Scripture>? scriptures})
      : _scriptures = scriptures ?? kAuthenticScriptures;

  @override
  Future<List<Scripture>> getAllScriptures() async {
    return List.unmodifiable(_scriptures);
  }

  @override
  Future<List<Scripture>> getScripturesByCategory(String category) async {
    if (category == 'All Categories' || category.isEmpty) {
      return getAllScriptures();
    }
    return _scriptures
        .where((s) => s.category.toLowerCase() == category.toLowerCase())
        .toList();
  }

  @override
  Future<List<Scripture>> getScripturesByDeity(String deity) async {
    if (deity == 'All Deities' || deity.isEmpty) {
      return getAllScriptures();
    }
    return _scriptures
        .where((s) => s.deity.toLowerCase().contains(deity.toLowerCase()) ||
                      deity.toLowerCase().contains(s.deity.toLowerCase()))
        .toList();
  }

  @override
  Future<List<Scripture>> searchScriptures(String query) async {
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) {
      return getAllScriptures();
    }
    return _scriptures.where((s) {
      final inCanonical = s.canonicalTitle.toLowerCase().contains(clean);
      final inDevanagari = s.devanagariTitle.toLowerCase().contains(clean);
      final inDeity = s.deity.toLowerCase().contains(clean);
      final inCategory = s.category.toLowerCase().contains(clean);
      final inComposer = s.composer.toLowerCase().contains(clean);
      return inCanonical || inDevanagari || inDeity || inCategory || inComposer;
    }).toList();
  }

  @override
  Future<Scripture?> getScriptureById(int id) async {
    try {
      return _scriptures.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<DailyDarshan> getDailyDarshan() async {
    return DailyDarshan.today();
  }

  @override
  List<String> getCategories() {
    return AppConstants.categories;
  }

  @override
  List<String> getDeities() {
    return AppConstants.deities;
  }
}

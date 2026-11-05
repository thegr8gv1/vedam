import '../../core/models/scripture.dart';
import '../../core/models/daily_darshan.dart';

abstract class ScriptureRepository {
  Future<List<Scripture>> getAllScriptures();
  Future<List<Scripture>> getScripturesByCategory(String category);
  Future<List<Scripture>> getScripturesByDeity(String deity);
  Future<List<Scripture>> searchScriptures(String query);
  Future<Scripture?> getScriptureById(int id);
  Future<DailyDarshan> getDailyDarshan();
  List<String> getCategories();
  List<String> getDeities();
}

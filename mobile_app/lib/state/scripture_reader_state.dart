import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/models/scripture.dart';
import '../core/models/verse.dart';
import '../core/models/scripture_user_data.dart';

/// State and local persistence management for bookmarks, study notes,
/// reading progress, and accessibility/reading preferences.
class ScriptureReaderState extends ChangeNotifier {
  static const String _prefsKeyBookmarks = 'vedam_bookmarks_v1';
  static const String _prefsKeyNotes = 'vedam_verse_notes_v1';
  static const String _prefsKeyProgress = 'vedam_reading_progress_v1';
  static const String _prefsKeyPrefs = 'vedam_reading_preferences_v1';

  final SharedPreferences? _injectedPrefs;

  Map<String, VerseBookmark> _bookmarks = {};
  Map<String, VerseNote> _notes = {};
  Map<int, ReadingProgress> _progress = {};
  ReadingPreferences _preferences = const ReadingPreferences();
  bool _isLoaded = false;

  ScriptureReaderState({SharedPreferences? prefs}) : _injectedPrefs = prefs {
    _initialize();
  }

  /// Explicit initialization future for testing and preloading
  Future<void> init() => _initialize();

  // Getters
  bool get isLoaded => _isLoaded;
  List<VerseBookmark> get allBookmarks =>
      _bookmarks.values.toList()..sort((a, b) => b.bookmarkedAt.compareTo(a.bookmarkedAt));
  List<VerseNote> get allNotes =>
      _notes.values.toList()..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  Map<int, ReadingProgress> get allProgress => Map.unmodifiable(_progress);
  ReadingPreferences get preferences => _preferences;

  // Bookmarks
  bool isBookmarked(String globalVerseId) => _bookmarks.containsKey(globalVerseId);

  VerseBookmark? getBookmark(String globalVerseId) => _bookmarks[globalVerseId];

  List<VerseBookmark> getBookmarksForScripture(int scriptureId) =>
      _bookmarks.values.where((b) => b.scriptureId == scriptureId).toList();

  Future<void> toggleBookmark(Verse verse, Scripture scripture) async {
    final gId = verse.globalId(scripture.contentId);
    if (_bookmarks.containsKey(gId)) {
      _bookmarks.remove(gId);
    } else {
      final snippet = verse.devanagariText.split('\n').first;
      _bookmarks[gId] = VerseBookmark(
        verseId: gId,
        scriptureId: scripture.id,
        scriptureContentId: scripture.contentId,
        scriptureTitle: scripture.canonicalTitle,
        verseNumber: verse.verseNumber,
        verseSnippet: snippet,
        bookmarkedAt: DateTime.now().toIso8601String(),
      );
    }
    notifyListeners();
    await _saveBookmarks();
  }

  Future<void> removeBookmark(String globalVerseId) async {
    if (_bookmarks.containsKey(globalVerseId)) {
      _bookmarks.remove(globalVerseId);
      notifyListeners();
      await _saveBookmarks();
    }
  }

  // Personal Study Notes
  VerseNote? getNote(String globalVerseId) => _notes[globalVerseId];

  Future<void> saveNote(Verse verse, Scripture scripture, String noteText) async {
    final gId = verse.globalId(scripture.contentId);
    final trimmed = noteText.trim();
    if (trimmed.isEmpty) {
      if (_notes.containsKey(gId)) {
        _notes.remove(gId);
        notifyListeners();
        await _saveNotes();
      }
      return;
    }

    _notes[gId] = VerseNote(
      verseId: gId,
      scriptureId: scripture.id,
      scriptureContentId: scripture.contentId,
      scriptureTitle: scripture.canonicalTitle,
      verseNumber: verse.verseNumber,
      noteText: trimmed,
      updatedAt: DateTime.now().toIso8601String(),
    );
    notifyListeners();
    await _saveNotes();
  }

  Future<void> deleteNote(String globalVerseId) async {
    if (_notes.containsKey(globalVerseId)) {
      _notes.remove(globalVerseId);
      notifyListeners();
      await _saveNotes();
    }
  }

  // Reading Progress
  ReadingProgress? getProgress(int scriptureId) => _progress[scriptureId];

  Future<void> recordReadingProgress(Scripture scripture, int verseNumber) async {
    final existing = _progress[scripture.id];
    final completed = existing != null
        ? Set<int>.from(existing.completedVerseNumbers)
        : <int>{};
    completed.add(verseNumber);

    _progress[scripture.id] = ReadingProgress(
      scriptureId: scripture.id,
      scriptureContentId: scripture.contentId,
      lastReadVerseNumber: verseNumber,
      lastReadVerseId: scripture.verses.length >= verseNumber
          ? scripture.verses[verseNumber - 1].globalId(scripture.contentId)
          : '$verseNumber',
      totalVerses: scripture.verseCount,
      completedVerseNumbers: completed,
      lastReadAt: DateTime.now().toIso8601String(),
    );
    notifyListeners();
    await _saveProgress();
  }

  // Reading Preferences
  Future<void> updatePreferences(ReadingPreferences newPrefs) async {
    _preferences = newPrefs;
    notifyListeners();
    await _savePreferences();
  }

  Future<void> resetPreferences() async {
    _preferences = const ReadingPreferences();
    notifyListeners();
    await _savePreferences();
  }

  // Initialization and persistence internals
  Future<SharedPreferences> _getPrefs() async {
    if (_injectedPrefs != null) return _injectedPrefs;
    return await SharedPreferences.getInstance();
  }

  Future<void> _initialize() async {
    try {
      final prefs = await _getPrefs();

      // 1. Bookmarks
      final rawBookmarks = prefs.getString(_prefsKeyBookmarks);
      if (rawBookmarks != null && rawBookmarks.isNotEmpty) {
        final List<dynamic> list = jsonDecode(rawBookmarks) as List<dynamic>;
        _bookmarks = {
          for (final item in list)
            (item as Map<String, dynamic>)['verseId'] as String:
                VerseBookmark.fromJson(item)
        };
      }

      // 2. Notes
      final rawNotes = prefs.getString(_prefsKeyNotes);
      if (rawNotes != null && rawNotes.isNotEmpty) {
        final List<dynamic> list = jsonDecode(rawNotes) as List<dynamic>;
        _notes = {
          for (final item in list)
            (item as Map<String, dynamic>)['verseId'] as String:
                VerseNote.fromJson(item)
        };
      }

      // 3. Progress
      final rawProgress = prefs.getString(_prefsKeyProgress);
      if (rawProgress != null && rawProgress.isNotEmpty) {
        final List<dynamic> list = jsonDecode(rawProgress) as List<dynamic>;
        _progress = {
          for (final item in list)
            (item as Map<String, dynamic>)['scriptureId'] as int:
                ReadingProgress.fromJson(item)
        };
      }

      // 4. Preferences
      final rawPrefs = prefs.getString(_prefsKeyPrefs);
      if (rawPrefs != null && rawPrefs.isNotEmpty) {
        _preferences = ReadingPreferences.fromJson(
            jsonDecode(rawPrefs) as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('Error initializing ScriptureReaderState: $e');
    } finally {
      _isLoaded = true;
      notifyListeners();
    }
  }

  Future<void> _saveBookmarks() async {
    try {
      final prefs = await _getPrefs();
      final list = _bookmarks.values.map((b) => b.toJson()).toList();
      await prefs.setString(_prefsKeyBookmarks, jsonEncode(list));
    } catch (e) {
      debugPrint('Error saving bookmarks: $e');
    }
  }

  Future<void> _saveNotes() async {
    try {
      final prefs = await _getPrefs();
      final list = _notes.values.map((n) => n.toJson()).toList();
      await prefs.setString(_prefsKeyNotes, jsonEncode(list));
    } catch (e) {
      debugPrint('Error saving notes: $e');
    }
  }

  Future<void> _saveProgress() async {
    try {
      final prefs = await _getPrefs();
      final list = _progress.values.map((p) => p.toJson()).toList();
      await prefs.setString(_prefsKeyProgress, jsonEncode(list));
    } catch (e) {
      debugPrint('Error saving reading progress: $e');
    }
  }

  Future<void> _savePreferences() async {
    try {
      final prefs = await _getPrefs();
      await prefs.setString(_prefsKeyPrefs, jsonEncode(_preferences.toJson()));
    } catch (e) {
      debugPrint('Error saving reading preferences: $e');
    }
  }
}

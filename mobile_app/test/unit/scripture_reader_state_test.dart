import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vedam_app/core/models/verse.dart';
import 'package:vedam_app/data/repositories/scripture_repository_impl.dart';
import 'package:vedam_app/state/scripture_reader_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ScriptureRepositoryImpl repository;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repository = ScriptureRepositoryImpl();
  });

  group('ScriptureReaderState Unit & Persistence Tests', () {
    test('Initial state defaults match requirements', () async {
      final state = ScriptureReaderState();
      await state.init();

      expect(state.allBookmarks, isEmpty);
      expect(state.allNotes, isEmpty);
      expect(state.allProgress, isEmpty);

      final prefs = state.preferences;
      expect(prefs.preferredScript, equals(ScriptOption.devanagari));
      expect(prefs.sanskritFontSize, equals(20.0));
      expect(prefs.transliterationFontSize, equals(15.0));
      expect(prefs.translationFontSize, equals(14.0));
      expect(prefs.lineSpacing, equals(1.6));
      expect(prefs.showTransliteration, isTrue);
      expect(prefs.showTranslation, isTrue);
    });

    test('Bookmark lifecycle: add, duplicate check, query, and remove', () async {
      final state = ScriptureReaderState();
      await state.init();

      final ganesha = (await repository.getScriptureById(1))!;
      final verse1 = ganesha.verses[0];
      final verse2 = ganesha.verses[1];
      final gId1 = verse1.globalId(ganesha.contentId);
      final gId2 = verse2.globalId(ganesha.contentId);

      // 1. Initial check
      expect(state.isBookmarked(gId1), isFalse);

      // 2. Add bookmark
      await state.toggleBookmark(verse1, ganesha);
      expect(state.isBookmarked(gId1), isTrue);
      expect(state.allBookmarks.length, equals(1));
      expect(state.allBookmarks.first.scriptureId, equals(1));
      expect(state.allBookmarks.first.verseNumber, equals(1));

      // 3. Add second bookmark on same scripture
      await state.toggleBookmark(verse2, ganesha);
      expect(state.allBookmarks.length, equals(2));
      expect(state.getBookmarksForScripture(1).length, equals(2));

      // 4. Toggle existing bookmark (should remove)
      await state.toggleBookmark(verse1, ganesha);
      expect(state.isBookmarked(gId1), isFalse);
      expect(state.allBookmarks.length, equals(1));
      expect(state.allBookmarks.first.verseId, equals(gId2));

      // 5. Explicit remove
      await state.removeBookmark(gId2);
      expect(state.allBookmarks, isEmpty);
    });

    test('Study Notes lifecycle: add, retrieve, edit, and delete', () async {
      final state = ScriptureReaderState();
      await state.init();

      final ganesha = (await repository.getScriptureById(1))!;
      final verse2 = ganesha.verses[1];
      final gId2 = verse2.globalId(ganesha.contentId);

      expect(state.getNote(gId2), isNull);

      // 1. Save new note
      await state.saveNote(
        verse2,
        ganesha,
        'Contemplate on Modaka as supreme spiritual wisdom.',
      );

      final note = state.getNote(gId2);
      expect(note, isNotNull);
      expect(note!.noteText, equals('Contemplate on Modaka as supreme spiritual wisdom.'));
      expect(note.verseNumber, equals(2));
      expect(note.scriptureId, equals(1));

      // 2. Edit existing note
      await state.saveNote(
        verse2,
        ganesha,
        'Updated reflection: Modaka represents blissful enlightenment.',
      );

      final updatedNote = state.getNote(gId2);
      expect(updatedNote!.noteText, equals('Updated reflection: Modaka represents blissful enlightenment.'));
      expect(state.allNotes.length, equals(1));

      // 3. Delete note
      await state.deleteNote(gId2);
      expect(state.getNote(gId2), isNull);
      expect(state.allNotes, isEmpty);
    });

    test('Reading Progress tracking and percentage calculation', () async {
      final state = ScriptureReaderState();
      await state.init();

      final ganesha = (await repository.getScriptureById(1))!;

      expect(state.getProgress(ganesha.id), isNull);

      // Verse 3 of 6 (1 completed)
      await state.recordReadingProgress(ganesha, 3);
      var progress = state.getProgress(ganesha.id);
      expect(progress, isNotNull);
      expect(progress!.lastReadVerseNumber, equals(3));
      expect(progress.totalVerses, equals(6));
      expect(progress.percentCompleted, closeTo(0.1666, 0.05));

      // Mark all verses read
      for (int i = 1; i <= 6; i++) {
        await state.recordReadingProgress(ganesha, i);
      }
      progress = state.getProgress(ganesha.id);
      expect(progress!.percentCompleted, closeTo(1.0, 0.01));
      expect(progress.isCompleted, isTrue);
    });

    test('Reading Preferences customization and reset', () async {
      final state = ScriptureReaderState();
      await state.init();

      // Update preferences
      final customPrefs = state.preferences.copyWith(
        sanskritFontSize: 28.0,
        lineSpacing: 1.8,
        showTransliteration: false,
        preferredScript: ScriptOption.telugu,
      );
      await state.updatePreferences(customPrefs);

      expect(state.preferences.sanskritFontSize, equals(28.0));
      expect(state.preferences.lineSpacing, equals(1.8));
      expect(state.preferences.showTransliteration, isFalse);
      expect(state.preferences.preferredScript, equals(ScriptOption.telugu));

      // Reset
      await state.resetPreferences();
      expect(state.preferences.sanskritFontSize, equals(20.0));
      expect(state.preferences.lineSpacing, equals(1.6));
      expect(state.preferences.showTransliteration, isTrue);
    });

    test('Local SharedPreferences persistence reloads saved state on app restart', () async {
      final ganesha = (await repository.getScriptureById(1))!;
      final verse1 = ganesha.verses[0];
      final gId1 = verse1.globalId(ganesha.contentId);

      // 1. Session 1 writes data
      final stateSession1 = ScriptureReaderState();
      await stateSession1.init();

      await stateSession1.toggleBookmark(verse1, ganesha);
      await stateSession1.saveNote(verse1, ganesha, 'Important dhyana shloka');
      await stateSession1.recordReadingProgress(ganesha, 4);
      await stateSession1.updatePreferences(
        stateSession1.preferences.copyWith(sanskritFontSize: 26.0),
      );

      // 2. Session 2 initializes independently from same SharedPreferences
      final stateSession2 = ScriptureReaderState();
      await stateSession2.init();

      // Verify all data restored accurately
      expect(stateSession2.isBookmarked(gId1), isTrue);
      expect(stateSession2.allBookmarks.length, equals(1));
      expect(stateSession2.getNote(gId1)?.noteText, equals('Important dhyana shloka'));
      expect(stateSession2.getProgress(1)?.lastReadVerseNumber, equals(4));
      expect(stateSession2.preferences.sanskritFontSize, equals(26.0));
    });
  });
}

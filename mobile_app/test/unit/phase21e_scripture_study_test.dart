import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vedam_app/core/models/scripture.dart';
import 'package:vedam_app/core/models/verse.dart';
import 'package:vedam_app/data/fixtures/authentic_scriptures_data.dart';
import 'package:vedam_app/state/scripture_reader_state.dart';

void main() {
  group('Phase 21E — Part B: Scripture Learning & Content Trust Unit Tests', () {
    late SharedPreferences prefs;
    late ScriptureReaderState readerState;
    late Scripture gita;
    late Verse testVerse;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      readerState = ScriptureReaderState(prefs: prefs);
      await readerState.init();

      gita = kAuthenticScriptures.firstWhere(
        (s) => s.contentId == 'BG-001' || s.canonicalTitle.contains('Bhagavad'),
        orElse: () => kAuthenticScriptures.first,
      );
      testVerse = gita.verses.first;
    });

    test('1. Verse model provides structured Padartha, Literal, and Commentary fields', () {
      final verse = Verse(
        id: 'bg_01_01',
        verseNumber: 1,
        devanagariText: 'धर्मक्षेत्रे कुरुक्षेत्रे समवेता युयुत्सवः ।\nमामकाः पाण्डवाश्चैव किमकुर्वत सञ्जय ॥',
        iastText: 'dharmakṣetre kurukṣetre samavetā yuyutsavaḥ |',
        draftTranslation: 'O Sanjaya, assembled on the holy field of Kurukshetra...',
        literalTranslation: 'In the field of Dharma, in the field of the Kurus, gathered eager for battle...',
        wordByWord: {
          'धर्मक्षेत्रे': 'in the holy field of righteous action',
          'कुरुक्षेत्रे': 'in the land of the Kurus',
          'समवेताः': 'assembled together',
          'युयुत्सवः': 'desiring to fight',
        },
        commentary: 'The opening verse sets the symbolic and literal stage for the sacred dialogue.',
        sourceReference: 'Classical Vedantic Exegesis (Section 8 Draft)',
      );

      expect(verse.hasLiteralTranslation, isTrue);
      expect(verse.hasWordByWord, isTrue);
      expect(verse.hasAlternativeTranslations, isTrue);
      expect(verse.wordByWord!['धर्मक्षेत्रे'], contains('righteous action'));
      expect(verse.sourceReference, contains('Section 8'));
    });

    test('2. Scripture model completeness getters calculate availability across real content', () {
      expect(gita.hasOriginalSanskrit, isTrue);
      expect(gita.hasTransliteration, isTrue);
      expect(gita.hasTranslation, isTrue);
      expect(gita.verseCount, greaterThan(0));
      expect(gita.versesWithTranslationCount, greaterThan(0));
      expect(gita.versesWithTranslationCount, lessThanOrEqualTo(gita.verseCount));
      expect(gita.versesWithAudioCount, lessThanOrEqualTo(gita.verseCount));
    });

    test('3. Bookmark lifecycle: add, duplicate prevention, retrieve, remove, and persist', () async {
      expect(readerState.isBookmarked(testVerse.globalId(gita.contentId)), isFalse);

      // Add bookmark
      await readerState.toggleBookmark(testVerse, gita);
      expect(readerState.isBookmarked(testVerse.globalId(gita.contentId)), isTrue);

      final bookmarks = readerState.getBookmarksForScripture(gita.id);
      expect(bookmarks.length, equals(1));
      expect(bookmarks.first.verseNumber, equals(testVerse.verseNumber));
      expect(bookmarks.first.scriptureContentId, equals(gita.contentId));

      // Duplicate toggle toggles off
      await readerState.toggleBookmark(testVerse, gita);
      expect(readerState.isBookmarked(testVerse.globalId(gita.contentId)), isFalse);
      expect(readerState.getBookmarksForScripture(gita.id).isEmpty, isTrue);

      // Re-add and verify persistence across fresh reader state
      await readerState.toggleBookmark(testVerse, gita);
      final restoredState = ScriptureReaderState(prefs: prefs);
      await restoredState.init();
      expect(restoredState.isBookmarked(testVerse.globalId(gita.contentId)), isTrue);
      expect(restoredState.getBookmarksForScripture(gita.id).length, equals(1));
    });

    test('4. Personal Study Notes: add, update, retrieve, empty clearing, and persistence', () async {
      final gId = testVerse.globalId(gita.contentId);
      expect(readerState.getNote(gId), isNull);

      // Save a private reflection note
      await readerState.saveNote(
        testVerse,
        gita,
        'Reflecting on Kurukshetra as the battlefield of daily mind and conscience.',
      );

      final note = readerState.getNote(gId);
      expect(note, isNotNull);
      expect(note!.noteText, contains('battlefield of daily mind'));
      expect(note.scriptureId, equals(gita.id));
      expect(note.verseNumber, equals(testVerse.verseNumber));

      final scriptureNotes = readerState.getNotesForScripture(gita.id);
      expect(scriptureNotes.length, equals(1));

      // Updating note
      await readerState.saveNote(
        testVerse,
        gita,
        'Updated insight: Dharma upholds those who uphold it.',
      );
      expect(readerState.getNote(gId)!.noteText, contains('Dharma upholds'));

      // Saving empty note removes it
      await readerState.saveNote(testVerse, gita, '   ');
      expect(readerState.getNote(gId), isNull);
      expect(readerState.getNotesForScripture(gita.id).isEmpty, isTrue);
    });

    test('5. Reading Progress: tracking, resume position, completed set, and percentage', () async {
      expect(readerState.getProgress(gita.id), isNull);

      // Record reading verse 1
      await readerState.recordReadingProgress(gita, 1);
      var progress = readerState.getProgress(gita.id);
      expect(progress, isNotNull);
      expect(progress!.lastReadVerseNumber, equals(1));
      expect(progress.completedVerseNumbers.contains(1), isTrue);
      expect(progress.percentCompleted, greaterThan(0.0));

      // Record reading verse 2
      if (gita.verseCount > 1) {
        await readerState.recordReadingProgress(gita, 2);
        progress = readerState.getProgress(gita.id);
        expect(progress!.lastReadVerseNumber, equals(2));
        expect(progress.completedVerseNumbers.contains(1), isTrue);
        expect(progress.completedVerseNumbers.contains(2), isTrue);
        expect(progress.percentCompleted, equals(2 / gita.verseCount));
      }

      // Verify persistence reload
      final restoredState = ScriptureReaderState(prefs: prefs);
      await restoredState.init();
      final restoredProgress = restoredState.getProgress(gita.id);
      expect(restoredProgress, isNotNull);
      expect(restoredProgress!.lastReadVerseNumber, equals(progress!.lastReadVerseNumber));
      expect(restoredProgress.completedVerseNumbers.length, equals(progress.completedVerseNumbers.length));
    });

    test('6. Corrupted preferences recovery: handles malformed JSON without crashing', () async {
      await prefs.setString('vedam_bookmarks_v1', 'NOT_VALID_JSON{[');
      await prefs.setString('vedam_verse_notes_v1', 'CORRUPT_DATA');
      await prefs.setString('vedam_reading_progress_v1', '{"unexpected": 123}');

      final resilientState = ScriptureReaderState(prefs: prefs);
      await resilientState.init();

      expect(resilientState.isLoaded, isTrue);
      expect(resilientState.allBookmarks.isEmpty, isTrue);
      expect(resilientState.allNotes.isEmpty, isTrue);
      expect(resilientState.allProgress.isEmpty, isTrue);
    });

    test('7. Content Trust & Governance: all scripture translations remain Section 8 DRAFT', () {
      for (final scripture in kAuthenticScriptures) {
        for (final verse in scripture.verses) {
          // All translations remain draft or in-progress under Section 8 (never approved)
          expect(verse.isApproved, isFalse);
          expect(verse.translationStatus, anyOf(equals('DRAFT'), equals('IN_PROGRESS')));

          // If commentary exists, ensure it is attributable and does not impersonate authoritative canonical shruti
          if (verse.commentary != null && verse.commentary!.isNotEmpty) {
            expect(verse.sourceReference, isNotNull);
            expect(verse.sourceReference!.isNotEmpty, isTrue);
          }
        }
      }
    });
  });
}

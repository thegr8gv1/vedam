import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vedam_app/core/models/scripture.dart';
import 'package:vedam_app/core/models/verse.dart';
import 'package:vedam_app/data/fixtures/authentic_scriptures_data.dart';
import 'package:vedam_app/presentation/screens/library/scripture_detail_screen.dart';
import 'package:vedam_app/presentation/screens/library/verse_learning_screen.dart';
import 'package:vedam_app/state/app_state.dart';
import 'package:vedam_app/state/scripture_reader_state.dart';

void main() {
  group('Phase 21E — Scripture Learning Screen Widget Tests', () {
    late SharedPreferences prefs;
    late AppState appState;
    late ScriptureReaderState readerState;
    late Scripture testScripture;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      appState = AppState();
      readerState = ScriptureReaderState(prefs: prefs);
      await readerState.init();

      testScripture = kAuthenticScriptures.firstWhere(
        (s) => s.verses.isNotEmpty,
        orElse: () => kAuthenticScriptures.first,
      );
    });

    Widget buildTestHarness(Widget child, {Size size = const Size(360, 640), double textScale = 1.0}) {
      return MaterialApp(
        theme: ThemeData.light(),
        home: MediaQuery(
          data: MediaQueryData(
            size: size,
            textScaler: TextScaler.linear(textScale),
          ),
          child: Scaffold(body: child),
        ),
      );
    }

    testWidgets('1. ScriptureDetailScreen renders content completeness indicators and action buttons', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));

      await tester.pumpWidget(
        buildTestHarness(
          ScriptureDetailScreen(
            scripture: testScripture,
            appState: appState,
            readerState: readerState,
          ),
          size: const Size(400, 800),
        ),
      );
      await tester.pumpAndSettle();

      // Canonical Title
      expect(find.text(testScripture.canonicalTitle), findsWidgets);

      // Content completeness card header
      expect(find.text('CONTENT AVAILABILITY & COMPLETENESS'), findsOneWidget);

      // Check completeness rows
      expect(find.text('Original Indic Text'), findsOneWidget);
      expect(find.text('Roman Transliteration'), findsOneWidget);
      expect(find.text('English Translation'), findsOneWidget);
      expect(find.text('Scholarly Commentary'), findsOneWidget);
      expect(find.text('Chanting Audio'), findsOneWidget);

      // Action buttons
      expect(find.textContaining('READ SCRIPTURE'), findsOneWidget);
      expect(find.text('ALL VERSES'), findsOneWidget);
    });

    testWidgets('2. VerseLearningScreen renders Sanskrit, IAST, Translation, and Navigation', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));

      await tester.pumpWidget(
        buildTestHarness(
          VerseLearningScreen(
            scripture: testScripture,
            readerState: readerState,
            initialVerseNumber: 1,
            appState: appState,
          ),
          size: const Size(400, 800),
        ),
      );
      await tester.pumpAndSettle();

      // Verse 1 of total
      expect(find.text('VERSE 1 / ${testScripture.verseCount}'), findsOneWidget);

      // Devanagari text is displayed
      expect(find.text(testScripture.verses.first.devanagariText), findsOneWidget);

      // Section 8 Draft badge
      expect(find.textContaining('Section 8 Draft'), findsWidgets);

      // Navigation buttons
      expect(find.byIcon(Icons.bookmark_border), findsOneWidget);
      expect(find.byIcon(Icons.note_add_outlined), findsOneWidget);
      expect(find.text('NEXT VERSE'), findsOneWidget);
    });

    testWidgets('3. Compact 360x640dp viewport with 1.35x font scaling renders without overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));

      await tester.pumpWidget(
        buildTestHarness(
          VerseLearningScreen(
            scripture: testScripture,
            readerState: readerState,
            initialVerseNumber: 1,
            appState: appState,
          ),
          size: const Size(360, 640),
          textScale: 1.35,
        ),
      );
      await tester.pumpAndSettle();

      // No RenderFlex overflow
      expect(tester.takeException(), isNull);
    });

    testWidgets('4. Bookmark toggle and personal note entry in VerseLearningScreen', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));

      await tester.pumpWidget(
        buildTestHarness(
          VerseLearningScreen(
            scripture: testScripture,
            readerState: readerState,
            initialVerseNumber: 1,
            appState: appState,
          ),
          size: const Size(400, 800),
        ),
      );
      await tester.pumpAndSettle();

      // Tap bookmark button
      final bookmarkButton = find.byIcon(Icons.bookmark_border);
      expect(bookmarkButton, findsOneWidget);
      await tester.tap(bookmarkButton);
      await tester.pumpAndSettle();

      // State is updated
      expect(readerState.isBookmarked(testScripture.verses.first.globalId(testScripture.contentId)), isTrue);
      expect(find.byIcon(Icons.bookmark), findsWidgets);

      // Tap note button to open dialog
      final noteButton = find.byIcon(Icons.note_add_outlined);
      expect(noteButton, findsOneWidget);
      await tester.tap(noteButton);
      await tester.pumpAndSettle();

      // Note dialog is shown
      expect(find.text('Personal Study Note'), findsOneWidget);
      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);

      await tester.enterText(textField, 'Meditative reflection on sacred divine sound.');
      await tester.pumpAndSettle();

      // Save note
      final saveBtn = find.text('SAVE NOTE');
      expect(saveBtn, findsOneWidget);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      final note = readerState.getNote(testScripture.verses.first.globalId(testScripture.contentId));
      expect(note, isNotNull);
      expect(note!.noteText, contains('sacred divine sound'));
      expect(find.byIcon(Icons.edit_note), findsOneWidget);
    });
  });
}

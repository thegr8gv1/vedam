import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vedam_app/core/theme/app_theme.dart';
import 'package:vedam_app/data/repositories/scripture_repository_impl.dart';
import 'package:vedam_app/presentation/screens/library/bookmarks_screen.dart';
import 'package:vedam_app/presentation/screens/library/verse_learning_screen.dart';
import 'package:vedam_app/state/scripture_reader_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ScriptureRepositoryImpl repository;
  late ScriptureReaderState readerState;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    repository = ScriptureRepositoryImpl();
    readerState = ScriptureReaderState();
    await readerState.init();
  });

  testWidgets('VerseLearningScreen renders verse 1, transliteration, and Section 8 draft notice',
      (WidgetTester tester) async {
    final scripture = (await repository.getScriptureById(1))!;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: VerseLearningScreen(
          scripture: scripture,
          readerState: readerState,
          initialVerseNumber: 1,
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Title and Subtitle
    expect(find.text('Ganesha Pancharatnam'), findsOneWidget);
    expect(find.textContaining('Verse 1 of 6'), findsOneWidget);

    // Verify Section 8 Draft Badge
    expect(find.text('BHAVARTHA (STUDY TRANSLATION)'), findsOneWidget);
    expect(find.textContaining('Under scholarly peer review'), findsOneWidget);

    // Verify Verse Navigation Elements
    expect(find.text('PREVIOUS'), findsOneWidget);
    expect(find.text('NEXT VERSE'), findsOneWidget);

    // Subheader chip
    expect(find.text('VERSE 1 / 6'), findsOneWidget);
  });

  testWidgets('VerseLearningScreen navigates next and previous verses accurately',
      (WidgetTester tester) async {
    final scripture = (await repository.getScriptureById(1))!;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: VerseLearningScreen(
          scripture: scripture,
          readerState: readerState,
          initialVerseNumber: 1,
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify initial position is verse 1
    expect(find.text('VERSE 1 / 6'), findsOneWidget);

    // Tap NEXT VERSE button
    await tester.tap(find.text('NEXT VERSE'));
    await tester.pumpAndSettle();

    // Now on verse 2
    expect(find.text('VERSE 2 / 6'), findsOneWidget);

    // Tap PREVIOUS button
    await tester.tap(find.text('PREVIOUS'));
    await tester.pumpAndSettle();

    // Back to verse 1
    expect(find.text('VERSE 1 / 6'), findsOneWidget);
  });

  testWidgets('VerseLearningScreen verse jumper modal navigates directly to chosen verse',
      (WidgetTester tester) async {
    final scripture = (await repository.getScriptureById(1))!;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: VerseLearningScreen(
          scripture: scripture,
          readerState: readerState,
          initialVerseNumber: 1,
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tap the verse jumper chip: "VERSE 1 / 6"
    await tester.tap(find.text('VERSE 1 / 6'));
    await tester.pumpAndSettle();

    // Verify Modal appears with "Select Verse (6 Total)" title
    expect(find.text('Select Verse (6 Total)'), findsOneWidget);

    // Tap Verse 4 circle button
    await tester.tap(find.text('4'));
    await tester.pumpAndSettle();

    // Now learning screen should show verse 4
    expect(find.text('VERSE 4 / 6'), findsOneWidget);
  });

  testWidgets('VerseLearningScreen toggles bookmark and updates readerState',
      (WidgetTester tester) async {
    final scripture = (await repository.getScriptureById(1))!;
    final gId1 = scripture.verses[0].globalId(scripture.contentId);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: VerseLearningScreen(
          scripture: scripture,
          readerState: readerState,
          initialVerseNumber: 1,
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(readerState.isBookmarked(gId1), isFalse);

    // Find and tap bookmark icon button
    final bookmarkButton = find.byTooltip('Bookmark this verse');
    expect(bookmarkButton, findsOneWidget);
    await tester.tap(bookmarkButton);
    await tester.pumpAndSettle();

    // Bookmark state updated
    expect(readerState.isBookmarked(gId1), isTrue);
  });

  testWidgets('BookmarksScreen renders tabs and lists saved bookmarks and study notes',
      (WidgetTester tester) async {
    final scripture = (await repository.getScriptureById(1))!;

    // Seed initial bookmark and note
    await readerState.toggleBookmark(scripture.verses[0], scripture);
    await readerState.saveNote(
      scripture.verses[1],
      scripture,
      'Important contemplative verse on spiritual wisdom.',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: BookmarksScreen(
          repository: repository,
          readerState: readerState,
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Screen title and tab headers
    expect(find.text('Bookmarks & Notes'), findsOneWidget);
    expect(find.text('Bookmarks (1)'), findsOneWidget);
    expect(find.text('Study Notes (1)'), findsOneWidget);

    // Verify Bookmarked verse snippet is displayed
    expect(find.text('Ganesha Pancharatnam'), findsOneWidget);
    expect(find.textContaining('मुदाकरात्तमोदकं'), findsOneWidget);
    expect(find.textContaining('Verse 1 • ID:'), findsOneWidget);

    // Switch to Study Notes tab
    await tester.tap(find.text('Study Notes (1)'));
    await tester.pumpAndSettle();

    // Verify note text is displayed
    expect(find.text('Important contemplative verse on spiritual wisdom.'), findsOneWidget);
    expect(find.text('Ganesha Pancharatnam • Verse 2'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vedam_app/core/models/verse.dart';
import 'package:vedam_app/core/theme/app_theme.dart';
import 'package:vedam_app/data/repositories/scripture_repository_impl.dart';
import 'package:vedam_app/presentation/screens/library/library_screen.dart';
import 'package:vedam_app/presentation/screens/library/scripture_detail_screen.dart';
import 'package:vedam_app/presentation/screens/library/verse_reader_screen.dart';
import 'package:vedam_app/state/app_state.dart';

void main() {
  late ScriptureRepositoryImpl repository;
  late AppState appState;

  setUp(() {
    repository = ScriptureRepositoryImpl();
    appState = AppState();
  });

  testWidgets('LibraryScreen allows search and filtering', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: LibraryScreen(
          repository: repository,
          appState: appState,
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify initial count shows 20 scriptures
    expect(find.text('20 Sacred Texts Available'), findsOneWidget);

    // Search for "Shiva Tandava"
    await tester.enterText(find.byType(TextField), 'Shiva Tandava');
    await tester.pumpAndSettle();

    expect(find.text('1 Sacred Texts Available'), findsOneWidget);
    expect(find.text('Shiva Tandava Stotram'), findsOneWidget);

    // Clear search
    await tester.tap(find.byIcon(Icons.clear));
    await tester.pumpAndSettle();
    expect(find.text('20 Sacred Texts Available'), findsOneWidget);
  });

  testWidgets('ScriptureDetailScreen renders canonical metadata and attribution',
      (WidgetTester tester) async {
    final ganesha = (await repository.getScriptureById(1))!;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: ScriptureDetailScreen(
          scripture: ganesha,
          appState: appState,
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Ganesha Pancharatnam'), findsWidgets);
    expect(find.text('गणेशपञ्चरत्नम्'), findsOneWidget);
    expect(find.text('TRADITIONAL ATTRIBUTION & PROVENANCE'), findsOneWidget);
    expect(find.text('READ SCRIPTURE (1 - 6)'), findsOneWidget);
    expect(find.textContaining('Section 8 Editorial Governance'), findsOneWidget);
  });

  testWidgets('VerseReaderScreen displays verses, script toggle, and Section 8 draft notice',
      (WidgetTester tester) async {
    final ganesha = (await repository.getScriptureById(1))!;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: VerseReaderScreen(
          scripture: ganesha,
          appState: appState,
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Verse 1 header
    expect(find.text('VERSE 1'), findsOneWidget);

    // Verify Section 8 draft notice on verse
    expect(find.text('BHAVARTHA (STUDY TRANSLATION)'), findsWidgets);
    expect(find.textContaining('Section 8 Draft'), findsWidgets);

    // Switch script to Telugu
    appState.setActiveScript(ScriptOption.telugu);
    await tester.pumpAndSettle();

    // Verify Sticky reader bar shows Telugu
    expect(find.text('Script: Telugu'), findsOneWidget);
  });
}

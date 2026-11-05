import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vedam_app/core/theme/app_theme.dart';
import 'package:vedam_app/data/repositories/scripture_repository_impl.dart';
import 'package:vedam_app/presentation/navigation/main_screen.dart';
import 'package:vedam_app/state/app_state.dart';

void main() {
  testWidgets('MainScreen navigation between tabs operates smoothly',
      (WidgetTester tester) async {
    final repository = ScriptureRepositoryImpl();
    final appState = AppState();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: MainScreen(
          repository: repository,
          appState: appState,
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify Home Tab active
    expect(find.text('VEDAM'), findsOneWidget);

    // Tap Library Tab
    await tester.tap(find.text('Library'));
    await tester.pumpAndSettle();
    expect(find.text('Scripture Library'), findsOneWidget);

    // Tap Sadhana Tab
    await tester.tap(find.text('Sadhana'));
    await tester.pumpAndSettle();
    expect(find.text('Daily Sadhana'), findsOneWidget);
    expect(find.text('DAILY PRACTICE OVERVIEW'), findsOneWidget);

    // Tap Saved Tab
    await tester.tap(find.text('Saved'));
    await tester.pumpAndSettle();
    expect(find.text('Devotional Shelf'), findsOneWidget);

    // Tap Settings Tab
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Reading & Script (लिपि)'), findsOneWidget);
  });
}

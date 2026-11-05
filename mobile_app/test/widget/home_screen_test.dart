import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vedam_app/core/theme/app_theme.dart';
import 'package:vedam_app/data/repositories/scripture_repository_impl.dart';
import 'package:vedam_app/presentation/screens/home/home_screen.dart';
import 'package:vedam_app/state/app_state.dart';

void main() {
  testWidgets('HomeScreen renders authentic branding, daily verse, and portals',
      (WidgetTester tester) async {
    final repository = ScriptureRepositoryImpl();
    final appState = AppState();
    int? navigatedTab;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: HomeScreen(
          repository: repository,
          appState: appState,
          onNavigateToTab: (index) {
            navigatedTab = index;
          },
        ),
      ),
    );

    // Initial pump
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify VEDAM branding in app bar
    expect(find.text('VEDAM'), findsOneWidget);
    expect(find.text('वेदम्'), findsOneWidget);

    // Verify Invocation banner
    expect(find.textContaining('ॐ असतो मा सद्गमय'), findsOneWidget);

    // Verify Daily Darshan Card
    expect(find.text('DAILY DEVOTIONAL DARSHAN'), findsOneWidget);
    expect(find.textContaining('Mahamrityunjaya'), findsOneWidget);

    // Verify Panchangam Card
    expect(find.text("TODAY'S PANCHANGAM"), findsOneWidget);
    expect(find.textContaining('Tithi'), findsOneWidget);

    // Verify Portals
    expect(find.text('Scripture Library'), findsOneWidget);
    expect(find.text('Daily Sadhana'), findsOneWidget);
    expect(find.text('Mantras & Chanting'), findsOneWidget);
    expect(find.text('My Devotional Shelf'), findsOneWidget);

    // Verify Section 8 banner
    expect(find.textContaining('Section 8 Editorial Governance'), findsOneWidget);

    // Tap Scripture Library portal
    final portalFinder = find.text('Scripture Library');
    await tester.ensureVisible(portalFinder);
    await tester.pumpAndSettle();
    await tester.tap(portalFinder);
    expect(navigatedTab, 1);
  });
}

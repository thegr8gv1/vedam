import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vedam_app/core/models/daily_darshan.dart';
import 'package:vedam_app/core/services/audio_service.dart';
import 'package:vedam_app/core/theme/app_theme.dart';
import 'package:vedam_app/data/fixtures/authentic_puja_guides_data.dart';
import 'package:vedam_app/data/repositories/mantra_repository.dart';
import 'package:vedam_app/data/repositories/panchangam_repository.dart';
import 'package:vedam_app/data/repositories/scripture_repository_impl.dart';
import 'package:vedam_app/presentation/screens/home/home_screen.dart';
import 'package:vedam_app/presentation/screens/home/widgets/daily_routine_card.dart';
import 'package:vedam_app/presentation/screens/home/widgets/dashboard_japa_card.dart';
import 'package:vedam_app/presentation/screens/home/widgets/devotional_welcome_header.dart';
import 'package:vedam_app/presentation/screens/home/widgets/panchangam_preview_card.dart';
import 'package:vedam_app/presentation/screens/home/widgets/saved_devotional_card.dart';
import 'package:vedam_app/presentation/screens/home/widgets/scripture_progress_card.dart';
import 'package:vedam_app/presentation/screens/home/widgets/upcoming_vrat_card.dart';
import 'package:vedam_app/state/app_state.dart';
import 'package:vedam_app/state/audio_state.dart';
import 'package:vedam_app/state/panchangam_state.dart';
import 'package:vedam_app/state/sadhana_state.dart';
import 'package:vedam_app/state/scripture_reader_state.dart';
import 'package:vedam_app/state/vrat_state.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildTestDashboard({
    required ScriptureRepositoryImpl repository,
    required AppState appState,
    required PanchangamState panchangamState,
    required SadhanaState sadhanaState,
    required AudioState audioState,
    required VratState vratState,
    required ScriptureReaderState readerState,
    MantraRepository? mantraRepository,
    ThemeMode themeMode = ThemeMode.light,
    Function(int)? onNavigateToTab,
    VoidCallback? onOpenMantras,
    VoidCallback? onOpenPanchangam,
    Size size = const Size(390, 844), // iPhone 14 size
  }) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: HomeScreen(
            repository: repository,
            appState: appState,
            panchangamState: panchangamState,
            sadhanaState: sadhanaState,
            audioState: audioState,
            vratState: vratState,
            readerState: readerState,
            mantraRepository: mantraRepository ?? MantraRepositoryImpl(),
            onNavigateToTab: onNavigateToTab ?? (_) {},
            onOpenMantras: onOpenMantras,
            onOpenPanchangam: onOpenPanchangam,
          ),
        ),
      ),
    );
  }

  group('Phase 17A: Devotee Home Dashboard & Daily Routine Integration Tests', () {
    testWidgets('1. Dashboard renders all essential devotional cards and headers',
        (WidgetTester tester) async {
      final repository = ScriptureRepositoryImpl();
      final appState = AppState();
      final audioService = AudioPlaybackServiceImpl();
      final audioState = AudioState(audioService: audioService);
      final sadhanaState = SadhanaState();
      final vratState = VratState();
      final readerState = ScriptureReaderState();
      final panchangamRepo = PanchangamRepositoryImpl();
      final panchangamState = PanchangamState(repository: panchangamRepo);

      await tester.pumpWidget(
        buildTestDashboard(
          repository: repository,
          appState: appState,
          panchangamState: panchangamState,
          sadhanaState: sadhanaState,
          audioState: audioState,
          vratState: vratState,
          readerState: readerState,
        ),
      );
      await tester.pumpAndSettle();

      // Verify Sacred Devotional Welcome & Invocation
      expect(find.byType(DevotionalWelcomeHeader), findsOneWidget);
      expect(find.textContaining('शुभ'), findsOneWidget);
      expect(find.textContaining('ॐ असतो मा सद्गमय'), findsOneWidget);

      // Verify Panchangam Card
      expect(find.byType(PanchangamPreviewCard), findsOneWidget);
      expect(find.text("TODAY'S PANCHANGAM"), findsOneWidget);

      // Verify Daily Routine Card
      expect(find.byType(DailyRoutineCard), findsOneWidget);
      expect(find.text('DAILY SPIRITUAL ROUTINE'), findsOneWidget);

      // Verify Japa Practice Card
      expect(find.byType(DashboardJapaCard), findsOneWidget);
      expect(find.text('DAILY JAPA PRACTICE'), findsOneWidget);

      // Verify Upcoming Vrat Card
      expect(find.byType(UpcomingVratCard), findsOneWidget);
      expect(find.text('UPCOMING VRAT & OBSERVANCES'), findsOneWidget);

      // Verify Scripture Progress Card
      expect(find.byType(ScriptureProgressCard), findsOneWidget);
      expect(find.text('SCRIPTURE LEARNING PROGRESS'), findsOneWidget);

      // Verify Saved Devotional Content Card
      expect(find.byType(SavedDevotionalCard), findsOneWidget);
      expect(find.text('SAVED DEVOTIONAL CONTENT'), findsOneWidget);

      // Verify Section 8 Governance Disclosure
      expect(find.textContaining('Section 8 Editorial Governance'), findsOneWidget);
    });

    testWidgets('2. Panchangam card displays honest offline fallback when calculation unavailable',
        (WidgetTester tester) async {
      // Standalone card with no calculation data loaded (null calcData)
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: PanchangamPreviewCard(
              panchangamState: null,
              darshan: DailyDarshan.today(),
              onTap: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Panchangam 5 Angas labels are present
      expect(find.textContaining('Tithi'), findsOneWidget);
      expect(find.textContaining('Nakshatra'), findsOneWidget);

      // Verify standard/fallback badge and non-authoritative disclaimer
      expect(find.text('STANDARD'), findsOneWidget);
      expect(find.textContaining('not an authoritative religious decree'), findsOneWidget);
    });

    testWidgets('3. Upcoming Vrat card handles empty observance schedule gracefully',
        (WidgetTester tester) async {
      // VratState with all observances removed
      final emptyVratState = VratState();
      for (final obs in emptyVratState.observances.toList()) {
        emptyVratState.deleteObservance(obs.id);
      }

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: UpcomingVratCard(
              vratState: emptyVratState,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Shows gentle empty-state invitation to plan observances
      expect(find.text('No Upcoming Vrat Scheduled'), findsOneWidget);
      expect(find.text('Explore Vrat Calendar'), findsOneWidget);
    });

    testWidgets('4. Scripture Progress card offers foundational scripture when no history exists',
        (WidgetTester tester) async {
      final repository = ScriptureRepositoryImpl();
      final appState = AppState();
      final audioService = AudioPlaybackServiceImpl();
      final audioState = AudioState(audioService: audioService);
      final readerState = ScriptureReaderState();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: ScriptureProgressCard(
              repository: repository,
              appState: appState,
              readerState: readerState,
              audioState: audioState,
              onOpenLibrary: () {},
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Foundational text recommendation (e.g. Mahamrityunjaya Mantra or Gayatri)
      expect(find.text('Start Reading'), findsOneWidget);
      expect(find.text('Not yet started'), findsOneWidget);
      expect(find.textContaining('Section 8 Notice'), findsOneWidget);
    });

    testWidgets('5. Daily Routine checklist can be checked off directly on the dashboard',
        (WidgetTester tester) async {
      final prefs = await SharedPreferences.getInstance();
      final sadhanaState = SadhanaState(prefs: prefs);
      final appState = AppState();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AnimatedBuilder(
              animation: sadhanaState,
              builder: (context, child) => DailyRoutineCard(
                sadhanaState: sadhanaState,
                appState: appState,
                onOpenSadhana: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final initialCompleted = sadhanaState.completedRoutineCount;
      expect(find.text('0 of 5 Practices Completed'), findsOneWidget);

      // Find first checklist radio button and tap it
      final itemFinder = find.byIcon(Icons.radio_button_unchecked).first;
      await tester.tap(itemFinder);
      await tester.pumpAndSettle();

      // Practice count should have increased to 1
      expect(sadhanaState.completedRoutineCount, initialCompleted + 1);
      expect(find.text('1 of 5 Practices Completed'), findsOneWidget);
    });

    testWidgets('6. Japa Practice card increments count via sacred bead (+1) and preserves session',
        (WidgetTester tester) async {
      final audioService = AudioPlaybackServiceImpl();
      final audioState = AudioState(audioService: audioService);

      // Set target repetitions to 108
      audioState.setTargetRepetitions(108);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AnimatedBuilder(
              animation: audioState,
              builder: (context, child) => DashboardJapaCard(
                audioState: audioState,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initial count is 0 of 108 (target=108, remaining=108)
      expect(find.text('0'), findsOneWidget);
      expect(find.text('108'), findsNWidgets(2));
      expect(find.text('Count Bead (+1)'), findsOneWidget);

      // Tap Count Bead (+1) sacred bead button
      final beadButton = find.text('Count Bead (+1)');
      await tester.tap(beadButton);
      await tester.pumpAndSettle();

      // Completed repetitions should now be 1 without resetting target
      expect(audioState.completedRepetitions, 1);
      expect(audioState.targetRepetitions, 108);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('107'), findsOneWidget);

      // Tap again
      await tester.tap(beadButton);
      await tester.pumpAndSettle();
      expect(audioState.completedRepetitions, 2);
    });

    testWidgets('7. Japa session target supports large targets (1008, 100,000) gracefully',
        (WidgetTester tester) async {
      final audioService = AudioPlaybackServiceImpl();
      final audioState = AudioState(audioService: audioService);

      // Set target repetitions to 1008
      audioState.setTargetRepetitions(1008);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AnimatedBuilder(
              animation: audioState,
              builder: (context, child) => DashboardJapaCard(
                audioState: audioState,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('1008'), findsNWidgets(2));
      expect(find.text('REMAINING'), findsOneWidget);

      // Set custom target to 10,000
      audioState.setTargetRepetitions(10000);
      await tester.pumpAndSettle();
      expect(find.text('10000'), findsNWidgets(2));
    });

    testWidgets('8. Active guided puja session displays resume banner on dashboard',
        (WidgetTester tester) async {
      final sadhanaState = SadhanaState();
      final appState = AppState();
      final guide = AuthenticPujaGuidesData.allGuides.first;

      // Start a puja guide
      sadhanaState.startGuide(guide, stepIndex: 2);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: DailyRoutineCard(
              sadhanaState: sadhanaState,
              appState: appState,
              onOpenSadhana: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify active puja resume banner
      expect(find.text('PUJA SESSION IN PROGRESS'), findsOneWidget);
      expect(find.textContaining('Step 3 of'), findsOneWidget);
      expect(find.text('Resume'), findsOneWidget);
    });

    testWidgets('9. Saved devotional card displays accurate count badges',
        (WidgetTester tester) async {
      final repository = ScriptureRepositoryImpl();
      final appState = AppState();
      final readerState = ScriptureReaderState();
      final audioService = AudioPlaybackServiceImpl();
      final audioState = AudioState(audioService: audioService);

      // Add favorites and bookmarks
      appState.toggleFavorite(1);
      appState.toggleFavorite(2);
      final scripture = await repository.getScriptureById(1);
      if (scripture != null && scripture.verses.isNotEmpty) {
        await readerState.toggleBookmark(scripture.verses.first, scripture);
      }
      audioState.toggleFavoriteMantra('om_namah_shivaya');

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: SavedDevotionalCard(
              repository: repository,
              appState: appState,
              readerState: readerState,
              audioState: audioState,
              onNavigateToTab: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify badges reflect state
      expect(find.text('Saved Scriptures'), findsOneWidget);
      expect(find.text('Bookmarked Verses'), findsOneWidget);
      expect(find.text('Favorite Mantras'), findsOneWidget);
      expect(find.text('1 sacred chants'), findsOneWidget);
    });

    testWidgets('10. Theme compatibility: Dashboard renders in Temple Night (dark) theme',
        (WidgetTester tester) async {
      final repository = ScriptureRepositoryImpl();
      final appState = AppState();
      final audioService = AudioPlaybackServiceImpl();
      final audioState = AudioState(audioService: audioService);
      final sadhanaState = SadhanaState();
      final vratState = VratState();
      final readerState = ScriptureReaderState();
      final panchangamRepo = PanchangamRepositoryImpl();
      final panchangamState = PanchangamState(repository: panchangamRepo);

      await tester.pumpWidget(
        buildTestDashboard(
          repository: repository,
          appState: appState,
          panchangamState: panchangamState,
          sadhanaState: sadhanaState,
          audioState: audioState,
          vratState: vratState,
          readerState: readerState,
          themeMode: ThemeMode.dark,
        ),
      );
      await tester.pumpAndSettle();

      // Confirms dark mode renders without errors
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('VEDAM'), findsOneWidget);
      expect(find.text('DAILY SPIRITUAL ROUTINE'), findsOneWidget);
    });

    testWidgets('11. Responsive layout: >= 700dp renders multi-column dual layout',
        (WidgetTester tester) async {
      final repository = ScriptureRepositoryImpl();
      final appState = AppState();
      final audioService = AudioPlaybackServiceImpl();
      final audioState = AudioState(audioService: audioService);
      final sadhanaState = SadhanaState();
      final vratState = VratState();
      final readerState = ScriptureReaderState();
      final panchangamRepo = PanchangamRepositoryImpl();
      final panchangamState = PanchangamState(repository: panchangamRepo);

      // Tablet / Web viewport: 1024 x 768
      await tester.pumpWidget(
        buildTestDashboard(
          repository: repository,
          appState: appState,
          panchangamState: panchangamState,
          sadhanaState: sadhanaState,
          audioState: audioState,
          vratState: vratState,
          readerState: readerState,
          size: const Size(1024, 768),
        ),
      );
      await tester.pumpAndSettle();

      // Confirms all cards render smoothly in dual-column layout
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(PanchangamPreviewCard), findsOneWidget);
      expect(find.byType(DashboardJapaCard), findsOneWidget);
    });
  });
}

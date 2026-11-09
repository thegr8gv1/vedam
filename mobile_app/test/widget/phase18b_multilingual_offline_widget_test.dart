import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vedam_app/core/models/app_settings.dart';
import 'package:vedam_app/core/models/verse.dart';
import 'package:vedam_app/core/services/audio_service.dart';
import 'package:vedam_app/data/fixtures/authentic_scriptures_data.dart';
import 'package:vedam_app/data/repositories/mantra_repository.dart';
import 'package:vedam_app/data/repositories/scripture_repository_impl.dart';
import 'package:vedam_app/l10n/app_localizations.dart';
import 'package:vedam_app/main.dart';
import 'package:vedam_app/presentation/navigation/main_screen.dart';
import 'package:vedam_app/presentation/screens/home/widgets/dashboard_japa_card.dart';
import 'package:vedam_app/presentation/screens/library/verse_reader_screen.dart';
import 'package:vedam_app/presentation/screens/mantras/mantra_player_screen.dart';
import 'package:vedam_app/presentation/widgets/offline_status_banner.dart';
import 'package:vedam_app/presentation/widgets/visual_mala_widget.dart';
import 'package:vedam_app/state/app_state.dart';
import 'package:vedam_app/state/audio_state.dart';
import 'package:vedam_app/state/scripture_reader_state.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Phase 18B Widget Tests: Localization & Navigation', () {
    testWidgets('AppLocalizations loads and renders translated navigation across all 5 locales',
        (tester) async {
      final localesToTest = [
        {'locale': const Locale('en'), 'home': 'Home', 'library': 'Library', 'settings': 'Settings'},
        {'locale': const Locale('te'), 'home': 'హోమ్', 'library': 'గ్రంథాలయం', 'settings': 'అమరికలు'},
        {'locale': const Locale('ta'), 'home': 'முகப்பு', 'library': 'நூலகம்', 'settings': 'அமைப்புகள்'},
        {'locale': const Locale('kn'), 'home': 'ಮುಖಪುಟ', 'library': 'ಗ್ರಂಥಾಲಯ', 'settings': 'ಸೆಟ್ಟಿಂಗ್ಸ್'},
        {'locale': const Locale('ml'), 'home': 'ഹോം', 'library': 'ഗ്രന്ഥശാല', 'settings': 'ക്രമീകരണങ്ങൾ'},
      ];

      for (final item in localesToTest) {
        final loc = item['locale'] as Locale;
        late AppLocalizations l10n;

        await tester.pumpWidget(
          MaterialApp(
            locale: loc,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (context) {
                l10n = AppLocalizations.of(context)!;
                return Scaffold(
                  body: Column(
                    children: [
                      Text(l10n.navHome),
                      Text(l10n.navLibrary),
                      Text(l10n.navSettings),
                    ],
                  ),
                );
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text(item['home'] as String), findsOneWidget,
            reason: 'Home translation mismatch in ${loc.languageCode}');
        expect(find.text(item['library'] as String), findsOneWidget,
            reason: 'Library translation mismatch in ${loc.languageCode}');
        expect(find.text(item['settings'] as String), findsOneWidget,
            reason: 'Settings translation mismatch in ${loc.languageCode}');
      }
    });

    testWidgets('MainScreen navigation bar updates language dynamically with AppState',
        (tester) async {
      final repository = ScriptureRepositoryImpl();
      final appState = AppState();

      await tester.pumpWidget(
        MaterialApp(
          locale: appState.locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MainScreen(
            repository: repository,
            appState: appState,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initial English navigation labels
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Library'), findsOneWidget);
      expect(find.text('Sadhana'), findsOneWidget);
      expect(find.text('Saved'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);

      // Dynamically switch to Telugu
      appState.setInterfaceLanguage(InterfaceLanguage.telugu);
      await tester.pumpWidget(
        MaterialApp(
          locale: appState.locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MainScreen(
            repository: repository,
            appState: appState,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('హోమ్'), findsOneWidget);
      expect(find.text('గ్రంథాలయం'), findsOneWidget);
      expect(find.text('సాధన'), findsOneWidget);
      expect(find.text('భద్రపరిచినవి'), findsOneWidget);
      expect(find.text('అమరికలు'), findsOneWidget);
    });
  });

  group('Phase 18B Widget Tests: Accessibility & Touch Targets', () {
    testWidgets('DashboardJapaCard action buttons have >= 48dp height touch targets and semantics',
        (tester) async {
      final audioState = AudioState(audioService: AudioPlaybackServiceImpl());
      audioState.setTargetRepetitions(108);

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: DashboardJapaCard(audioState: audioState),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find the OutlinedButton (Count Bead) and ElevatedButton (Start Chanting)
      final outlinedBtnFinder = find.byType(OutlinedButton);
      final elevatedBtnFinder = find.byType(ElevatedButton);

      expect(outlinedBtnFinder, findsOneWidget);
      expect(elevatedBtnFinder, findsOneWidget);

      // Verify touch target height is at least 48dp (WCAG standard)
      final outlinedSize = tester.getSize(outlinedBtnFinder);
      expect(outlinedSize.height, greaterThanOrEqualTo(48.0));

      final elevatedSize = tester.getSize(elevatedBtnFinder);
      expect(elevatedSize.height, greaterThanOrEqualTo(48.0));

      // Verify semantics
      final semanticsBead = find.bySemanticsLabel(RegExp(r'Count Japa bead'));
      expect(semanticsBead, findsOneWidget);
    });

    testWidgets('VisualMalaWidget includes screen-reader Semantics with accurate completion state',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VisualMalaWidget(
              completedCount: 54,
              targetCount: 108,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final semanticsFinder = find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.label == 'Japa Mala Chanting Counter',
      );
      expect(semanticsFinder, findsOneWidget);
    });

    testWidgets('MaterialApp respects text scaling preferences gracefully',
        (tester) async {
      final repository = ScriptureRepositoryImpl();
      final appState = AppState();

      // Test large text scale factor 1.35
      appState.setTextScalePreference(TextScalePreference.extraLarge);

      await tester.pumpWidget(
        VedamApp(
          repository: repository,
          appState: appState,
        ),
      );
      await tester.pumpAndSettle();

      // Ensure no overflow errors occurred
      expect(tester.takeException(), isNull);
    });
  });

  group('Phase 18B Widget Tests: Offline Readiness & Indicators', () {
    testWidgets('OfflineStatusBanner renders and dismisses on user tap',
        (tester) async {
      bool dismissed = false;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: OfflineStatusBanner(
              isOffline: true,
              onDismiss: () => dismissed = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(OfflineStatusBanner), findsOneWidget);
      expect(find.textContaining('Offline Mode'), findsOneWidget);

      // Tap close button
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(dismissed, isTrue);
      // Banner dismissed
      expect(find.textContaining('Offline Mode'), findsNothing);
    });

    testWidgets('MantraPlayerScreen displays offline availability badge for bundled audio',
        (tester) async {
      final repo = MantraRepositoryImpl();
      final bundledMantra = repo.getAllMantras().firstWhere((m) => m.isBundled);
      final audioState = AudioState(audioService: AudioPlaybackServiceImpl());

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MantraPlayerScreen(
            mantra: bundledMantra,
            audioState: audioState,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Offline Ready • Bundled Authentic Audio'), findsOneWidget);
      expect(find.byIcon(Icons.offline_pin_outlined), findsOneWidget);
    });

    testWidgets('VerseReaderScreen renders verses in Telugu, Tamil, Kannada, and Malayalam scripts',
        (tester) async {
      final scripture = kAuthenticScriptures.first; // Ganesha Pancharatnam
      final appState = AppState();
      final readerState = ScriptureReaderState();

      final scriptsToTest = [
        ScriptOption.devanagari,
        ScriptOption.telugu,
        ScriptOption.tamil,
        ScriptOption.kannada,
        ScriptOption.malayalam,
      ];

      for (final script in scriptsToTest) {
        appState.setActiveScript(script);

        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: VerseReaderScreen(
              scripture: scripture,
              appState: appState,
              readerState: readerState,
            ),
          ),
        );
        await tester.pumpAndSettle();

        final expectedText = scripture.verses.first.getTextInScript(script);
        expect(find.text(expectedText), findsOneWidget,
            reason: 'Verse text must render in script: ${script.label}');
      }
    });
  });
}

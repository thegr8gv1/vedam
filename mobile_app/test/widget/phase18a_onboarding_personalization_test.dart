import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vedam_app/core/models/devotee_preferences.dart';
import 'package:vedam_app/core/models/devotional_reminder.dart';
import 'package:vedam_app/core/models/mantra_item.dart';
import 'package:vedam_app/core/models/panchangam_data.dart';
import 'package:vedam_app/core/models/verse.dart';
import 'package:vedam_app/core/services/audio_service.dart';
import 'package:vedam_app/core/services/reminder_service.dart';
import 'package:vedam_app/core/theme/app_theme.dart';
import 'package:vedam_app/data/repositories/mantra_repository.dart';
import 'package:vedam_app/data/repositories/panchangam_repository.dart';
import 'package:vedam_app/data/repositories/scripture_repository.dart';
import 'package:vedam_app/data/repositories/scripture_repository_impl.dart';
import 'package:vedam_app/main.dart';
import 'package:vedam_app/presentation/screens/home/widgets/personalized_devotional_card.dart';
import 'package:vedam_app/presentation/screens/onboarding/onboarding_wizard_screen.dart';
import 'package:vedam_app/presentation/screens/settings/settings_screen.dart';
import 'package:vedam_app/state/app_state.dart';
import 'package:vedam_app/state/audio_state.dart';
import 'package:vedam_app/state/panchangam_state.dart';
import 'package:vedam_app/state/personalization_state.dart';
import 'package:vedam_app/state/sadhana_state.dart';

class _MockAudioService implements AudioPlaybackService {
  final _stateController = StreamController<PlayerState>.broadcast();
  final _posController = StreamController<Duration>.broadcast();
  final _durController = StreamController<Duration>.broadcast();

  final PlayerState _state = PlayerState.stopped;
  final Duration _pos = Duration.zero;
  final Duration _dur = const Duration(seconds: 5);
  MantraItem? _active;

  @override
  Stream<PlayerState> get playerStateStream => _stateController.stream;
  @override
  Stream<Duration> get positionStream => _posController.stream;
  @override
  Stream<Duration> get durationStream => _durController.stream;
  @override
  PlayerState get playerState => _state;
  @override
  Duration get currentPosition => _pos;
  @override
  Duration get totalDuration => _dur;
  @override
  MantraItem? get activeMantra => _active;
  @override
  bool get isLoading => false;
  @override
  Stream<bool> get loadingStream => const Stream.empty();

  @override
  Future<void> playMantra(MantraItem item) async {
    _active = item;
  }
  @override
  Future<void> pause() async {}
  @override
  Future<void> resume() async {}
  @override
  Future<void> stop() async { _active = null; }
  @override
  Future<void> seek(Duration position) async {}
  @override
  Future<void> setPlaybackRate(double speed) async {}
  @override
  Future<void> dispose() async {
    await _stateController.close();
    await _posController.close();
    await _durController.close();
  }
}

class _MockReminderService implements ReminderService {
  bool initialized = false;
  ReminderPermissionStatus permissionStatus = ReminderPermissionStatus.granted;
  final List<DevotionalReminder> scheduled = [];

  @override
  Future<void> initialize() async {
    initialized = true;
  }

  @override
  Future<ReminderPermissionStatus> getPermissionStatus() async => permissionStatus;

  @override
  Future<ReminderPermissionStatus> requestPermission() async => permissionStatus;

  @override
  Future<int> getOrCreateNotificationId(String id) async => id.hashCode.abs() % 2147483647;

  @override
  Future<void> releaseReminderId(String reminderId) async {}

  @override
  Future<void> showImmediateNotification({
    required String id,
    required String title,
    required String body,
  }) async {}

  @override
  Future<void> scheduleReminder(DevotionalReminder reminder) async {
    scheduled.add(reminder);
  }

  @override
  Future<void> cancelReminder(String reminderId) async {
    scheduled.removeWhere((r) => r.id == reminderId);
  }

  @override
  Future<void> cancelAllReminders() async {
    scheduled.clear();
  }

  @override
  Future<List<PendingNotificationRequest>> getPendingNotificationRequests() async => [];

  @override
  Future<List<ActiveNotification>> getActiveNotifications() async => [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 18A: Devotee Onboarding & Personalization Tests', () {
    late AppState appState;
    late PanchangamRepository panchangamRepository;
    late PanchangamState panchangamState;
    late AudioPlaybackService audioService;
    late AudioState audioState;
    late SadhanaState sadhanaState;
    late ScriptureRepository repository;
    late MantraRepository mantraRepository;
    late _MockReminderService reminderService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      appState = AppState();
      panchangamRepository = PanchangamRepositoryImpl();
      panchangamState = PanchangamState(repository: panchangamRepository);
      audioService = _MockAudioService();
      audioState = AudioState(audioService: audioService);
      sadhanaState = SadhanaState();
      repository = ScriptureRepositoryImpl();
      mantraRepository = MantraRepositoryImpl();
      reminderService = _MockReminderService();
    });

    testWidgets('1. First launch for new devotee opens Onboarding Wizard Step 1',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final pzState = PersonalizationState(
        appState: appState,
        panchangamState: panchangamState,
        audioState: audioState,
        forceShowOnboarding: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: VedamApp(
            repository: ScriptureRepositoryImpl(),
            appState: appState,
            personalizationState: pzState,
            showOnboarding: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Welcome to Vedam'), findsOneWidget);
      expect(find.text('Step 1 of 7'), findsOneWidget);
      expect(find.text('Get Started'), findsOneWidget);
      expect(find.text('Skip for Now'), findsOneWidget);
    });

    testWidgets('2. Wizard navigation through all 7 steps with Back and Continue',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final pzState = PersonalizationState(
        appState: appState,
        panchangamState: panchangamState,
        audioState: audioState,
      );

      bool finished = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: OnboardingWizardScreen(
            personalizationState: pzState,
            panchangamRepository: panchangamRepository,
            onFinish: () => finished = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Step 0: Welcome
      expect(find.text('Welcome to Vedam'), findsOneWidget);
      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();

      // Step 1: Devotional Interests
      expect(find.text('Step 2 of 7'), findsOneWidget);
      expect(find.text('Choose Your Devotional Interests'), findsOneWidget);
      expect(find.text('Lord Ganesha'), findsOneWidget);
      expect(find.text('Lord Shiva'), findsOneWidget);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 2: Language & Script
      expect(find.text('Step 3 of 7'), findsOneWidget);
      expect(find.text('Language & Script Preferences'), findsOneWidget);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 3: Daily Sadhana Goals
      expect(find.text('Step 4 of 7'), findsOneWidget);
      expect(find.text('Daily Sadhana & Chanting Goals'), findsOneWidget);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 4: Panchangam Location
      expect(find.text('Step 5 of 7'), findsOneWidget);
      expect(find.text('Select Panchangam Location'), findsOneWidget);
      expect(find.text('No GPS Tracking Required'), findsOneWidget);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 5: Reminders
      expect(find.text('Step 6 of 7'), findsOneWidget);
      expect(find.text('Daily Devotional Reminders'), findsOneWidget);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 6: Review & Finish
      expect(find.text('Step 7 of 7'), findsOneWidget);
      expect(find.text('Review Your Spiritual Preferences'), findsOneWidget);
      expect(find.text('Finish Setup & Enter Vedam'), findsOneWidget);

      // Tap Finish
      await tester.tap(find.text('Finish Setup & Enter Vedam'));
      await tester.pumpAndSettle();

      expect(finished, isTrue);
      expect(pzState.onboardingCompleted, isTrue);
    });

    testWidgets('3. Skipping onboarding completes gracefully with default preferences and does not block',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final pzState = PersonalizationState(
        appState: appState,
        panchangamState: panchangamState,
        audioState: audioState,
      );

      bool finished = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: OnboardingWizardScreen(
            personalizationState: pzState,
            onFinish: () => finished = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Skip for Now'), findsOneWidget);
      await tester.tap(find.text('Skip for Now'));
      await tester.pumpAndSettle();

      expect(finished, isTrue);
      expect(pzState.onboardingCompleted, isTrue);
    });

    testWidgets('4. Returning users are not prompted with onboarding again',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        'vedam_onboarding_completed': true,
      });

      final pzState = PersonalizationState(
        appState: appState,
        panchangamState: panchangamState,
        audioState: audioState,
      );
      await tester.pumpAndSettle();

      expect(pzState.showOnboardingFlow, isFalse);
      expect(pzState.onboardingCompleted, isTrue);
    });

    testWidgets('5. Existing users from earlier phases are detected and not disrupted',
        (WidgetTester tester) async {
      // User has existing routine or vrat from Phase 15/17 but not Phase 18A profile yet
      SharedPreferences.setMockInitialValues({
        'vedam_sadhana_routine_ids': ['practice_morning_prayer'],
      });

      final pzState = PersonalizationState(
        appState: appState,
        panchangamState: panchangamState,
        audioState: audioState,
      );
      await tester.pumpAndSettle();

      expect(pzState.isReturningUser, isTrue);
      expect(pzState.showOnboardingFlow, isFalse);
    });

    testWidgets('6. Devotional interests multi-selection supports adding/removing deities with at least 1 preserved',
        (WidgetTester tester) async {
      final pzState = PersonalizationState(
        appState: appState,
        panchangamState: panchangamState,
        audioState: audioState,
      );

      await pzState.setDevotionalInterests({'ganesha', 'shiva'});
      expect(pzState.selectedDeityIds, contains('ganesha'));
      expect(pzState.selectedDeityIds, contains('shiva'));

      await pzState.toggleDevotionalInterest('vishnu');
      expect(pzState.selectedDeityIds, contains('vishnu'));

      await pzState.toggleDevotionalInterest('ganesha');
      expect(pzState.selectedDeityIds.contains('ganesha'), isFalse);

      // Attempting to clear all falls back safely to general practice
      await pzState.setDevotionalInterests({});
      expect(pzState.selectedDeityIds, contains('general'));
    });

    testWidgets('7. Language and Scripture script selection updates AppState active script',
        (WidgetTester tester) async {
      final pzState = PersonalizationState(
        appState: appState,
        panchangamState: panchangamState,
        audioState: audioState,
      );

      await pzState.setScriptureScript(ScriptOption.telugu);
      expect(pzState.scriptureScript, equals(ScriptOption.telugu));
      expect(appState.activeScript, equals(ScriptOption.telugu));

      await pzState.setScriptureScript(ScriptOption.kannada);
      expect(pzState.scriptureScript, equals(ScriptOption.kannada));
      expect(appState.activeScript, equals(ScriptOption.kannada));
    });

    testWidgets('8. Daily Sadhana goals: Japa targets support presets (11-1008) and custom count',
        (WidgetTester tester) async {
      final pzState = PersonalizationState(
        appState: appState,
        panchangamState: panchangamState,
        audioState: audioState,
      );

      // Presets
      await pzState.setJapaTarget(54);
      expect(pzState.japaTarget, equals(54));
      expect(audioState.targetRepetitions, equals(54));

      await pzState.setJapaTarget(1008);
      expect(pzState.japaTarget, equals(1008));
      expect(audioState.targetRepetitions, equals(1008));

      // Custom numeric entry
      await pzState.setJapaTarget(216);
      expect(pzState.japaTarget, equals(216));
      expect(audioState.targetRepetitions, equals(216));

      // Rejects invalid target
      await pzState.setJapaTarget(-5);
      expect(pzState.japaTarget, equals(216)); // Preserved
    });

    testWidgets('9. Panchangam Location selection updates PanchangamState without GPS permission',
        (WidgetTester tester) async {
      final pzState = PersonalizationState(
        appState: appState,
        panchangamState: panchangamState,
        audioState: audioState,
      );

      const rameswaram = PanchangamLocation(
        name: 'Rameswaram, TN, India',
        latitude: 9.2876,
        longitude: 79.3129,
        timezone: 'Asia/Kolkata',
      );

      await pzState.setPanchangamLocation(rameswaram);
      expect(pzState.panchangamLocation.name, contains('Rameswaram'));
      expect(panchangamState.selectedLocation.name, contains('Rameswaram'));
    });

    testWidgets('10. Notifications: Opt-in schedules local reminders, opt-out cancels them without silent activation',
        (WidgetTester tester) async {
      final pzState = PersonalizationState(
        appState: appState,
        panchangamState: panchangamState,
        audioState: audioState,
        reminderService: reminderService,
      );

      // Default is opt-out (false)
      expect(pzState.remindersEnabled, isFalse);
      expect(reminderService.scheduled.isEmpty, isTrue);

      // Opt in
      final enabled = await pzState.setRemindersEnabled(true);
      expect(enabled, isTrue);
      expect(pzState.remindersEnabled, isTrue);
      expect(reminderService.scheduled.length, equals(2)); // Morning & Evening

      // Opt out
      await pzState.setRemindersEnabled(false);
      expect(pzState.remindersEnabled, isFalse);
      expect(reminderService.scheduled.isEmpty, isTrue);
    });

    testWidgets('11. Home Dashboard renders PersonalizedDevotionalCard with deity focus and target progress',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final pzState = PersonalizationState(
        appState: appState,
        panchangamState: panchangamState,
        audioState: audioState,
      );
      await pzState.setDevotionalInterests({'ganesha', 'shiva'});

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              child: PersonalizedDevotionalCard(
                personalizationState: pzState,
                audioState: audioState,
                sadhanaState: sadhanaState,
                repository: repository,
                mantraRepository: mantraRepository,
                appState: appState,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('DEVOTIONAL FOCUS'), findsOneWidget);
      expect(find.text('Lord Ganesha'), findsOneWidget);
      expect(find.text('Lord Shiva'), findsOneWidget);
      expect(find.text('Daily Sadhana Targets'), findsOneWidget);
      expect(find.text('Japa Repetitions'), findsOneWidget);
    });

    testWidgets('12. SettingsScreen displays Personalization & Practices section with quick edit tiles',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final pzState = PersonalizationState(
        appState: appState,
        panchangamState: panchangamState,
        audioState: audioState,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: SettingsScreen(
            appState: appState,
            personalizationState: pzState,
            panchangamState: panchangamState,
            panchangamRepository: panchangamRepository,
            audioState: audioState,
            sadhanaState: sadhanaState,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Personalization & Practices (अभ्यास एवं रुचि)'), findsOneWidget);
      expect(find.text('Devotional Focus (इष्टदेवता)'), findsOneWidget);
      expect(find.text('Preferred Japa Target'), findsOneWidget);
      expect(find.text('Panchangam Location'), findsOneWidget);
      expect(find.text('Devotional Reminders'), findsOneWidget);
      expect(find.text('Restart Devotee Onboarding'), findsOneWidget);
      expect(find.text('Reset Personalization Preferences'), findsOneWidget);
    });

    testWidgets('13. Reset Personalization restores defaults WITHOUT deleting user bookmarks, notes, or history',
        (WidgetTester tester) async {
      // User has existing favorite scripture and recently read
      expect(appState.isFavorite(1), isTrue);
      appState.toggleFavorite(4); // Add 4 to favorites
      expect(appState.isFavorite(4), isTrue);
      appState.recordRecentlyRead(2);

      final pzState = PersonalizationState(
        appState: appState,
        panchangamState: panchangamState,
        audioState: audioState,
      );
      await pzState.setDevotionalInterests({'hanuman', 'durga'});
      await pzState.setJapaTarget(1008);

      expect(pzState.selectedDeityIds, contains('hanuman'));
      expect(pzState.japaTarget, equals(1008));
      expect(appState.isFavorite(1), isTrue);
      expect(appState.isFavorite(4), isTrue);

      // Perform Reset
      await pzState.resetPersonalization();

      // Personalization preferences reset to defaults
      expect(pzState.selectedDeityIds, contains('ganesha')); // Default
      expect(pzState.japaTarget, equals(108)); // Default

      // User's bookmarks and reading recents are STRICTLY PRESERVED
      expect(appState.isFavorite(1), isTrue);
      expect(appState.isFavorite(4), isTrue);
      expect(appState.recentlyReadScriptureIds, contains(2));
    });

    testWidgets('14. Theme compatibility: Onboarding renders cleanly in Temple Night (dark) theme',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final pzState = PersonalizationState(
        appState: appState,
        panchangamState: panchangamState,
        audioState: audioState,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: OnboardingWizardScreen(
            personalizationState: pzState,
            onFinish: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Welcome to Vedam'), findsOneWidget);
    });

    testWidgets('15. Resilient preference parsing handles missing, malformed, or outdated JSON safely',
        (WidgetTester tester) async {
      // Incomplete or corrupted JSON
      final parsed = DevoteePreferences.fromJson({
        'selected_deity_ids': ['nonexistent_deity', 'shiva'],
        'scripture_script': 'invalid_script',
        'japa_target': -99,
      });

      expect(parsed.selectedDeityIds, contains('shiva'));
      expect(parsed.scriptureScript, equals(ScriptOption.devanagari)); // Safe fallback
      expect(parsed.sadhanaGoals.japaTarget, equals(108)); // Safe fallback
    });
  });
}

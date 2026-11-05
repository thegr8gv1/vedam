import 'package:flutter/material.dart';
import 'core/constants/app_constants.dart';
import 'core/models/daily_darshan.dart';
import 'core/models/vrat_observance.dart';
import 'core/services/audio_service.dart';
import 'core/theme/app_theme.dart';
import 'data/fixtures/authentic_puja_guides_data.dart';
import 'data/repositories/mantra_repository.dart';
import 'data/repositories/scripture_repository_impl.dart';
import 'presentation/navigation/main_screen.dart';
import 'presentation/screens/home/widgets/daily_routine_card.dart';
import 'presentation/screens/home/widgets/dashboard_japa_card.dart';
import 'presentation/screens/home/widgets/panchangam_preview_card.dart';
import 'presentation/screens/home/widgets/scripture_progress_card.dart';
import 'presentation/screens/home/widgets/upcoming_vrat_card.dart';
import 'presentation/screens/library/bookmarks_screen.dart';
import 'presentation/screens/library/verse_learning_screen.dart';
import 'presentation/screens/mantras/mantra_player_screen.dart';
import 'presentation/screens/mantras/mantras_screen.dart';
import 'presentation/screens/mantras/widgets/japa_completion_dialog.dart';
import 'presentation/screens/mantras/widgets/japa_target_modal.dart';
import 'presentation/screens/mantras/widgets/japa_target_selector_widget.dart';
import 'data/repositories/panchangam_repository.dart';
import 'presentation/screens/panchangam/panchangam_screen.dart';
import 'presentation/screens/sadhana/guided_puja_screen.dart';
import 'presentation/screens/vrat/reminders_settings_screen.dart';
import 'presentation/screens/vrat/vrat_calendar_screen.dart';
import 'presentation/screens/vrat/vrat_detail_screen.dart';
import 'state/panchangam_state.dart';
import 'state/app_state.dart';
import 'state/audio_state.dart';
import 'state/sadhana_state.dart';
import 'state/scripture_reader_state.dart';
import 'state/vrat_state.dart';

import 'presentation/screens/festivals/festival_calendar_screen.dart';
import 'presentation/screens/festivals/festival_detail_screen.dart';
import 'data/fixtures/authentic_festival_catalog_data.dart';
import 'data/fixtures/authentic_scriptures_data.dart';
import 'presentation/screens/library/verse_reader_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final repository = ScriptureRepositoryImpl();
  final mantraRepository = MantraRepositoryImpl();
  final audioService = AudioPlaybackServiceImpl();
  final audioState = AudioState(audioService: audioService);
  final appState = AppState();
  final panchangamRepository = PanchangamRepositoryImpl();
  final panchangamState = PanchangamState(repository: panchangamRepository);
  final sadhanaState = SadhanaState();
  final vratState = VratState();
  final scriptureReaderState = ScriptureReaderState();

  int initialTab = 0;
  int? readerScriptureId;
  int? learnScriptureId;
  int? openVerseNumber;
  String? openMantraId;
  bool showMantrasList = false;
  bool showPanchangam = false;
  String? openGuideId;
  int openGuideStep = 0;
  bool openGuideCompleted = false;
  bool showVratCalendar = false;
  String? openVratId;
  String? openVratStatus;
  bool showReminders = false;
  bool showBookmarks = false;
  bool showPreferences = false;
  int? initialJapaTarget;
  int? initialJapaCompleted;
  bool showTargetModal = false;
  bool showTargetSelector = false;
  bool showCompletionDialog = false;
  bool showFestivalCalendar = false;
  String? openFestivalId;

  String? cardParam;

  try {
    cardParam = Uri.base.queryParameters['card'];
    final tab = Uri.base.queryParameters['tab'];
    if (tab == 'library') initialTab = 1;
    if (tab == 'sadhana') initialTab = 2;
    if (tab == 'saved') initialTab = 3;
    if (tab == 'settings') initialTab = 4;
    if (tab == 'mantras') showMantrasList = true;
    if (tab == 'panchangam') showPanchangam = true;
    if (tab == 'vrat') showVratCalendar = true;
    if (tab == 'festivals' || Uri.base.queryParameters['festivals'] == 'true' || Uri.base.queryParameters['calendar'] == 'true') {
      showFestivalCalendar = true;
    }
    final fest = Uri.base.queryParameters['festival'];
    if (fest != null) {
      openFestivalId = fest;
    }
    if (tab == 'reminders') showReminders = true;
    if (tab == 'bookmarks') showBookmarks = true;
    if (Uri.base.queryParameters['prefs'] == 'true') showPreferences = true;
    if (Uri.base.queryParameters['target_modal'] == 'true') showTargetModal = true;
    if (Uri.base.queryParameters['target_selector'] == 'true') showTargetSelector = true;
    if (Uri.base.queryParameters['completion'] == 'true') showCompletionDialog = true;

    final targetParam = Uri.base.queryParameters['target'];
    if (targetParam != null) {
      initialJapaTarget = int.tryParse(targetParam);
    }
    final completedParam = Uri.base.queryParameters['completed_chants'];
    if (completedParam != null) {
      initialJapaCompleted = int.tryParse(completedParam);
    }

    final reader = Uri.base.queryParameters['reader'];
    if (reader != null) {
      readerScriptureId = int.tryParse(reader);
    }

    final learn = Uri.base.queryParameters['learn'];
    if (learn != null) {
      learnScriptureId = int.tryParse(learn);
    }

    final verse = Uri.base.queryParameters['verse'];
    if (verse != null) {
      openVerseNumber = int.tryParse(verse);
    }

    final mantra = Uri.base.queryParameters['mantra'];
    if (mantra != null) {
      openMantraId = mantra;
    }

    final guide = Uri.base.queryParameters['guide'];
    if (guide != null) {
      openGuideId = guide;
    }

    final step = Uri.base.queryParameters['step'];
    if (step != null) {
      openGuideStep = int.tryParse(step) ?? 0;
    }

    if (Uri.base.queryParameters['completed'] == 'true') {
      openGuideCompleted = true;
    }

    final vrat = Uri.base.queryParameters['vrat'];
    if (vrat != null) {
      openVratId = vrat;
    }
    openVratStatus = Uri.base.queryParameters['status'];
  } catch (_) {}

  runApp(VedamApp(
    repository: repository,
    mantraRepository: mantraRepository,
    audioState: audioState,
    panchangamRepository: panchangamRepository,
    panchangamState: panchangamState,
    sadhanaState: sadhanaState,
    vratState: vratState,
    scriptureReaderState: scriptureReaderState,
    appState: appState,
    initialTab: initialTab,
    readerScriptureId: readerScriptureId,
    learnScriptureId: learnScriptureId,
    openVerseNumber: openVerseNumber,
    openMantraId: openMantraId,
    showMantrasList: showMantrasList,
    showPanchangam: showPanchangam,
    openGuideId: openGuideId,
    openGuideStep: openGuideStep,
    openGuideCompleted: openGuideCompleted,
    showVratCalendar: showVratCalendar,
    openVratId: openVratId,
    openVratStatus: openVratStatus,
    showReminders: showReminders,
    showBookmarks: showBookmarks,
    showPreferences: showPreferences,
    initialJapaTarget: initialJapaTarget,
    initialJapaCompleted: initialJapaCompleted,
    showTargetModal: showTargetModal,
    showTargetSelector: showTargetSelector,
    showCompletionDialog: showCompletionDialog,
    cardParam: cardParam,
    showFestivalCalendar: showFestivalCalendar,
    openFestivalId: openFestivalId,
  ));
}

class VedamApp extends StatelessWidget {
  final ScriptureRepositoryImpl repository;
  final MantraRepository? mantraRepository;
  final AudioState? audioState;
  final PanchangamRepository? panchangamRepository;
  final PanchangamState? panchangamState;
  final SadhanaState? sadhanaState;
  final VratState? vratState;
  final ScriptureReaderState? scriptureReaderState;
  final AppState appState;
  final int initialTab;
  final int? readerScriptureId;
  final int? learnScriptureId;
  final int? openVerseNumber;
  final String? openMantraId;
  final bool showMantrasList;
  final bool showPanchangam;
  final String? openGuideId;
  final int openGuideStep;
  final bool openGuideCompleted;
  final bool showVratCalendar;
  final String? openVratId;
  final String? openVratStatus;
  final bool showReminders;
  final bool showBookmarks;
  final bool showPreferences;
  final int? initialJapaTarget;
  final int? initialJapaCompleted;
  final bool showTargetModal;
  final bool showTargetSelector;
  final bool showCompletionDialog;
  final String? cardParam;
  final bool showFestivalCalendar;
  final String? openFestivalId;

  const VedamApp({
    super.key,
    required this.repository,
    this.mantraRepository,
    this.audioState,
    this.panchangamRepository,
    this.panchangamState,
    this.sadhanaState,
    this.vratState,
    this.scriptureReaderState,
    required this.appState,
    this.initialTab = 0,
    this.readerScriptureId,
    this.learnScriptureId,
    this.openVerseNumber,
    this.openMantraId,
    this.showMantrasList = false,
    this.showPanchangam = false,
    this.openGuideId,
    this.openGuideStep = 0,
    this.openGuideCompleted = false,
    this.showVratCalendar = false,
    this.openVratId,
    this.openVratStatus,
    this.showReminders = false,
    this.showBookmarks = false,
    this.showPreferences = false,
    this.initialJapaTarget,
    this.initialJapaCompleted,
    this.showTargetModal = false,
    this.showTargetSelector = false,
    this.showCompletionDialog = false,
    this.cardParam,
    this.showFestivalCalendar = false,
    this.openFestivalId,
  });

  @override
  Widget build(BuildContext context) {
    final mRepo = mantraRepository ?? MantraRepositoryImpl();
    final aState = audioState ?? AudioState(audioService: AudioPlaybackServiceImpl());
    final pRepo = panchangamRepository ?? PanchangamRepositoryImpl();
    final pState = panchangamState ?? PanchangamState(repository: pRepo);
    final sState = sadhanaState ?? SadhanaState();
    final vState = vratState ?? VratState();
    final rState = scriptureReaderState ?? ScriptureReaderState();

    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        Widget homeWidget = MainScreen(
          repository: repository,
          mantraRepository: mRepo,
          audioState: aState,
          panchangamRepository: pRepo,
          panchangamState: pState,
          sadhanaState: sState,
          vratState: vState,
          readerState: rState,
          appState: appState,
          initialIndex: initialTab,
        );

        if (openFestivalId != null) {
          final event = AuthenticFestivalCatalogData.getEventById(openFestivalId!) ??
              AuthenticFestivalCatalogData.allEvents.first;
          homeWidget = FestivalDetailScreen(
            event: event,
            vratState: vState,
            panchangamState: pState,
            sadhanaState: sState,
            mantraRepository: mRepo,
            audioState: aState,
          );
        } else if (showFestivalCalendar) {
          homeWidget = FestivalCalendarScreen(
            vratState: vState,
            panchangamState: pState,
            panchangamRepository: pRepo,
            sadhanaState: sState,
            mantraRepository: mRepo,
            audioState: aState,
          );
        } else if (cardParam == 'panchangam') {
          homeWidget = Scaffold(
            appBar: AppBar(title: const Text("Today's Panchangam")),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: PanchangamPreviewCard(
                  panchangamState: pState,
                  darshan: DailyDarshan.today(),
                  onTap: () {},
                ),
              ),
            ),
          );
        } else if (cardParam == 'routine') {
          homeWidget = Scaffold(
            appBar: AppBar(title: const Text("Daily Spiritual Routine")),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: DailyRoutineCard(
                  sadhanaState: sState,
                  appState: appState,
                  onOpenSadhana: () {},
                ),
              ),
            ),
          );
        } else if (cardParam == 'japa') {
          if (initialJapaTarget != null) {
            aState.setTargetRepetitions(initialJapaTarget!);
          }
          if (initialJapaCompleted != null) {
            for (int i = 0; i < initialJapaCompleted!; i++) {
              aState.incrementManualRepetition();
            }
          }
          homeWidget = Scaffold(
            appBar: AppBar(title: const Text("Daily Japa Practice")),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: DashboardJapaCard(
                  audioState: aState,
                  mantraRepository: mRepo,
                ),
              ),
            ),
          );
        } else if (cardParam == 'vrat') {
          homeWidget = Scaffold(
            appBar: AppBar(title: const Text("Upcoming Vrat & Observances")),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: UpcomingVratCard(
                  vratState: vState,
                  panchangamState: pState,
                ),
              ),
            ),
          );
        } else if (cardParam == 'scripture') {
          homeWidget = Scaffold(
            appBar: AppBar(title: const Text("Scripture Learning Progress")),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: ScriptureProgressCard(
                  repository: repository,
                  appState: appState,
                  readerState: rState,
                  audioState: aState,
                  onOpenLibrary: () {},
                ),
              ),
            ),
          );
        } else if (showBookmarks) {
          homeWidget = BookmarksScreen(
            repository: repository,
            readerState: rState,
            audioState: aState,
          );
        } else if (showReminders) {
          homeWidget = RemindersSettingsScreen(vratState: vState);
        } else if (openVratId != null) {
          final targetId = (openVratId == 'default' || vState.getObservanceById(openVratId!) == null)
              ? (vState.observances.isNotEmpty ? vState.observances.first.id : openVratId!)
              : openVratId!;
          if (openVratStatus == 'completed') {
            final existing = vState.getObservanceById(targetId);
            if (existing != null && existing.status != ObservanceStatus.completed) {
              vState.updateObservanceStatus(targetId, ObservanceStatus.completed);
            }
          }
          homeWidget = VratDetailScreen(
            observanceId: targetId,
            vratState: vState,
            sadhanaState: sState,
            mantraRepository: mRepo,
            audioState: aState,
            panchangamState: pState,
          );
        } else if (showVratCalendar) {
          homeWidget = VratCalendarScreen(
            vratState: vState,
            sadhanaState: sState,
            mantraRepository: mRepo,
            audioState: aState,
            panchangamState: pState,
          );
        } else if (openGuideId != null) {
          final guide = AuthenticPujaGuidesData.getGuideById(openGuideId!) ?? AuthenticPujaGuidesData.allGuides.first;
          sState.startGuide(guide, stepIndex: openGuideStep);
          if (openGuideCompleted) {
            sState.completeGuide();
          }
          homeWidget = GuidedPujaScreen(
            guide: guide,
            sadhanaState: sState,
            mantraRepository: mRepo,
            audioState: aState,
          );
        } else if (showPanchangam) {
          homeWidget = PanchangamScreen(
            state: pState,
            repository: pRepo,
          );
        } else if (showMantrasList) {
          homeWidget = MantrasScreen(
            repository: mRepo,
            audioState: aState,
          );
        } else if (showTargetSelector) {
          if (initialJapaTarget != null) {
            aState.setTargetRepetitions(initialJapaTarget!);
          }
          homeWidget = Scaffold(
            appBar: AppBar(title: const Text('Select Chanting Target')),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: JapaTargetSelectorWidget(audioState: aState),
              ),
            ),
          );
        } else if (showTargetModal) {
          homeWidget = Scaffold(
            appBar: AppBar(title: const Text('Japa Target Selection')),
            body: SafeArea(
              child: JapaTargetModal(audioState: aState),
            ),
          );
        } else if (showCompletionDialog) {
          if (initialJapaTarget != null) {
            aState.setTargetRepetitions(initialJapaTarget!);
          }
          final completed = initialJapaCompleted ?? aState.targetRepetitions;
          for (int i = 0; i < completed; i++) {
            aState.incrementManualRepetition();
          }
          homeWidget = Scaffold(
            appBar: AppBar(title: const Text('Japa Completion Notice')),
            body: Center(
              child: SingleChildScrollView(
                child: JapaCompletionDialog(audioState: aState),
              ),
            ),
          );
        } else if (openMantraId != null) {
          final m = mRepo.getMantraById(openMantraId!) ??
              mRepo.getAllMantras().first;
          if (initialJapaTarget != null) {
            aState.setTargetRepetitions(initialJapaTarget!);
          }
          if (initialJapaCompleted != null) {
            for (int i = 0; i < initialJapaCompleted!; i++) {
              aState.incrementManualRepetition();
            }
          }
          homeWidget = MantraPlayerScreen(
            mantra: m,
            audioState: aState,
            playlist: mRepo.getAllMantras(),
          );
        } else if (learnScriptureId != null) {
          final s = kAuthenticScriptures.firstWhere(
            (element) => element.id == learnScriptureId,
            orElse: () => kAuthenticScriptures.first,
          );
          homeWidget = VerseLearningScreen(
            scripture: s,
            readerState: rState,
            initialVerseNumber: openVerseNumber ?? 1,
            audioState: aState,
            initialShowPreferences: showPreferences,
          );
        } else if (readerScriptureId != null) {
          final s = kAuthenticScriptures.firstWhere(
            (element) => element.id == readerScriptureId,
            orElse: () => kAuthenticScriptures.first,
          );
          homeWidget = VerseReaderScreen(
            scripture: s,
            appState: appState,
            readerState: rState,
            audioState: aState,
          );
        }

        return MaterialApp(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: appState.themeMode,
          home: homeWidget,
        );
      },
    );
  }
}

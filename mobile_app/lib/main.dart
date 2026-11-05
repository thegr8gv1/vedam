import 'package:flutter/material.dart';
import 'core/constants/app_constants.dart';
import 'core/services/audio_service.dart';
import 'core/theme/app_theme.dart';
import 'data/fixtures/authentic_puja_guides_data.dart';
import 'data/repositories/mantra_repository.dart';
import 'data/repositories/scripture_repository_impl.dart';
import 'presentation/navigation/main_screen.dart';
import 'presentation/screens/mantras/mantra_player_screen.dart';
import 'presentation/screens/mantras/mantras_screen.dart';
import 'data/repositories/panchangam_repository.dart';
import 'presentation/screens/panchangam/panchangam_screen.dart';
import 'presentation/screens/sadhana/guided_puja_screen.dart';
import 'state/panchangam_state.dart';
import 'state/app_state.dart';
import 'state/audio_state.dart';
import 'state/sadhana_state.dart';

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

  int initialTab = 0;
  int? readerScriptureId;
  String? openMantraId;
  bool showMantrasList = false;
  bool showPanchangam = false;
  String? openGuideId;
  int openGuideStep = 0;
  bool openGuideCompleted = false;

  try {
    final tab = Uri.base.queryParameters['tab'];
    if (tab == 'library') initialTab = 1;
    if (tab == 'sadhana') initialTab = 2;
    if (tab == 'saved') initialTab = 3;
    if (tab == 'settings') initialTab = 4;
    if (tab == 'mantras') showMantrasList = true;
    if (tab == 'panchangam') showPanchangam = true;

    final reader = Uri.base.queryParameters['reader'];
    if (reader != null) {
      readerScriptureId = int.tryParse(reader);
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
  } catch (_) {}

  runApp(VedamApp(
    repository: repository,
    mantraRepository: mantraRepository,
    audioState: audioState,
    panchangamRepository: panchangamRepository,
    panchangamState: panchangamState,
    sadhanaState: sadhanaState,
    appState: appState,
    initialTab: initialTab,
    readerScriptureId: readerScriptureId,
    openMantraId: openMantraId,
    showMantrasList: showMantrasList,
    showPanchangam: showPanchangam,
    openGuideId: openGuideId,
    openGuideStep: openGuideStep,
    openGuideCompleted: openGuideCompleted,
  ));
}

class VedamApp extends StatelessWidget {
  final ScriptureRepositoryImpl repository;
  final MantraRepository? mantraRepository;
  final AudioState? audioState;
  final PanchangamRepository? panchangamRepository;
  final PanchangamState? panchangamState;
  final SadhanaState? sadhanaState;
  final AppState appState;
  final int initialTab;
  final int? readerScriptureId;
  final String? openMantraId;
  final bool showMantrasList;
  final bool showPanchangam;
  final String? openGuideId;
  final int openGuideStep;
  final bool openGuideCompleted;

  const VedamApp({
    super.key,
    required this.repository,
    this.mantraRepository,
    this.audioState,
    this.panchangamRepository,
    this.panchangamState,
    this.sadhanaState,
    required this.appState,
    this.initialTab = 0,
    this.readerScriptureId,
    this.openMantraId,
    this.showMantrasList = false,
    this.showPanchangam = false,
    this.openGuideId,
    this.openGuideStep = 0,
    this.openGuideCompleted = false,
  });

  @override
  Widget build(BuildContext context) {
    final mRepo = mantraRepository ?? MantraRepositoryImpl();
    final aState = audioState ?? AudioState(audioService: AudioPlaybackServiceImpl());
    final pRepo = panchangamRepository ?? PanchangamRepositoryImpl();
    final pState = panchangamState ?? PanchangamState(repository: pRepo);
    final sState = sadhanaState ?? SadhanaState();

    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        Widget homeWidget = MainScreen(
          repository: repository,
          mantraRepository: mRepo,
          audioState: aState,
          panchangamRepository: pRepo,
          panchangamState: pState,
          appState: appState,
          initialIndex: initialTab,
        );

        if (openGuideId != null) {
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
        } else if (openMantraId != null) {
          final m = mRepo.getMantraById(openMantraId!) ??
              mRepo.getAllMantras().first;
          homeWidget = MantraPlayerScreen(
            mantra: m,
            audioState: aState,
          );
        } else if (readerScriptureId != null) {
          final s = kAuthenticScriptures.firstWhere(
            (element) => element.id == readerScriptureId,
            orElse: () => kAuthenticScriptures.first,
          );
          homeWidget = VerseReaderScreen(
            scripture: s,
            appState: appState,
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

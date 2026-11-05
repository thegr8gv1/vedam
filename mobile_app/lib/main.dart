import 'package:flutter/material.dart';
import 'core/constants/app_constants.dart';
import 'core/services/audio_service.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/mantra_repository.dart';
import 'data/repositories/scripture_repository_impl.dart';
import 'presentation/navigation/main_screen.dart';
import 'presentation/screens/mantras/mantra_player_screen.dart';
import 'presentation/screens/mantras/mantras_screen.dart';
import 'state/app_state.dart';
import 'state/audio_state.dart';

import 'data/fixtures/authentic_scriptures_data.dart';
import 'presentation/screens/library/verse_reader_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final repository = ScriptureRepositoryImpl();
  final mantraRepository = MantraRepositoryImpl();
  final audioService = AudioPlaybackServiceImpl();
  final audioState = AudioState(audioService: audioService);
  final appState = AppState();

  int initialTab = 0;
  int? readerScriptureId;
  String? openMantraId;
  bool showMantrasList = false;

  try {
    final tab = Uri.base.queryParameters['tab'];
    if (tab == 'library') initialTab = 1;
    if (tab == 'sadhana') initialTab = 2;
    if (tab == 'saved') initialTab = 3;
    if (tab == 'settings') initialTab = 4;
    if (tab == 'mantras') showMantrasList = true;

    final reader = Uri.base.queryParameters['reader'];
    if (reader != null) {
      readerScriptureId = int.tryParse(reader);
    }

    final mantra = Uri.base.queryParameters['mantra'];
    if (mantra != null) {
      openMantraId = mantra;
    }
  } catch (_) {}

  runApp(VedamApp(
    repository: repository,
    mantraRepository: mantraRepository,
    audioState: audioState,
    appState: appState,
    initialTab: initialTab,
    readerScriptureId: readerScriptureId,
    openMantraId: openMantraId,
    showMantrasList: showMantrasList,
  ));
}

class VedamApp extends StatelessWidget {
  final ScriptureRepositoryImpl repository;
  final MantraRepository? mantraRepository;
  final AudioState? audioState;
  final AppState appState;
  final int initialTab;
  final int? readerScriptureId;
  final String? openMantraId;
  final bool showMantrasList;

  const VedamApp({
    super.key,
    required this.repository,
    this.mantraRepository,
    this.audioState,
    required this.appState,
    this.initialTab = 0,
    this.readerScriptureId,
    this.openMantraId,
    this.showMantrasList = false,
  });

  @override
  Widget build(BuildContext context) {
    final mRepo = mantraRepository ?? MantraRepositoryImpl();
    final aState = audioState ?? AudioState(audioService: AudioPlaybackServiceImpl());

    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        Widget homeWidget = MainScreen(
          repository: repository,
          mantraRepository: mRepo,
          audioState: aState,
          appState: appState,
          initialIndex: initialTab,
        );

        if (showMantrasList) {
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

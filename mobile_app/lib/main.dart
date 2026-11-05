import 'package:flutter/material.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/scripture_repository_impl.dart';
import 'presentation/navigation/main_screen.dart';
import 'state/app_state.dart';

import 'data/fixtures/authentic_scriptures_data.dart';
import 'presentation/screens/library/verse_reader_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final repository = ScriptureRepositoryImpl();
  final appState = AppState();

  int initialTab = 0;
  int? readerScriptureId;

  try {
    final tab = Uri.base.queryParameters['tab'];
    if (tab == 'library') initialTab = 1;
    if (tab == 'sadhana') initialTab = 2;
    if (tab == 'saved') initialTab = 3;
    if (tab == 'settings') initialTab = 4;

    final reader = Uri.base.queryParameters['reader'];
    if (reader != null) {
      readerScriptureId = int.tryParse(reader);
    }
  } catch (_) {}

  runApp(VedamApp(
    repository: repository,
    appState: appState,
    initialTab: initialTab,
    readerScriptureId: readerScriptureId,
  ));
}

class VedamApp extends StatelessWidget {
  final ScriptureRepositoryImpl repository;
  final AppState appState;
  final int initialTab;
  final int? readerScriptureId;

  const VedamApp({
    super.key,
    required this.repository,
    required this.appState,
    this.initialTab = 0,
    this.readerScriptureId,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        Widget homeWidget = MainScreen(
          repository: repository,
          appState: appState,
          initialIndex: initialTab,
        );

        if (readerScriptureId != null) {
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

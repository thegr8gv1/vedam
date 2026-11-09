import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vedam_app/core/models/mantra_item.dart';
import 'package:vedam_app/core/services/audio_service.dart';
import 'package:vedam_app/data/repositories/mantra_repository.dart';
import 'package:vedam_app/data/repositories/scripture_repository_impl.dart';
import 'package:vedam_app/l10n/app_localizations.dart';
import 'package:vedam_app/presentation/screens/favorites/favorites_screen.dart';
import 'package:vedam_app/presentation/screens/library/verse_learning_screen.dart';
import 'package:vedam_app/presentation/screens/library/verse_reader_screen.dart';
import 'package:vedam_app/presentation/screens/mantras/mantras_screen.dart';
import 'package:vedam_app/state/app_state.dart';
import 'package:vedam_app/state/audio_state.dart';
import 'package:vedam_app/state/scripture_reader_state.dart';

class _MockAudioService implements AudioPlaybackService {
  final _stateController = StreamController<PlayerState>.broadcast();
  final _posController = StreamController<Duration>.broadcast();
  final _durController = StreamController<Duration>.broadcast();

  PlayerState _state = PlayerState.stopped;
  Duration _pos = Duration.zero;
  final Duration _dur = const Duration(seconds: 30);
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
  Future<void> playMantra(MantraItem item) async {
    _active = item;
    if (item.isBundled) {
      _state = PlayerState.playing;
      _stateController.add(PlayerState.playing);
    } else {
      // Simulate vault unbundled audio file missing on mobile
      _state = PlayerState.stopped;
      _stateController.add(PlayerState.stopped);
      throw Exception('Vault audio file not bundled on mobile device');
    }
  }

  @override
  Future<void> pause() async {
    _state = PlayerState.paused;
    _stateController.add(PlayerState.paused);
  }

  @override
  Future<void> resume() async {
    _state = PlayerState.playing;
    _stateController.add(PlayerState.playing);
  }

  @override
  Future<void> stop() async {
    _state = PlayerState.stopped;
    _stateController.add(PlayerState.stopped);
  }

  @override
  Future<void> seek(Duration position) async {
    _pos = position;
    _posController.add(position);
  }

  @override
  Future<void> setPlaybackRate(double rate) async {}

  @override
  Future<void> dispose() async {
    await _stateController.close();
    await _posController.close();
    await _durController.close();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ScriptureRepositoryImpl scriptureRepo;
  late MantraRepository mantraRepo;
  late _MockAudioService audioService;
  late AudioState audioState;
  late AppState appState;
  late ScriptureReaderState readerState;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    scriptureRepo = ScriptureRepositoryImpl();
    mantraRepo = MantraRepositoryImpl();
    audioService = _MockAudioService();
    audioState = AudioState(audioService: audioService, prefs: prefs);
    appState = AppState();
    readerState = ScriptureReaderState(prefs: prefs);

    await audioState.init();
    await readerState.init();
  });

  tearDown(() {
    audioState.dispose();
  });

  Widget createTestWidget(Widget child, {Size surfaceSize = const Size(400, 800)}) {
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''),
      ],
      home: MediaQuery(
        data: MediaQueryData(size: surfaceSize),
        child: child,
      ),
    );
  }

  group('Phase 20A: Cross-Feature Workflow Widget Tests', () {
    testWidgets('1. Vault audio fallback dialog is presented when unbundled recording is tapped in VerseReaderScreen',
        (tester) async {
      // Find a scripture that has vault unbundled audio mapped (e.g. Shiva Tandava Stotram, id: 2)
      final shivaTandava = (await scriptureRepo.getScriptureById(2))!;

      await tester.pumpWidget(
        createTestWidget(
          VerseReaderScreen(
            scripture: shivaTandava,
            appState: appState,
            readerState: readerState,
            audioState: audioState,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find the Chant Verse (Audio) button for Verse 1
      final audioBtn = find.text('Chant Verse (Audio)');
      expect(audioBtn, findsOneWidget);

      await tester.tap(audioBtn);
      await tester.pumpAndSettle();

      // Because this is a vault-dependent recording (VEDA-MTR-0443) and not bundled,
      // the app presents the respectful Vault Archive Recording dialog
      expect(find.text('Vault Archive Recording'), findsOneWidget);
      expect(find.textContaining('This master recording is preserved in the desktop vault'), findsOneWidget);
      expect(find.text('Understood'), findsOneWidget);

      // Dismiss dialog cleanly
      await tester.tap(find.text('Understood'));
      await tester.pumpAndSettle();
      expect(find.text('Vault Archive Recording'), findsNothing);
    });

    testWidgets('2. VerseLearningScreen audio card presents respectful fallback for vault recordings',
        (tester) async {
      final shivaTandava = (await scriptureRepo.getScriptureById(2))!;

      await tester.pumpWidget(
        createTestWidget(
          VerseLearningScreen(
            scripture: shivaTandava,
            readerState: readerState,
            audioState: audioState,
            appState: appState,
            initialVerseNumber: 1,
          ),
          surfaceSize: const Size(400, 1000),
        ),
      );
      await tester.pumpAndSettle();

      final playVerifiedIcon = find.byTooltip('Play Verified Audio');
      expect(playVerifiedIcon, findsOneWidget);

      await tester.ensureVisible(playVerifiedIcon);
      await tester.tap(playVerifiedIcon);
      await tester.pumpAndSettle();

      expect(find.text('Vault Archive Recording'), findsOneWidget);
      expect(find.text('Understood'), findsOneWidget);

      await tester.tap(find.text('Understood'));
      await tester.pumpAndSettle();
      expect(find.text('Vault Archive Recording'), findsNothing);
    });

    testWidgets('3. MantrasScreen filters combine predictably and Reset Filters restores full catalog',
        (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          MantrasScreen(
            repository: mantraRepo,
            audioState: audioState,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check baseline count: 455 Sacred Mantras Available
      expect(find.textContaining('Sacred Mantras Available'), findsOneWidget);

      // 1. Filter by search text 'shiva'
      await tester.enterText(find.byType(TextField), 'shiva');
      await tester.pumpAndSettle();

      // Filtered results should be less than 455
      expect(find.text('Reset Filters'), findsOneWidget);

      // 2. Tap Reset Filters
      await tester.tap(find.text('Reset Filters'));
      await tester.pumpAndSettle();

      // Full catalog restored
      expect(find.textContaining('455 Sacred Mantras Available'), findsOneWidget);
    });

    testWidgets('4. Devotional Shelf 5 tabs synchronize and display bookmarks and notes',
        (tester) async {
      final shivaTandava = (await scriptureRepo.getScriptureById(2))!;
      final verse1 = shivaTandava.verses.first;

      // Add a bookmark and a note
      await readerState.toggleBookmark(verse1, shivaTandava);
      await readerState.saveNote(verse1, shivaTandava, 'Meditation on cosmic stillness');

      await tester.pumpWidget(
        createTestWidget(
          FavoritesScreen(
            repository: scriptureRepo,
            appState: appState,
            readerState: readerState,
            audioState: audioState,
            mantraRepository: mantraRepo,
            onNavigateToTab: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify 5 tab labels are visible
      expect(find.widgetWithText(Tab, 'Scriptures (3)'), findsOneWidget);
      expect(find.widgetWithText(Tab, 'Bookmarks (1)'), findsOneWidget);
      expect(find.widgetWithText(Tab, 'Notes (1)'), findsOneWidget);
      expect(find.widgetWithText(Tab, 'Mantras (0)'), findsOneWidget);
      expect(find.widgetWithText(Tab, 'Recents (4)'), findsOneWidget);

      // Switch to Notes tab
      await tester.tap(find.widgetWithText(Tab, 'Notes (1)'));
      await tester.pumpAndSettle();

      // Note text is displayed with personal reflection label
      expect(find.text('Meditation on cosmic stillness'), findsOneWidget);
    });

    testWidgets('5. Responsive layout check: No overflow at 360dp phone width',
        (tester) async {
      final shivaTandava = (await scriptureRepo.getScriptureById(2))!;

      await tester.pumpWidget(
        createTestWidget(
          VerseReaderScreen(
            scripture: shivaTandava,
            appState: appState,
            readerState: readerState,
            audioState: audioState,
          ),
          surfaceSize: const Size(360, 640),
        ),
      );
      await tester.pumpAndSettle();

      // Verify no RenderFlex overflow error thrown
      expect(tester.takeException(), isNull);
    });
  });
}

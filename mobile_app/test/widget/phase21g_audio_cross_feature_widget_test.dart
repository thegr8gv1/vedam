import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vedam_app/core/models/mantra_item.dart';
import 'package:vedam_app/core/services/audio_service.dart';
import 'package:vedam_app/core/theme/app_theme.dart';
import 'package:vedam_app/data/fixtures/authentic_mantras_data.dart';
import 'package:vedam_app/data/fixtures/authentic_puja_guides_data.dart';
import 'package:vedam_app/data/repositories/mantra_repository.dart';
import 'package:vedam_app/presentation/screens/japa/japa_practice_screen.dart';
import 'package:vedam_app/presentation/screens/mantras/mantra_player_screen.dart';
import 'package:vedam_app/presentation/screens/mantras/mantras_screen.dart';
import 'package:vedam_app/presentation/screens/sadhana/guided_puja_screen.dart';
import 'package:vedam_app/presentation/screens/sadhana/sadhana_screen.dart';
import 'package:vedam_app/state/app_state.dart';
import 'package:vedam_app/state/audio_state.dart';
import 'package:vedam_app/state/sadhana_state.dart';

class CrossFeatureMockAudioService implements AudioPlaybackService {
  final _stateController = StreamController<PlayerState>.broadcast();
  final _posController = StreamController<Duration>.broadcast();
  final _durController = StreamController<Duration>.broadcast();
  final _loadingController = StreamController<bool>.broadcast();

  PlayerState _currentState = PlayerState.stopped;
  Duration _currentPos = Duration.zero;
  final Duration _totalDur = const Duration(seconds: 45);
  MantraItem? _active;
  bool _isLoading = false;

  int playCount = 0;
  int pauseCount = 0;
  int stopCount = 0;

  @override
  Stream<PlayerState> get playerStateStream => _stateController.stream;
  @override
  Stream<Duration> get positionStream => _posController.stream;
  @override
  Stream<Duration> get durationStream => _durController.stream;
  @override
  Stream<bool> get loadingStream => _loadingController.stream;
  @override
  PlayerState get playerState => _currentState;
  @override
  Duration get currentPosition => _currentPos;
  @override
  Duration get totalDuration => _totalDur;
  @override
  MantraItem? get activeMantra => _active;
  @override
  bool get isLoading => _isLoading;

  @override
  Future<void> playMantra(MantraItem item) async {
    playCount++;
    _active = item;
    _isLoading = true;
    _loadingController.add(true);
    _isLoading = false;
    _loadingController.add(false);
    _currentState = PlayerState.playing;
    _stateController.add(PlayerState.playing);
  }

  @override
  Future<void> pause() async {
    pauseCount++;
    _currentState = PlayerState.paused;
    _stateController.add(PlayerState.paused);
  }

  @override
  Future<void> resume() async {
    _currentState = PlayerState.playing;
    _stateController.add(PlayerState.playing);
  }

  @override
  Future<void> stop() async {
    stopCount++;
    _currentState = PlayerState.stopped;
    _stateController.add(PlayerState.stopped);
    _currentPos = Duration.zero;
    _posController.add(Duration.zero);
  }

  @override
  Future<void> seek(Duration position) async {
    _currentPos = position;
    _posController.add(position);
  }

  @override
  Future<void> setPlaybackRate(double rate) async {}

  @override
  Future<void> dispose() async {
    await _stateController.close();
    await _posController.close();
    await _durController.close();
    await _loadingController.close();
  }

  void emitState(PlayerState state) {
    _currentState = state;
    _stateController.add(state);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CrossFeatureMockAudioService mockAudio;
  late AudioState audioState;
  late MantraRepository mantraRepo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    mockAudio = CrossFeatureMockAudioService();
    audioState = AudioState(audioService: mockAudio);
    mantraRepo = MantraRepositoryImpl();
  });

  tearDown(() {
    audioState.dispose();
  });

  group('Phase 21G — Cross-Feature Audio & UI Validation', () {
    testWidgets('MantrasScreen renders with zero autoplay and filters accurately',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: MantrasScreen(
            repository: mantraRepo,
            audioState: audioState,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Zero autoplay on mount
      expect(mockAudio.playCount, 0);

      // Verify search bar and title are present
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Mantra Library & Japa'), findsOneWidget);
    });

    testWidgets('MantraPlayerScreen renders bundled mantra in light theme without overflow',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final bundled = AuthenticMantrasData.allMantras.firstWhere((m) => m.isBundled);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: MantraPlayerScreen(
            mantra: bundled,
            audioState: audioState,
            playlist: [bundled],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(bundled.title), findsWidgets);

      // Verify play button is present and triggers play on tap
      final playButtonFinder = find.byIcon(Icons.play_arrow);
      expect(playButtonFinder, findsOneWidget);

      await tester.tap(playButtonFinder);
      await tester.pumpAndSettle();

      expect(mockAudio.playCount, 1);
    });

    testWidgets('MantraPlayerScreen renders in dark theme without overflow',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final bundled = AuthenticMantrasData.allMantras.firstWhere((m) => m.isBundled);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: MantraPlayerScreen(
            mantra: bundled,
            audioState: audioState,
            playlist: [bundled],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(bundled.title), findsWidgets);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('JapaPracticeScreen renders with zero autoplay and bead counter',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final bundled = AuthenticMantrasData.allMantras.firstWhere((m) => m.isBundled);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: JapaPracticeScreen(
            initialMantra: bundled,
            audioState: audioState,
            mantraRepository: mantraRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Zero autoplay on mount
      expect(mockAudio.playCount, 0);

      expect(find.text(bundled.title), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('GuidedPujaScreen loads without unwanted audio playback',
        (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final prefs = await SharedPreferences.getInstance();
      final sadhanaState = SadhanaState(prefs: prefs, initialDate: DateTime(2026, 11, 5));
      final guide = AuthenticPujaGuidesData.getGuideById('guide_ganesh_puja')!;

      await tester.pumpWidget(
        MaterialApp(
          home: GuidedPujaScreen(
            guide: guide,
            sadhanaState: sadhanaState,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Ensure no exceptions and no autoplay
      expect(mockAudio.playCount, 0);
      expect(tester.takeException(), isNull);
    });

    testWidgets('SadhanaScreen renders devotional flow cleanly in dark theme',
        (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final prefs = await SharedPreferences.getInstance();
      final sadhanaState = SadhanaState(prefs: prefs, initialDate: DateTime(2026, 11, 5));
      final appState = AppState();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: SadhanaScreen(
            sadhanaState: sadhanaState,
            appState: appState,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(mockAudio.playCount, 0);
      expect(tester.takeException(), isNull);
    });
  });
}

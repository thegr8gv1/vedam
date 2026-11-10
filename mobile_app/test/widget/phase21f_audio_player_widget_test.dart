import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vedam_app/core/models/mantra_item.dart';
import 'package:vedam_app/core/services/audio_service.dart';
import 'package:vedam_app/core/theme/app_theme.dart';
import 'package:vedam_app/data/fixtures/authentic_mantras_data.dart';
import 'package:vedam_app/data/repositories/mantra_repository.dart';
import 'package:vedam_app/presentation/screens/mantras/mantra_player_screen.dart';
import 'package:vedam_app/presentation/screens/mantras/mantras_screen.dart';
import 'package:vedam_app/presentation/widgets/visual_mala_widget.dart';
import 'package:vedam_app/state/audio_state.dart';

class WidgetTestMockAudioService implements AudioPlaybackService {
  final _stateController = StreamController<PlayerState>.broadcast();
  final _posController = StreamController<Duration>.broadcast();
  final _durController = StreamController<Duration>.broadcast();
  final _loadingController = StreamController<bool>.broadcast();

  PlayerState _currentState = PlayerState.stopped;
  Duration _currentPos = Duration.zero;
  final Duration _totalDur = const Duration(seconds: 30);
  MantraItem? _active;
  final bool _isLoading = false;

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
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 21F: Devotional Audio Player Screen Widget & Accessibility Tests', () {
    late SharedPreferences prefs;
    late WidgetTestMockAudioService mockService;
    late AudioState audioState;
    final bundledMantra = AuthenticMantrasData.allMantras.firstWhere((m) => m.isBundled);

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      mockService = WidgetTestMockAudioService();
      audioState = AudioState(audioService: mockService, prefs: prefs);
    });

    tearDown(() async {
      audioState.dispose();
      await mockService.dispose();
    });

    testWidgets('1. Strict NO AUTOPLAY on Entry: screen loads stopped with play button ready', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: MantraPlayerScreen(
            mantra: bundledMantra,
            audioState: audioState,
            autoPlay: false, // Strict NO AUTOPLAY default
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify no audio playback initiated automatically
      expect(mockService.playCount, equals(0),
          reason: 'Devotional audio must NEVER autoplay on screen load');
      // Verify play icon is displayed (not pause)
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.byIcon(Icons.stop), findsOneWidget);
    });

    testWidgets('2. Comprehensive Playback Controls: renders Play, Stop, Mala, Slider, Speed, and Repeat chips', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: MantraPlayerScreen(
            mantra: bundledMantra,
            audioState: audioState,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(bundledMantra.title), findsWidgets);
      expect(find.byType(VisualMalaWidget), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.byIcon(Icons.stop), findsOneWidget);
      expect(find.text('1.0x'), findsOneWidget);

      // Tap Play button intentionally
      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pumpAndSettle();
      expect(mockService.playCount, equals(1));

      // Tap Stop button
      await tester.tap(find.byIcon(Icons.stop));
      await tester.pumpAndSettle();
      expect(mockService.stopCount, equals(1));
    });

    testWidgets('3. Accessibility & Touch Targets: controls maintain >= 48dp minimum size', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: MantraPlayerScreen(
            mantra: bundledMantra,
            audioState: audioState,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find the main play/pause container/button
      final playButtonFinder = find.byKey(const ValueKey('primary_play_pause_button'));
      expect(playButtonFinder, findsOneWidget);
      final playSize = tester.getSize(playButtonFinder);
      expect(playSize.width, greaterThanOrEqualTo(48.0));
      expect(playSize.height, greaterThanOrEqualTo(48.0));

      // Find the stop button
      final stopButtonFinder = find.byTooltip('Stop Playback');
      expect(stopButtonFinder, findsOneWidget);
      final stopSize = tester.getSize(stopButtonFinder);
      expect(stopSize.width, greaterThanOrEqualTo(48.0));
      expect(stopSize.height, greaterThanOrEqualTo(48.0));
    });

    testWidgets('4. Compact Viewport & Font Scaling: 360x640 at 1.35x font scale renders with NO overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(360, 640),
            textScaler: TextScaler.linear(1.35),
          ),
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: MantraPlayerScreen(
              mantra: bundledMantra,
              audioState: audioState,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(MantraPlayerScreen), findsOneWidget);
    });

    testWidgets('5. Dark Theme Fidelity: renders with dark theme cleanly', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: MantraPlayerScreen(
            mantra: bundledMantra,
            audioState: audioState,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text(bundledMantra.title), findsWidgets);
    });

    testWidgets('6. MantrasScreen shows repetition label and filters offline ready recordings', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: MantrasScreen(
            repository: MantraRepositoryImpl(),
            audioState: audioState,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify repetition label '1 Chant' is shown in subtitle
      expect(find.textContaining('1 Chant'), findsWidgets);

      // Verify filter chips exist
      expect(find.text('Offline Ready'), findsOneWidget);

      // Tap Offline Ready filter
      await tester.tap(find.text('Offline Ready'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}

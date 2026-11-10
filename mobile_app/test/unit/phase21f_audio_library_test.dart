import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vedam_app/core/models/japa_practice_session.dart';
import 'package:vedam_app/core/models/mantra_item.dart';
import 'package:vedam_app/core/services/audio_service.dart';
import 'package:vedam_app/data/fixtures/authentic_mantras_data.dart';
import 'package:vedam_app/data/fixtures/authentic_scriptures_data.dart';
import 'package:vedam_app/state/audio_state.dart';

class TestMockAudioService implements AudioPlaybackService {
  final _stateController = StreamController<PlayerState>.broadcast();
  final _posController = StreamController<Duration>.broadcast();
  final _durController = StreamController<Duration>.broadcast();
  final _loadingController = StreamController<bool>.broadcast();

  PlayerState _currentState = PlayerState.stopped;
  Duration _currentPos = Duration.zero;
  Duration _totalDur = const Duration(seconds: 10);
  MantraItem? _active;
  bool _isLoading = false;
  double _rate = 1.0;

  int playCount = 0;
  int pauseCount = 0;
  int resumeCount = 0;
  int stopCount = 0;
  int seekCount = 0;
  int disposeCount = 0;

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
  double get rate => _rate;

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
    resumeCount++;
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
    seekCount++;
    _currentPos = position;
    _posController.add(position);
  }

  @override
  Future<void> setPlaybackRate(double rate) async {
    _rate = rate;
  }

  @override
  Future<void> dispose() async {
    disposeCount++;
    await _stateController.close();
    await _posController.close();
    await _durController.close();
    await _loadingController.close();
  }

  void emitState(PlayerState state) {
    _currentState = state;
    _stateController.add(state);
  }

  void emitPosition(Duration pos) {
    _currentPos = pos;
    _posController.add(pos);
  }

  void emitDuration(Duration dur) {
    _totalDur = dur;
    _durController.add(dur);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 21F: Devotional Audio Library & Playback Foundation Unit Tests', () {
    late SharedPreferences prefs;
    late TestMockAudioService mockService;
    late AudioState audioState;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      mockService = TestMockAudioService();
      audioState = AudioState(audioService: mockService, prefs: prefs);
    });

    tearDown(() async {
      audioState.dispose();
      await mockService.dispose();
    });

    test('1. Audio Service Foundation: play, pause, resume, stop, seek, and playback rate', () async {
      final mantra = AuthenticMantrasData.allMantras.firstWhere((m) => m.isBundled);
      expect(audioState.playerState, equals(PlayerState.stopped));
      expect(audioState.isLoading, isFalse);

      await audioState.playMantra(mantra);
      expect(mockService.playCount, equals(1));
      expect(audioState.activeMantra?.id, equals(mantra.id));
      expect(audioState.playerState, equals(PlayerState.playing));

      await audioState.pause();
      expect(mockService.pauseCount, equals(1));
      expect(audioState.playerState, equals(PlayerState.paused));

      await audioState.resume();
      expect(mockService.resumeCount, equals(1));
      expect(audioState.playerState, equals(PlayerState.playing));

      await audioState.seek(const Duration(seconds: 4));
      expect(mockService.seekCount, equals(1));

      await audioState.setPlaybackSpeed(1.25);
      expect(mockService.rate, equals(1.25));

      await audioState.stop();
      expect(mockService.stopCount, equals(1));
      expect(audioState.playerState, equals(PlayerState.stopped));
    });

    test('2. Repetition Counting Integrity: genuine completion increments count exactly once', () async {
      final mantra = AuthenticMantrasData.allMantras.firstWhere((m) => m.isBundled);
      audioState.setTargetRepetitions(108);
      await audioState.playMantra(mantra);
      expect(audioState.completedRepetitions, equals(0));

      // Emit completed state from player
      mockService.emitState(PlayerState.completed);
      // Give async microtasks time to execute
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(audioState.completedRepetitions, equals(1));
    });

    test('3. Repetition Counting Protection: pause, seek, and stop NEVER increment count', () async {
      final mantra = AuthenticMantrasData.allMantras.firstWhere((m) => m.isBundled);
      audioState.setTargetRepetitions(108);
      await audioState.playMantra(mantra);
      expect(audioState.completedRepetitions, equals(0));

      // User pauses playback
      await audioState.pause();
      expect(audioState.completedRepetitions, equals(0),
          reason: 'Pause must never increment repetition count');

      // User seeks during playback
      await audioState.seek(const Duration(seconds: 3));
      expect(audioState.completedRepetitions, equals(0),
          reason: 'Seek must never increment repetition count');

      // User stops playback
      await audioState.stop();
      expect(audioState.completedRepetitions, equals(0),
          reason: 'Stop must never increment repetition count');
    });

    test('4. Debounce Guard: rapid duplicate completion events do not double-increment', () async {
      final mantra = AuthenticMantrasData.allMantras.firstWhere((m) => m.isBundled);
      audioState.setTargetRepetitions(108);
      await audioState.playMantra(mantra);
      expect(audioState.completedRepetitions, equals(0));

      // Emit two completion events rapidly within debounce window (<100ms)
      mockService.emitState(PlayerState.completed);
      mockService.emitState(PlayerState.completed);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(audioState.completedRepetitions, equals(1),
          reason: 'Duplicate completion events must be debounced');
    });

    test('5. Manual Counting Independence: manual count operates independently from audio playback', () async {
      expect(audioState.completedRepetitions, equals(0));

      audioState.incrementManualRepetition();
      audioState.incrementManualRepetition();
      expect(audioState.completedRepetitions, equals(2));

      // Audio stopped state does not reset manual repetitions
      await audioState.stop();
      expect(audioState.completedRepetitions, equals(2));
    });

    test('6. Japa Session Identity Preservation: session identity maintains integrity', () async {
      final session = JapaPracticeSession(
        id: 'session-21f-108',
        mantraId: 'om-namah-shivaya',
        mantraTitle: 'Om Namah Shivaya',
        targetRepetitions: 108,
        completedRepetitions: 54,
        startTime: DateTime.now().subtract(const Duration(minutes: 10)),
        lastUpdatedTime: DateTime.now(),
        status: JapaSessionStatus.active,
        countingMode: JapaCountingMode.audio,
      );

      expect(session.isCompleted, isFalse);
      expect(session.progressFraction, closeTo(0.5, 0.01));
      expect(session.id, equals('session-21f-108'));

      final completedSession = session.copyWith(
        completedRepetitions: 108,
        status: JapaSessionStatus.completed,
      );
      expect(completedSession.isCompleted, isTrue);
      expect(completedSession.id, equals(session.id),
          reason: 'Session ID must remain immutable across updates');
    });

    test('7. Repetition Representation Integrity: mantra item declares 1 chant per repetition', () {
      for (final mantra in AuthenticMantrasData.allMantras) {
        expect(mantra.repetitionCount, equals(1));
        expect(mantra.repetitionRepresentationLabel, equals('1 Chant'));
      }
    });

    test('8. Scripture Audio Availability Honest Representation: 0 approved translations invariant', () {
      for (final scripture in kAuthenticScriptures) {
        for (final verse in scripture.verses) {
          // Zero approved translations invariant strictly verified
          expect(verse.isApproved, isFalse);
          expect(verse.translationStatus, isNot('APPROVED'));
        }
      }
    });

    test('9. Audio Vault Catalog Breakdown: exactly 31 bundled audio tracks and 424 archive entries', () {
      final bundled = AuthenticMantrasData.allMantras.where((m) => m.isBundled).toList();
      final vault = AuthenticMantrasData.allMantras.where((m) => !m.isBundled).toList();

      expect(bundled.length, equals(31),
          reason: 'Bundle contains exactly 31 ear-verified lightweight MP3 audio recordings');
      expect(vault.length, equals(424),
          reason: 'Vault archive contains remaining mantras from 455 canonical collection');
      expect(bundled.length + vault.length, equals(455));
    });
  });
}

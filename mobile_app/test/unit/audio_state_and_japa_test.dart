import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vedam_app/core/models/mantra_item.dart';
import 'package:vedam_app/core/services/audio_service.dart';
import 'package:vedam_app/state/audio_state.dart';

class MockAudioPlaybackService implements AudioPlaybackService {
  final _stateController = StreamController<PlayerState>.broadcast();
  final _posController = StreamController<Duration>.broadcast();
  final _durController = StreamController<Duration>.broadcast();

  PlayerState _currentState = PlayerState.stopped;
  Duration _currentPos = Duration.zero;
  Duration _totalDur = const Duration(seconds: 5);
  MantraItem? _active;

  int playCallCount = 0;
  int pauseCallCount = 0;
  int resumeCallCount = 0;
  int stopCallCount = 0;
  bool shouldThrowOnPlay = false;

  @override
  Stream<PlayerState> get playerStateStream => _stateController.stream;

  @override
  Stream<Duration> get positionStream => _posController.stream;

  @override
  Stream<Duration> get durationStream => _durController.stream;

  @override
  PlayerState get playerState => _currentState;

  @override
  Duration get currentPosition => _currentPos;

  @override
  Duration get totalDuration => _totalDur;

  @override
  MantraItem? get activeMantra => _active;

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

  @override
  Future<void> playMantra(MantraItem item) async {
    playCallCount++;
    if (shouldThrowOnPlay) {
      emitState(PlayerState.stopped);
      throw Exception('Simulated audio failure');
    }
    _active = item;
    emitState(PlayerState.playing);
  }

  @override
  Future<void> pause() async {
    pauseCallCount++;
    emitState(PlayerState.paused);
  }

  @override
  Future<void> resume() async {
    resumeCallCount++;
    emitState(PlayerState.playing);
  }

  @override
  Future<void> stop() async {
    stopCallCount++;
    _currentPos = Duration.zero;
    emitState(PlayerState.stopped);
  }

  @override
  Future<void> seek(Duration position) async {
    _currentPos = position;
    _posController.add(position);
  }

  @override
  Future<void> dispose() async {
    await _stateController.close();
    await _posController.close();
    await _durController.close();
  }
}

void main() {
  group('AudioState & Japa Mala Repetition Engine Tests', () {
    late MockAudioPlaybackService mockAudio;
    late AudioState audioState;
    late MantraItem sampleMantra;

    setUp(() {
      mockAudio = MockAudioPlaybackService();
      audioState = AudioState(audioService: mockAudio);
      sampleMantra = const MantraItem(
        id: 'TEST-MTR-001',
        collection: 'Shiva',
        deity: 'Shiva',
        title: 'Om Namah Shivaya',
        filename: 'Om Namah Shivaya.wav',
        mantraText: 'Om Namah Shivaya',
        significance: 'Purifies the mind and leads to inner stillness.',
        form: '',
        durationSeconds: 4.5,
        sampleRate: 48000,
        bitDepth: 16,
        channels: 2,
        fileSizeBytes: 877484,
        sha256: 'abc1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef',
        sourceTxt: 'Assorted Shiva Chants.txt',
        isBundled: true,
        bundledAssetPath: 'assets/audio/bundled/om_namah_shivaya.mp3',
      );
    });

    tearDown(() {
      audioState.dispose();
    });

    test('Initial state defaults to 108 target repetitions and 0 completed', () {
      expect(audioState.targetRepetitions, equals(108));
      expect(audioState.completedRepetitions, equals(0));
      expect(audioState.isSessionCompleted, isFalse);
      expect(audioState.remainingRepetitions, equals(108));
      expect(audioState.progressFraction, equals(0.0));
      expect(audioState.playerState, equals(PlayerState.stopped));
    });

    test('Repeat count selection updates target accurately', () {
      audioState.setTargetRepetitions(1);
      expect(audioState.targetRepetitions, equals(1));

      audioState.setTargetRepetitions(11);
      expect(audioState.targetRepetitions, equals(11));

      audioState.setTargetRepetitions(108);
      expect(audioState.targetRepetitions, equals(108));

      // Custom count
      audioState.setTargetRepetitions(1008);
      expect(audioState.targetRepetitions, equals(1008));
    });

    test('Playback state transitions: play, pause, resume, stop', () async {
      await audioState.playMantra(sampleMantra);
      expect(mockAudio.playCallCount, equals(1));
      expect(audioState.activeMantra?.id, equals('TEST-MTR-001'));
      expect(audioState.isPlaying, isTrue);

      await audioState.pause();
      expect(mockAudio.pauseCallCount, equals(1));
      expect(audioState.isPaused, isTrue);

      await audioState.resume();
      expect(mockAudio.resumeCallCount, equals(1));
      expect(audioState.isPlaying, isTrue);

      await audioState.stop();
      expect(mockAudio.stopCallCount, equals(1));
      expect(audioState.isStopped, isTrue);
    });

    test('Increments count only after complete successful playback repetition', () async {
      audioState.setTargetRepetitions(3);
      await audioState.playMantra(sampleMantra);
      expect(audioState.completedRepetitions, equals(0));

      // Simulate completion 1
      mockAudio.emitState(PlayerState.completed);
      await Future.delayed(const Duration(milliseconds: 50));
      expect(audioState.completedRepetitions, equals(1));
      expect(audioState.remainingRepetitions, equals(2));
      expect(audioState.isSessionCompleted, isFalse);

      // Simulate completion 2
      await Future.delayed(const Duration(milliseconds: 450));
      mockAudio.emitState(PlayerState.completed);
      await Future.delayed(const Duration(milliseconds: 50));
      expect(audioState.completedRepetitions, equals(2));

      // Simulate completion 3 (target reached!)
      await Future.delayed(const Duration(milliseconds: 450));
      mockAudio.emitState(PlayerState.completed);
      await Future.delayed(const Duration(milliseconds: 50));
      expect(audioState.completedRepetitions, equals(3));
      expect(audioState.remainingRepetitions, equals(0));
      expect(audioState.isSessionCompleted, isTrue);
      expect(mockAudio.stopCallCount, greaterThanOrEqualTo(1));
    });

    test('Never increments count on failed playback or playback error', () async {
      mockAudio.shouldThrowOnPlay = true;
      await audioState.playMantra(sampleMantra);

      expect(audioState.completedRepetitions, equals(0));
      expect(audioState.errorMessage, contains('Simulated audio failure'));
      expect(audioState.isSessionCompleted, isFalse);
    });

    test('Prevents double-counting during rapid spurious callbacks', () async {
      audioState.setTargetRepetitions(10);
      await audioState.playMantra(sampleMantra);

      // Rapidly fire multiple completed events within 100ms
      mockAudio.emitState(PlayerState.completed);
      mockAudio.emitState(PlayerState.completed);
      mockAudio.emitState(PlayerState.completed);

      await Future.delayed(const Duration(milliseconds: 50));
      // Guard must ensure count incremented exactly once
      expect(audioState.completedRepetitions, equals(1));
    });

    test('Session reset clears completed repetitions and stops player', () async {
      audioState.setTargetRepetitions(108);
      await audioState.playMantra(sampleMantra);

      mockAudio.emitState(PlayerState.completed);
      await Future.delayed(const Duration(milliseconds: 50));
      expect(audioState.completedRepetitions, equals(1));

      audioState.resetSession();
      expect(audioState.completedRepetitions, equals(0));
      expect(audioState.remainingRepetitions, equals(108));
      expect(mockAudio.stopCallCount, greaterThanOrEqualTo(1));
    });

    test('Favorites toggle adds and removes mantra IDs reactively', () {
      expect(audioState.isFavorite('TEST-MTR-001'), isFalse);

      audioState.toggleFavorite('TEST-MTR-001');
      expect(audioState.isFavorite('TEST-MTR-001'), isTrue);

      audioState.toggleFavorite('TEST-MTR-001');
      expect(audioState.isFavorite('TEST-MTR-001'), isFalse);
    });
  });
}

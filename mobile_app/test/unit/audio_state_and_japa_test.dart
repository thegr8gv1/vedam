import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vedam_app/core/models/japa_target_preset.dart';
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

  double playbackRate = 1.0;

  @override
  Future<void> setPlaybackRate(double rate) async {
    playbackRate = rate;
  }

  @override
  Future<void> dispose() async {
    await _stateController.close();
    await _posController.close();
    await _durController.close();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 16B: Traditional Presets and Custom Count Validation', () {
    test('kJapaTraditionalPresets defines all 7 required counts with authentic labels', () {
      expect(kJapaTraditionalPresets.length, equals(7));

      final counts = kJapaTraditionalPresets.map((p) => p.count).toList();
      expect(counts, equals([11, 21, 27, 54, 108, 111, 1008]));

      final labels = kJapaTraditionalPresets.map((p) => p.traditionalLabel).toList();
      expect(labels, [
        '11 repetitions',
        '21 repetitions',
        '27 repetitions',
        'Half Mala',
        'One Mala',
        '111 repetitions',
        '1008 repetitions',
      ]);

      for (final p in kJapaTraditionalPresets) {
        expect(p.spiritualSignificance.isNotEmpty, isTrue);
      }
    });

    test('validateCustomJapaTarget validates positive whole integers accurately', () {
      final validCounts = ['1', '11', '21', '27', '54', '108', '111', '1008', '5000', '100000'];
      for (final input in validCounts) {
        final res = validateCustomJapaTarget(input);
        expect(res.isValid, isTrue, reason: 'Failed for $input');
        expect(res.count, equals(int.parse(input)));
        expect(res.errorMessage, isNull);
      }
    });

    test('validateCustomJapaTarget rejects zero and negative counts', () {
      final res0 = validateCustomJapaTarget('0');
      expect(res0.isValid, isFalse);
      expect(res0.errorMessage, contains('greater than zero'));

      final resNeg = validateCustomJapaTarget('-10');
      expect(resNeg.isValid, isFalse);
      expect(resNeg.errorMessage, contains('greater than zero'));
    });

    test('validateCustomJapaTarget rejects decimals and formatting symbols', () {
      final resDot = validateCustomJapaTarget('108.5');
      expect(resDot.isValid, isFalse);
      expect(resDot.errorMessage, contains('no decimals'));

      final resComma = validateCustomJapaTarget('1,008');
      expect(resComma.isValid, isFalse);
      expect(resComma.errorMessage, contains('no decimals'));
    });

    test('validateCustomJapaTarget rejects empty, whitespace, and non-numeric inputs', () {
      expect(validateCustomJapaTarget(null).isValid, isFalse);
      expect(validateCustomJapaTarget('').isValid, isFalse);
      expect(validateCustomJapaTarget('   ').isValid, isFalse);
      expect(validateCustomJapaTarget('abc').isValid, isFalse);
      expect(validateCustomJapaTarget('108 beads').isValid, isFalse);
    });

    test('validateCustomJapaTarget rejects counts exceeding practical upper bound (100,000)', () {
      final resSafeMax = validateCustomJapaTarget('100000');
      expect(resSafeMax.isValid, isTrue);
      expect(resSafeMax.count, equals(100000));

      final resTooLarge = validateCustomJapaTarget('100001');
      expect(resTooLarge.isValid, isFalse);
      expect(resTooLarge.errorMessage, contains('100000 repetitions'));

      final resExtreme = validateCustomJapaTarget('99999999999');
      expect(resExtreme.isValid, isFalse);
    });
  });

  group('AudioState & Japa Mala Repetition Engine Tests', () {
    late MockAudioPlaybackService mockAudio;
    late AudioState audioState;
    late MantraItem sampleMantra;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
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
      expect(audioState.autoPauseAtTarget, isTrue);
      expect(audioState.canChangeTargetWithoutConfirmation(), isTrue);
    });

    test('Repeat count selection updates target accurately', () {
      audioState.setTargetRepetitions(1);
      expect(audioState.targetRepetitions, equals(1));

      audioState.setTargetRepetitions(11);
      expect(audioState.targetRepetitions, equals(11));

      audioState.setTargetRepetitions(27);
      expect(audioState.targetRepetitions, equals(27));

      audioState.setTargetRepetitions(54);
      expect(audioState.targetRepetitions, equals(54));

      audioState.setTargetRepetitions(108);
      expect(audioState.targetRepetitions, equals(108));

      // Custom count
      audioState.setTargetRepetitions(1008);
      expect(audioState.targetRepetitions, equals(1008));
    });

    test('setTargetRepetitions ignores invalid counts (<=0 or >100,000)', () {
      audioState.setTargetRepetitions(108);
      audioState.setTargetRepetitions(0);
      expect(audioState.targetRepetitions, equals(108));

      audioState.setTargetRepetitions(-5);
      expect(audioState.targetRepetitions, equals(108));

      audioState.setTargetRepetitions(100001);
      expect(audioState.targetRepetitions, equals(108));
    });

    test('Changing target mid-session strictly preserves completed repetitions', () {
      audioState.setTargetRepetitions(108);
      // Simulate 15 completed repetitions
      for (int i = 0; i < 15; i++) {
        audioState.incrementManualRepetition();
      }
      expect(audioState.completedRepetitions, equals(15));
      expect(audioState.canChangeTargetWithoutConfirmation(), isFalse);

      // Devotee switches target to 54
      audioState.setTargetRepetitions(54);
      expect(audioState.targetRepetitions, equals(54));
      expect(audioState.completedRepetitions, equals(15)); // strictly preserved!
      expect(audioState.remainingRepetitions, equals(39));
      expect(audioState.isSessionCompleted, isFalse);

      // Devotee switches target to 11 (which is lower than completed 15)
      audioState.setTargetRepetitions(11);
      expect(audioState.targetRepetitions, equals(11));
      expect(audioState.completedRepetitions, equals(15)); // strictly preserved!
      expect(audioState.remainingRepetitions, equals(0));
      expect(audioState.isSessionCompleted, isTrue);
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

    test('Increments count only after complete successful playback repetition with auto-pause', () async {
      audioState.setTargetRepetitions(3);
      audioState.setAutoPauseAtTarget(true);
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

    test('Continuous chanting mode (auto-pause disabled) continues after target', () async {
      audioState.setTargetRepetitions(2);
      audioState.setAutoPauseAtTarget(false);
      await audioState.playMantra(sampleMantra);

      // Repetition 1
      mockAudio.emitState(PlayerState.completed);
      await Future.delayed(const Duration(milliseconds: 50));
      expect(audioState.completedRepetitions, equals(1));

      // Repetition 2 (target reached)
      await Future.delayed(const Duration(milliseconds: 450));
      mockAudio.emitState(PlayerState.completed);
      await Future.delayed(const Duration(milliseconds: 50));
      expect(audioState.completedRepetitions, equals(2));
      expect(audioState.isSessionCompleted, isTrue);

      // Repetition 3 (beyond target in continuous mode)
      await Future.delayed(const Duration(milliseconds: 450));
      mockAudio.emitState(PlayerState.completed);
      await Future.delayed(const Duration(milliseconds: 50));
      expect(audioState.completedRepetitions, equals(3));
      expect(audioState.completedRepetitions, greaterThan(audioState.targetRepetitions));
    });

    test('Session completion controls: continueChanting and finishSession', () {
      audioState.setTargetRepetitions(11);
      for (int i = 0; i < 11; i++) {
        audioState.incrementManualRepetition();
      }
      expect(audioState.isSessionCompleted, isTrue);
      expect(audioState.hasReachedTarget, isTrue);

      // Devotee chooses Continue Chanting
      audioState.continueChanting();
      expect(audioState.isContinuingBeyondTarget, isTrue);
      expect(audioState.hasAcknowledgedCompletion, isTrue);

      // Next chants increment seamlessly
      audioState.incrementManualRepetition();
      expect(audioState.completedRepetitions, equals(12));

      // Devotee chooses Finish Session
      audioState.finishSession();
      expect(audioState.completedRepetitions, equals(12)); // count strictly preserved!
      expect(audioState.isStopped, isTrue);
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

    test('SharedPreferences persistence restores target, autoPause, and completed count', () async {
      SharedPreferences.setMockInitialValues({
        'vedam_japa_target_v1': 54,
        'vedam_japa_auto_pause_v1': false,
        'vedam_japa_completed_v1': 27,
      });

      final freshState = AudioState(audioService: mockAudio);
      await freshState.init();

      expect(freshState.targetRepetitions, equals(54));
      expect(freshState.autoPauseAtTarget, isFalse);
      expect(freshState.completedRepetitions, equals(27));
      expect(freshState.remainingRepetitions, equals(27));

      freshState.dispose();
    });

    test('Playlist navigation: next and previous mantra controls', () async {
      const mantra2 = MantraItem(
        id: 'TEST-MTR-002',
        collection: 'Shiva',
        deity: 'Shiva',
        title: 'Maha Mrityunjaya Mantra',
        filename: 'Maha Mrityunjaya Mantra.wav',
        mantraText: 'Tryambakam Yajamahe',
        significance: 'Grants liberation and supreme vitality.',
        form: '',
        durationSeconds: 6.0,
        sampleRate: 48000,
        bitDepth: 16,
        channels: 2,
        fileSizeBytes: 900000,
        sha256: 'def456',
        sourceTxt: 'Shiva Chants.txt',
        isBundled: true,
        bundledAssetPath: 'assets/audio/bundled/maha_mrityunjaya_mantra.mp3',
      );

      audioState.setPlaylist([sampleMantra, mantra2]);
      await audioState.playMantra(sampleMantra);

      expect(audioState.hasPreviousMantra, isFalse);
      expect(audioState.hasNextMantra, isTrue);

      await audioState.playNextMantra();
      expect(audioState.activeMantra?.id, equals('TEST-MTR-002'));
      expect(audioState.hasPreviousMantra, isTrue);
      expect(audioState.hasNextMantra, isFalse);

      await audioState.playPreviousMantra();
      expect(audioState.activeMantra?.id, equals('TEST-MTR-001'));
    });

    test('Repeat modes: repeatOff stops after 1 repetition; repeatOne loops', () async {
      // Test repeatOff
      audioState.setRepeatMode(DevotionalRepeatMode.repeatOff);
      await audioState.playMantra(sampleMantra);

      mockAudio.emitState(PlayerState.completed);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(audioState.completedRepetitions, equals(1));
      expect(mockAudio.stopCallCount, greaterThanOrEqualTo(1));

      // Test repeatOne
      audioState.setRepeatMode(DevotionalRepeatMode.repeatOne);
      expect(audioState.repeatMode, equals(DevotionalRepeatMode.repeatOne));
      audioState.cycleRepeatMode();
      expect(audioState.repeatMode, equals(DevotionalRepeatMode.repeatOff));
      audioState.cycleRepeatMode();
      expect(audioState.repeatMode, equals(DevotionalRepeatMode.sequential));
    });

    test('Playback speed controls and persistence', () async {
      await audioState.setPlaybackSpeed(1.25);
      expect(audioState.playbackSpeed, equals(1.25));
      expect(mockAudio.playbackRate, equals(1.25));

      await audioState.setPlaybackSpeed(1.5);
      expect(audioState.playbackSpeed, equals(1.5));
    });

    test('Sleep timer behavior: setting, active status, and expiration', () async {
      expect(audioState.isSleepTimerActive, isFalse);

      audioState.setSleepTimer(const Duration(minutes: 15));
      expect(audioState.isSleepTimerActive, isTrue);
      expect(audioState.sleepTimerRemaining?.inMinutes, equals(14)); // rounded/computed

      // Cancel timer
      audioState.cancelSleepTimer();
      expect(audioState.isSleepTimerActive, isFalse);

      // Short timer triggering pause
      await audioState.playMantra(sampleMantra);
      audioState.setSleepTimer(const Duration(milliseconds: 50));
      await Future.delayed(const Duration(milliseconds: 70));
      expect(mockAudio.pauseCallCount, greaterThanOrEqualTo(1));
    });

    test('Counting mode label accurately distinguishes audio vs manual chanting', () async {
      expect(audioState.countingModeLabel, contains('Manual'));

      await audioState.playMantra(sampleMantra);
      expect(audioState.countingModeLabel, contains('Audio-Assisted'));

      await audioState.stop();
      expect(audioState.countingModeLabel, contains('Manual'));
    });
  });
}

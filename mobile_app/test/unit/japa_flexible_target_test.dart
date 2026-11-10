import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vedam_app/core/models/japa_target_preset.dart';
import 'package:vedam_app/core/models/mantra_item.dart';
import 'package:vedam_app/core/services/audio_service.dart';
import 'package:vedam_app/state/audio_state.dart';

class MockAudioServiceForTesting implements AudioPlaybackService {
  final _stateController = StreamController<PlayerState>.broadcast();
  final _posController = StreamController<Duration>.broadcast();
  final _durController = StreamController<Duration>.broadcast();

  PlayerState _currentState = PlayerState.stopped;
  Duration _currentPos = Duration.zero;
  final Duration _totalDur = const Duration(seconds: 4);
  MantraItem? _active;

  int playCallCount = 0;
  int pauseCallCount = 0;
  int stopCallCount = 0;

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

  @override
  bool get isLoading => false;

  @override
  Stream<bool> get loadingStream => const Stream.empty();

  void emitState(PlayerState state) {
    _currentState = state;
    _stateController.add(state);
  }

  @override
  Future<void> playMantra(MantraItem item) async {
    playCallCount++;
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
  Future<void> setPlaybackRate(double rate) async {}

  @override
  Future<void> dispose() async {
    await _stateController.close();
    await _posController.close();
    await _durController.close();
  }
}

void main() {
  group('Phase 16B.1: Flexible Japa Target & Session Behavior Tests', () {
    late MockAudioServiceForTesting mockAudio;
    late AudioState audioState;
    const testMantra = MantraItem(
      id: 'MTR-TEST-108',
      collection: 'Shiva',
      deity: 'Shiva',
      title: 'Om Namah Shivaya',
      filename: 'Om Namah Shivaya.wav',
      mantraText: 'ॐ नमः शिवाय',
      significance: 'Sacred Panchakshari mantra.',
      form: '',
      durationSeconds: 4.5,
      sampleRate: 48000,
      bitDepth: 16,
      channels: 2,
      fileSizeBytes: 877484,
      sha256: 'abc123',
      sourceTxt: 'Shiva.txt',
      isBundled: true,
      bundledAssetPath: 'assets/audio/bundled/om_namah_shivaya.mp3',
    );

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      mockAudio = MockAudioServiceForTesting();
      audioState = AudioState(audioService: mockAudio);
    });

    tearDown(() {
      audioState.dispose();
      mockAudio.dispose();
    });

    test('1. All seven traditional preset options are defined with authentic counts and labels', () {
      expect(kJapaTraditionalPresets.length, equals(7));
      final counts = kJapaTraditionalPresets.map((p) => p.count).toList();
      expect(counts, equals([11, 21, 27, 54, 108, 111, 1008]));

      expect(kJapaTraditionalPresets[0].traditionalLabel, equals('11 repetitions'));
      expect(kJapaTraditionalPresets[1].traditionalLabel, equals('21 repetitions'));
      expect(kJapaTraditionalPresets[2].traditionalLabel, equals('27 repetitions'));
      expect(kJapaTraditionalPresets[3].traditionalLabel, equals('Half Mala'));
      expect(kJapaTraditionalPresets[4].traditionalLabel, equals('One Mala'));
      expect(kJapaTraditionalPresets[5].traditionalLabel, equals('111 repetitions'));
      expect(kJapaTraditionalPresets[6].traditionalLabel, equals('1008 repetitions'));
    });

    test('2. Selecting 11, 21, 27, 54, 108, 111, and 1008 sets the correct target repetitions', () {
      for (final preset in kJapaTraditionalPresets) {
        audioState.setTargetRepetitions(preset.count);
        expect(audioState.targetRepetitions, equals(preset.count));
      }
    });

    test('3. Custom values 1, 35, 500, and 100000 are validated and accepted', () {
      for (final val in ['1', '35', '500', '100000']) {
        final res = validateCustomJapaTarget(val);
        expect(res.isValid, isTrue);
        expect(res.parsedValue, equals(int.parse(val)));

        audioState.setTargetRepetitions(res.parsedValue!);
        expect(audioState.targetRepetitions, equals(int.parse(val)));
      }
    });

    test('4. Invalid custom values (empty, 0, negative, decimals, non-numeric, >100000) are rejected with clear messages', () {
      // Empty & whitespace
      final emptyRes = validateCustomJapaTarget('');
      expect(emptyRes.isValid, isFalse);
      expect(emptyRes.errorMessage, contains('Please enter a target count'));

      final spaceRes = validateCustomJapaTarget('   ');
      expect(spaceRes.isValid, isFalse);
      expect(spaceRes.errorMessage, contains('Please enter a target count'));

      // Zero and negative
      final zeroRes = validateCustomJapaTarget('0');
      expect(zeroRes.isValid, isFalse);
      expect(zeroRes.errorMessage, contains('greater than zero'));

      final negRes = validateCustomJapaTarget('-15');
      expect(negRes.isValid, isFalse);
      expect(negRes.errorMessage, isNotNull);

      // Decimals
      final decRes = validateCustomJapaTarget('108.5');
      expect(decRes.isValid, isFalse);
      expect(decRes.errorMessage, contains('no decimals'));

      // Non-numeric
      final textRes = validateCustomJapaTarget('om_namah');
      expect(textRes.isValid, isFalse);
      expect(textRes.errorMessage, contains('digits only'));

      // Exceeding practical ceiling (100,000)
      final largeRes = validateCustomJapaTarget('100001');
      expect(largeRes.isValid, isFalse);
      expect(largeRes.errorMessage, contains('100000 repetitions'));
    });

    test('5. Progress and remaining counts are correct for small and large targets', () {
      // Small target: 11
      audioState.setTargetRepetitions(11);
      expect(audioState.targetRepetitions, equals(11));
      expect(audioState.completedRepetitions, equals(0));
      expect(audioState.progressFraction, equals(0.0));

      audioState.incrementManualRepetition();
      audioState.incrementManualRepetition();
      expect(audioState.completedRepetitions, equals(2));
      expect(audioState.targetRepetitions - audioState.completedRepetitions, equals(9));
      expect(audioState.progressFraction, closeTo(2 / 11, 0.001));

      // Large target: 1008
      audioState.setTargetRepetitions(1008);
      expect(audioState.targetRepetitions, equals(1008));
      expect(audioState.completedRepetitions, equals(2)); // preserved!
      expect(audioState.targetRepetitions - audioState.completedRepetitions, equals(1006));
      expect(audioState.progressFraction, closeTo(2 / 1008, 0.001));
    });

    test('6. Completion occurs exactly at the selected target', () {
      audioState.setTargetRepetitions(11);
      expect(audioState.hasReachedTarget, isFalse);

      for (int i = 0; i < 10; i++) {
        audioState.incrementManualRepetition();
        expect(audioState.hasReachedTarget, isFalse);
      }

      // 11th chant
      audioState.incrementManualRepetition();
      expect(audioState.completedRepetitions, equals(11));
      expect(audioState.hasReachedTarget, isTrue);
    });

    test('7. Completion does NOT reset the counter automatically', () {
      audioState.setTargetRepetitions(11);
      for (int i = 0; i < 11; i++) {
        audioState.incrementManualRepetition();
      }
      expect(audioState.completedRepetitions, equals(11));
      expect(audioState.hasReachedTarget, isTrue);

      // Trigger finish or acknowledge: counter remains strictly 11
      audioState.acknowledgeCompletionAlert();
      expect(audioState.completedRepetitions, equals(11));
    });

    test('8. Continuing after completion preserves the completed count and increments further', () {
      audioState.setTargetRepetitions(21);
      for (int i = 0; i < 21; i++) {
        audioState.incrementManualRepetition();
      }
      expect(audioState.completedRepetitions, equals(21));
      expect(audioState.hasReachedTarget, isTrue);

      // Devotee chooses to continue chanting
      audioState.continueChanting();
      expect(audioState.isContinuingBeyondTarget, isTrue);

      // Devotee chants 3 more beads
      audioState.incrementManualRepetition();
      audioState.incrementManualRepetition();
      audioState.incrementManualRepetition();

      expect(audioState.completedRepetitions, equals(24));
      expect(audioState.targetRepetitions, equals(21));
    });

    test('9. Changing a target before a session starts works without requiring confirmation', () {
      expect(audioState.canChangeTargetWithoutConfirmation(), isTrue);
      audioState.setTargetRepetitions(54);
      expect(audioState.targetRepetitions, equals(54));

      audioState.setTargetRepetitions(108);
      expect(audioState.targetRepetitions, equals(108));
    });

    test('10. Changing a target during an active session flags confirmation needed and preserves completed repetitions', () {
      audioState.setTargetRepetitions(108);
      audioState.incrementManualRepetition();
      audioState.incrementManualRepetition();
      audioState.incrementManualRepetition();
      expect(audioState.completedRepetitions, equals(3));

      // Active session check: canChangeTargetWithoutConfirmation must be false
      expect(audioState.canChangeTargetWithoutConfirmation(), isFalse);

      // Changing target to 54
      audioState.setTargetRepetitions(54);
      expect(audioState.targetRepetitions, equals(54));
      // Completed repetitions strictly preserved at 3!
      expect(audioState.completedRepetitions, equals(3));
    });

    test('11. Manual and audio-assisted counting use the same shared target and completed count', () async {
      audioState.setTargetRepetitions(27);
      audioState.setAutoPauseAtTarget(false); // continuous for test

      // 1 manual chant
      audioState.incrementManualRepetition();
      expect(audioState.completedRepetitions, equals(1));

      // 1 audio repetition
      await audioState.playMantra(testMantra, resetSessionCount: false);
      mockAudio.emitState(PlayerState.completed);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(audioState.completedRepetitions, equals(2));
      expect(audioState.targetRepetitions, equals(27));

      // Another manual chant
      audioState.incrementManualRepetition();
      expect(audioState.completedRepetitions, equals(3));
    });

    test('12. Audio completion callbacks cannot double-count (anti-double-counting barrier)', () async {
      audioState.setTargetRepetitions(54);
      await audioState.playMantra(testMantra);
      expect(audioState.completedRepetitions, equals(0));

      // First completion callback
      mockAudio.emitState(PlayerState.completed);
      await Future.delayed(const Duration(milliseconds: 10));

      // Rapid spurious callback within 50ms
      mockAudio.emitState(PlayerState.completed);
      await Future.delayed(const Duration(milliseconds: 50));

      // Only exactly 1 repetition counted!
      expect(audioState.completedRepetitions, equals(1));
    });

    test('13. Saved target preference restores correctly from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        'vedam_japa_target_v1': 1008,
        'vedam_japa_auto_pause_v1': true,
        'vedam_japa_completed_v1': 42,
      });

      final restoredState = AudioState(audioService: mockAudio);
      await Future.delayed(const Duration(milliseconds: 60));

      expect(restoredState.targetRepetitions, equals(1008));
      expect(restoredState.autoPauseAtTarget, isTrue);
      expect(restoredState.completedRepetitions, equals(42));

      restoredState.dispose();
    });
  });
}

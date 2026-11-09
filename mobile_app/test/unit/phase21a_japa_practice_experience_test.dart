import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vedam_app/core/models/japa_practice_session.dart';
import 'package:vedam_app/core/models/mantra_item.dart';
import 'package:vedam_app/core/services/japa_session_service.dart';
import 'package:vedam_app/state/audio_state.dart';

import 'audio_state_and_japa_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 21A: Japa Practice Session Model & Serialization Tests', () {
    test('1. JapaPracticeSession serializes and deserializes cleanly', () {
      final now = DateTime.now();
      final session = JapaPracticeSession(
        id: 'test_session_108',
        mantraId: 'VEDA-MTR-0399',
        mantraTitle: 'Gayatri Mantra',
        deity: 'Surya',
        targetRepetitions: 108,
        completedRepetitions: 54,
        countingMode: JapaCountingMode.manual,
        startTime: now,
        lastUpdatedTime: now.add(const Duration(minutes: 5)),
        status: JapaSessionStatus.active,
      );

      final json = session.toJson();
      final restored = JapaPracticeSession.fromJson(json);

      expect(restored.id, equals('test_session_108'));
      expect(restored.mantraId, equals('VEDA-MTR-0399'));
      expect(restored.mantraTitle, equals('Gayatri Mantra'));
      expect(restored.deity, equals('Surya'));
      expect(restored.targetRepetitions, equals(108));
      expect(restored.completedRepetitions, equals(54));
      expect(restored.countingMode, equals(JapaCountingMode.manual));
      expect(restored.status, equals(JapaSessionStatus.active));
      expect(restored.remainingRepetitions, equals(54));
      expect(restored.progressFraction, equals(0.5));
      expect(restored.isCompleted, isFalse);
    });

    test('2. Corrupted JSON safely recovers with robust fallback defaults', () {
      final corrupted = <String, dynamic>{
        'id': null,
        'mantraId': null,
        'targetRepetitions': -5,
        'completedRepetitions': -10,
        'countingMode': 'unknown_mode',
        'status': 'invalid_status',
        'startTime': 'not_a_date',
      };

      final session = JapaPracticeSession.fromJson(corrupted);
      expect(session.targetRepetitions, equals(108));
      expect(session.completedRepetitions, equals(0));
      expect(session.countingMode, equals(JapaCountingMode.manual));
      expect(session.status, equals(JapaSessionStatus.active));
      expect(session.id, isNotEmpty);
    });
  });

  group('Phase 21A: JapaSessionService Persistence & Recovery Tests', () {
    late SharedPreferences prefs;
    late JapaSessionService sessionService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      sessionService = JapaSessionService(prefs: prefs);
    });

    test('3. Save, recover active session, and ensure no count increment on recovery', () async {
      final session = JapaPracticeSession(
        id: 'session_rec_1',
        mantraId: 'VEDA-MTR-0001',
        mantraTitle: 'Om Namah Shivaya',
        deity: 'Shiva',
        targetRepetitions: 108,
        completedRepetitions: 27,
        countingMode: JapaCountingMode.manual,
        startTime: DateTime.now(),
        lastUpdatedTime: DateTime.now(),
        status: JapaSessionStatus.active,
      );

      await sessionService.saveActiveSession(session);

      // Restore active session
      final restored = await sessionService.loadActiveSession();
      expect(restored, isNotNull);
      expect(restored!.completedRepetitions, equals(27));
      expect(restored.targetRepetitions, equals(108));
      expect(restored.id, equals('session_rec_1'));

      // Ensure reading again NEVER increments the count
      final secondRead = await sessionService.loadActiveSession();
      expect(secondRead!.completedRepetitions, equals(27));
    });

    test('4. Corrupted active session is safely handled without throwing', () async {
      await prefs.setString(JapaSessionService.keyActiveSession, '{bad json syntax: 123');
      final result = await sessionService.loadActiveSession();
      expect(result, isNull);
    });

    test('5. Abandoning active session archives legitimate progress to history and clears active', () async {
      final active = JapaPracticeSession(
        id: 'session_abandon_1',
        mantraId: 'VEDA-MTR-0001',
        mantraTitle: 'Om Namah Shivaya',
        targetRepetitions: 108,
        completedRepetitions: 42,
        countingMode: JapaCountingMode.mixed,
        startTime: DateTime.now(),
        lastUpdatedTime: DateTime.now(),
        status: JapaSessionStatus.active,
      );

      await sessionService.saveActiveSession(active);
      await sessionService.abandonActiveSession();

      // Active slot cleared
      expect(await sessionService.loadActiveSession(), isNull);

      // Preserved in history as abandoned
      final history = await sessionService.loadSessionHistory();
      expect(history.length, equals(1));
      expect(history.first.id, equals('session_abandon_1'));
      expect(history.first.completedRepetitions, equals(42));
      expect(history.first.status, equals(JapaSessionStatus.abandoned));
    });

    test('6. Completed session is recorded in history and does not create duplicate entries', () async {
      final completedSession = JapaPracticeSession(
        id: 'session_completed_1',
        mantraId: 'VEDA-MTR-0413',
        mantraTitle: 'Maha Mrityunjaya Mantra',
        deity: 'Shiva',
        targetRepetitions: 108,
        completedRepetitions: 108,
        countingMode: JapaCountingMode.audio,
        startTime: DateTime.now().subtract(const Duration(minutes: 20)),
        lastUpdatedTime: DateTime.now(),
        status: JapaSessionStatus.completed,
      );

      await sessionService.recordCompletedSession(completedSession);

      // Recording same session ID again updates instead of duplicating
      await sessionService.recordCompletedSession(completedSession);

      final history = await sessionService.loadSessionHistory();
      expect(history.length, equals(1));
      expect(history.first.isCompleted, isTrue);
    });
  });

  group('Phase 21A: AudioState Japa Practice Integration Tests', () {
    late MockAudioPlaybackService mockAudio;
    late AudioState audioState;
    late JapaSessionService sessionService;
    const testMantra = MantraItem(
      id: 'VEDA-MTR-0399',
      collection: 'Surya',
      deity: 'Surya',
      title: 'Gayatri Mantra',
      filename: 'Gayatri Mantra.wav',
      mantraText: 'Om Bhur Bhuvah Svah...',
      significance: 'Vedic prayer for spiritual illumination',
      form: 'Vedic Suktam',
      durationSeconds: 18.95,
      sampleRate: 48000,
      bitDepth: 16,
      channels: 2,
      fileSizeBytes: 3638476,
      sha256: 'a1b2c3d4',
      sourceTxt: 'Rigveda',
      isBundled: true,
      bundledAssetPath: 'assets/audio/bundled/gayatri_mantra.mp3',
    );

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      sessionService = JapaSessionService(prefs: prefs);
      mockAudio = MockAudioPlaybackService();
      audioState = AudioState(
        audioService: mockAudio,
        prefs: prefs,
        japaSessionService: sessionService,
      );
    });

    tearDown(() {
      audioState.dispose();
    });

    test('7. Target selection supports all 7 presets (11, 21, 27, 54, 108, 111, 1008)', () {
      final expectedPresets = [11, 21, 27, 54, 108, 111, 1008];
      for (final p in expectedPresets) {
        audioState.setTargetRepetitions(p);
        expect(audioState.targetRepetitions, equals(p));
      }
    });

    test('8. Manual tap debounce blocks double counting within threshold', () {
      audioState.setManualTapDebounceMs(250);

      // First tap succeeds
      final firstTap = audioState.incrementManualRepetition();
      expect(firstTap, isTrue);
      expect(audioState.completedRepetitions, equals(1));

      // Immediate second tap within 250ms is debounced
      final secondTap = audioState.incrementManualRepetition();
      expect(secondTap, isFalse);
      expect(audioState.completedRepetitions, equals(1));
    });

    test('9. Audio counting increments strictly on completion, not pause, stop, or seek', () async {
      await audioState.playMantra(testMantra);
      expect(audioState.completedRepetitions, equals(0));

      // Pause does not increment
      await audioState.pause();
      expect(audioState.completedRepetitions, equals(0));

      // Resume does not increment
      await audioState.resume();
      expect(audioState.completedRepetitions, equals(0));

      // Seek does not increment
      await audioState.seek(const Duration(seconds: 5));
      expect(audioState.completedRepetitions, equals(0));

      // Stop does not increment
      await audioState.stop();
      expect(audioState.completedRepetitions, equals(0));

      // Genuine completion increments by exactly 1
      mockAudio.emitState(PlayerState.completed);
      await Future.delayed(const Duration(milliseconds: 50));
      expect(audioState.completedRepetitions, equals(1));
    });

    test('10. setActiveMantraWithoutPlaying sets mantra without triggering audio playback', () {
      audioState.setActiveMantraWithoutPlaying(testMantra);
      expect(audioState.activeMantra?.id, equals(testMantra.id));
      expect(audioState.isPlaying, isFalse);
      expect(mockAudio.playCallCount, equals(0));
    });

    test('11. finishSession records completed session to history and clears active session', () async {
      audioState.setActiveMantraWithoutPlaying(testMantra);
      audioState.setTargetRepetitions(11);

      for (int i = 0; i < 11; i++) {
        audioState.incrementManualRepetition();
      }
      expect(audioState.completedRepetitions, equals(11));
      expect(audioState.hasReachedTarget, isTrue);

      audioState.finishSession();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(audioState.activeSession, isNull);
      final history = await sessionService.loadSessionHistory();
      expect(history.length, equals(1));
      expect(history.first.completedRepetitions, equals(11));
      expect(history.first.status, equals(JapaSessionStatus.completed));
    });

    test('12. Pause and resume session toggles session status and persists cleanly', () async {
      audioState.setActiveMantraWithoutPlaying(testMantra);
      audioState.incrementManualRepetition();

      audioState.pauseSession();
      expect(audioState.activeSession?.status, equals(JapaSessionStatus.paused));

      audioState.resumeSession();
      expect(audioState.activeSession?.status, equals(JapaSessionStatus.active));
    });
  });
}

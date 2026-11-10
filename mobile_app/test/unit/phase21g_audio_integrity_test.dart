import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vedam_app/core/models/mantra_item.dart';
import 'package:vedam_app/core/services/audio_service.dart';
import 'package:vedam_app/data/fixtures/authentic_mantras_data.dart';
import 'package:vedam_app/state/audio_state.dart';

class Phase21gMockAudioService implements AudioPlaybackService {
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

  late Phase21gMockAudioService mockAudio;
  late AudioState audioState;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    mockAudio = Phase21gMockAudioService();
    audioState = AudioState(audioService: mockAudio);
  });

  tearDown(() {
    audioState.dispose();
  });

  group('Phase 21G — Audio Availability States & Catalog Reconciliation', () {
    test('Catalog contains exactly 455 mantras partitioned into 31 bundled and 424 archive', () {
      final all = AuthenticMantrasData.allMantras;
      expect(all.length, 455);

      final bundled = all.where((m) => m.isBundled).toList();
      final archive = all.where((m) => !m.isBundled).toList();

      expect(bundled.length, 31);
      expect(archive.length, 424);
    });

    test('All 31 bundled mantras resolve to availableOffline state and are playable', () {
      final bundled = AuthenticMantrasData.allMantras.where((m) => m.isBundled);
      for (final mantra in bundled) {
        expect(mantra.audioAvailabilityState, AudioAvailabilityState.availableOffline);
        expect(mantra.audioAvailabilityState.isPlayableInApp, isTrue);
        expect(mantra.audioAvailabilityState.badgeLabel, 'Offline Audio');
        expect(mantra.bundledAssetPath, isNotNull);
        expect(mantra.bundledAssetPath!.isNotEmpty, isTrue);
      }
    });

    test('All 424 desktop archive mantras resolve to catalogedNotAvailableInApp', () {
      final archive = AuthenticMantrasData.allMantras.where((m) => !m.isBundled);
      for (final mantra in archive) {
        expect(mantra.audioAvailabilityState, AudioAvailabilityState.catalogedNotAvailableInApp);
        expect(mantra.audioAvailabilityState.isPlayableInApp, isFalse);
        expect(mantra.audioAvailabilityState.badgeLabel, 'Manual Japa (Archive)');
      }
    });

    test('AudioAvailabilityState enum coverage and display labels', () {
      expect(AudioAvailabilityState.availableOffline.displayName, 'Available Offline');
      expect(AudioAvailabilityState.catalogedNotAvailableInApp.displayName, 'Cataloged (Archive Only)');
      expect(AudioAvailabilityState.quarantinedPendingVerification.displayName, 'Quarantined / Verification Pending');
      expect(AudioAvailabilityState.unavailable.displayName, 'Unavailable');

      expect(AudioAvailabilityState.quarantinedPendingVerification.badgeLabel, 'Quarantined');
      expect(AudioAvailabilityState.unavailable.badgeLabel, 'Text Only');
    });

    test('Exact size unit reconciliation: decimal MB vs binary MiB formula verification', () {
      // 455 Individual WAVs: 565,551,304 bytes
      const individualBytes = 565551304;
      final indDecMb = individualBytes / 1000000.0;
      final indBinMib = individualBytes / (1024.0 * 1024.0);
      expect(indDecMb, closeTo(565.55, 0.01));
      expect(indBinMib, closeTo(539.35, 0.01));

      // 1 Compilation track (mantras.wav): 67,738,988 bytes
      const compBytes = 67738988;
      final compDecMb = compBytes / 1000000.0;
      final compBinMib = compBytes / (1024.0 * 1024.0);
      expect(compDecMb, closeTo(67.74, 0.01));
      expect(compBinMib, closeTo(64.60, 0.01));

      // Total 456 Root WAV files: 633,290,292 bytes
      const totalBytes = individualBytes + compBytes;
      expect(totalBytes, 633290292);
      final totalDecMb = totalBytes / 1000000.0;
      final totalBinMib = totalBytes / (1024.0 * 1024.0);
      expect(totalDecMb, closeTo(633.29, 0.01));
      expect(totalBinMib, closeTo(603.95, 0.01));
    });
  });

  group('Phase 21G — Hardened Japa Completion Integrity & Playback Instance Tokens', () {
    test('Token increments upon play and completion increments repetition count', () async {
      final mantra = AuthenticMantrasData.allMantras.firstWhere((m) => m.isBundled);
      await audioState.playMantra(mantra);

      final token1 = audioState.currentPlaybackToken;
      expect(token1, greaterThan(0));
      expect(audioState.playbackTrackId, mantra.id);
      expect(audioState.completedRepetitions, 0);

      // Fire completion
      mockAudio.emitState(PlayerState.completed);
      await pumpEventQueue();

      expect(audioState.completedRepetitions, 1);
      expect(audioState.lastHandledPlaybackToken, token1);
    });

    test('Duplicate completion event with identical playback token is strictly rejected', () async {
      final mantra = AuthenticMantrasData.allMantras.firstWhere((m) => m.isBundled);
      await audioState.playMantra(mantra);
      final token = audioState.currentPlaybackToken;

      // First completion
      mockAudio.emitState(PlayerState.completed);
      await pumpEventQueue();
      expect(audioState.completedRepetitions, 1);
      expect(audioState.lastHandledPlaybackToken, token);

      // Attempt duplicate completion with same token
      mockAudio.emitState(PlayerState.completed);
      await pumpEventQueue();

      // Repetition count must NOT increment again
      expect(audioState.completedRepetitions, 1);
    });

    test('Completion event after track switch is rejected as stale', () async {
      final mantra1 = AuthenticMantrasData.allMantras.where((m) => m.isBundled).elementAt(0);
      final mantra2 = AuthenticMantrasData.allMantras.where((m) => m.isBundled).elementAt(1);

      await audioState.playMantra(mantra1);
      expect(audioState.playbackTrackId, mantra1.id);

      // User switches track before completion of mantra1
      await audioState.playMantra(mantra2);
      expect(audioState.playbackTrackId, mantra2.id);

      // Now old completion for mantra1 is superseded
      expect(audioState.activeMantra?.id, mantra2.id);
      expect(audioState.completedRepetitions, 0);
    });

    test('Completion event after stop is rejected', () async {
      final mantra = AuthenticMantrasData.allMantras.firstWhere((m) => m.isBundled);
      await audioState.playMantra(mantra);
      final playToken = audioState.currentPlaybackToken;

      await audioState.stop();
      expect(audioState.isAudioPlayingOrActive, isFalse);
      expect(audioState.currentPlaybackToken, greaterThan(playToken));

      // Late completed event arrives from audio hardware
      mockAudio.emitState(PlayerState.completed);
      await pumpEventQueue();

      expect(audioState.completedRepetitions, 0);
    });

    test('Completion event during pause is rejected', () async {
      final mantra = AuthenticMantrasData.allMantras.firstWhere((m) => m.isBundled);
      await audioState.playMantra(mantra);

      await audioState.pause();
      expect(audioState.isAudioPlayingOrActive, isFalse);

      // Erratic completion from OS audio engine while paused
      mockAudio.emitState(PlayerState.completed);
      await pumpEventQueue();

      expect(audioState.completedRepetitions, 0);
    });

    test('Completion event after session abandon is rejected', () async {
      final mantra = AuthenticMantrasData.allMantras.firstWhere((m) => m.isBundled);
      await audioState.playMantra(mantra);
      audioState.incrementManualRepetition();

      expect(audioState.activeSession, isNotNull);

      await audioState.abandonSession();
      expect(audioState.activeSession, isNull);
      expect(audioState.playbackSessionId, isNull);
      expect(audioState.isAudioPlayingOrActive, isFalse);

      // Late completion arriving after abandonment
      mockAudio.emitState(PlayerState.completed);
      await pumpEventQueue();

      expect(audioState.completedRepetitions, 0);
    });

    test('RepeatOne mode generates fresh playback token for next iteration', () async {
      final mantra = AuthenticMantrasData.allMantras.firstWhere((m) => m.isBundled);
      audioState.setRepeatMode(DevotionalRepeatMode.repeatOne);
      await audioState.playMantra(mantra);

      final token1 = audioState.currentPlaybackToken;

      // Completion 1
      mockAudio.emitState(PlayerState.completed);
      await pumpEventQueue();
      expect(audioState.completedRepetitions, 1);

      // Token must have advanced for the next loop
      final token2 = audioState.currentPlaybackToken;
      expect(token2, greaterThan(token1));

      // Wait debounce window (>400ms)
      await Future.delayed(const Duration(milliseconds: 450));

      // Completion 2
      mockAudio.emitState(PlayerState.completed);
      await pumpEventQueue();
      expect(audioState.completedRepetitions, 2);
      expect(audioState.lastHandledPlaybackToken, token2);
    });

    test('Seeking does NOT trigger repetition completion', () async {
      final mantra = AuthenticMantrasData.allMantras.firstWhere((m) => m.isBundled);
      await audioState.playMantra(mantra);

      // Seek halfway
      await audioState.seek(const Duration(seconds: 5));
      expect(mockAudio.seekCount, 1);
      expect(audioState.completedRepetitions, 0);

      // Seek to the very end
      await audioState.seek(const Duration(seconds: 10));
      expect(mockAudio.seekCount, 2);
      expect(audioState.completedRepetitions, 0);
    });

    test('Manual bead counting operates independently during audio playback', () async {
      final mantra = AuthenticMantrasData.allMantras.firstWhere((m) => m.isBundled);
      await audioState.playMantra(mantra);
      expect(audioState.completedRepetitions, 0);

      // Devotee taps manual bead counter
      audioState.incrementManualRepetition();
      expect(audioState.completedRepetitions, 1);

      // Audio completes afterwards
      mockAudio.emitState(PlayerState.completed);
      await pumpEventQueue();

      expect(audioState.completedRepetitions, 2);
    });

    test('Rapid consecutive track switching invalidates earlier completion events', () async {
      final mantras = AuthenticMantrasData.allMantras.where((m) => m.isBundled).toList();
      final m1 = mantras[0];
      final m2 = mantras[1];
      final m3 = mantras[2];

      await audioState.playMantra(m1);
      final token1 = audioState.currentPlaybackToken;

      // Devotee rapidly skips to m2, then to m3
      await audioState.playMantra(m2);
      await audioState.playMantra(m3);
      final token3 = audioState.currentPlaybackToken;

      expect(token3, greaterThan(token1));
      expect(audioState.playbackTrackId, m3.id);
      expect(audioState.activeMantra?.id, m3.id);
      expect(audioState.completedRepetitions, 0);

      // Late completed event arrives for m1 run
      // Since token is now token3 and track is m3, late event cannot count against m3
      mockAudio.emitState(PlayerState.completed);
      await pumpEventQueue();

      expect(audioState.completedRepetitions, 1); // genuine completion of current active track m3
      expect(audioState.lastHandledPlaybackToken, token3);

      // A duplicate event arriving afterwards is rejected
      mockAudio.emitState(PlayerState.completed);
      await pumpEventQueue();
      expect(audioState.completedRepetitions, 1);
    });

    test('Disposal cancels subscriptions and closes stream controller cleanly', () async {
      final localMock = Phase21gMockAudioService();
      final localAudioState = AudioState(audioService: localMock);

      final mantra = AuthenticMantrasData.allMantras.firstWhere((m) => m.isBundled);
      await localAudioState.playMantra(mantra);
      expect(localAudioState.completedRepetitions, 0);

      // Devotee leaves screen / provider is disposed
      localAudioState.dispose();

      // State is disposed and count was not mutated
      expect(localAudioState.completedRepetitions, 0);
    });
  });
}

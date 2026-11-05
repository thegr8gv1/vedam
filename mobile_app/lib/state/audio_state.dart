import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import '../core/models/mantra_item.dart';
import '../core/services/audio_service.dart';

class AudioState extends ChangeNotifier {
  final AudioPlaybackService _audioService;

  MantraItem? _activeMantra;
  PlayerState _playerState = PlayerState.stopped;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  int _targetRepetitions = 108;
  int _completedRepetitions = 0;
  String? _errorMessage;

  final Set<String> _favoriteMantraIds = {};

  // Idempotent double-counting prevention guard
  int _lastCompletionTimestampMs = 0;
  bool _isTransitioningRepetition = false;

  StreamSubscription<PlayerState>? _stateSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration>? _durationSub;

  AudioState({required AudioPlaybackService audioService})
      : _audioService = audioService {
    _initAudioListeners();
  }

  void _initAudioListeners() {
    _stateSub = _audioService.playerStateStream.listen((state) {
      _playerState = state;
      if (state == PlayerState.completed) {
        _handlePlaybackCompleted();
      }
      notifyListeners();
    });

    _positionSub = _audioService.positionStream.listen((pos) {
      _position = pos;
      notifyListeners();
    });

    _durationSub = _audioService.durationStream.listen((dur) {
      _duration = dur;
      notifyListeners();
    });
  }

  // Getters
  MantraItem? get activeMantra => _activeMantra;
  PlayerState get playerState => _playerState;
  bool get isPlaying => _playerState == PlayerState.playing;
  bool get isPaused => _playerState == PlayerState.paused;
  bool get isStopped => _playerState == PlayerState.stopped;

  Duration get position => _position;
  Duration get duration => _duration;

  int get targetRepetitions => _targetRepetitions;
  int get completedRepetitions => _completedRepetitions;
  int get remainingRepetitions =>
      _targetRepetitions > _completedRepetitions ? _targetRepetitions - _completedRepetitions : 0;

  bool get isSessionCompleted => _completedRepetitions >= _targetRepetitions;
  double get progressFraction => _targetRepetitions > 0
      ? (_completedRepetitions / _targetRepetitions).clamp(0.0, 1.0)
      : 0.0;

  String? get errorMessage => _errorMessage;
  Set<String> get favoriteMantraIds => Set.unmodifiable(_favoriteMantraIds);
  bool isFavorite(String mantraId) => _favoriteMantraIds.contains(mantraId);

  // Repeat count setter
  void setTargetRepetitions(int count) {
    if (count <= 0) return;
    _targetRepetitions = count;
    notifyListeners();
  }

  // Manual bead increment (shares state with audio repetitions)
  void incrementManualRepetition() {
    _completedRepetitions++;
    notifyListeners();
  }

  // Play mantra
  Future<void> playMantra(MantraItem mantra, {bool resetSessionCount = true}) async {
    _errorMessage = null;
    _activeMantra = mantra;

    if (resetSessionCount) {
      _completedRepetitions = 0;
    }

    try {
      await _audioService.playMantra(mantra);
    } catch (e) {
      _errorMessage = 'Playback error: $e';
      notifyListeners();
    }
  }

  Future<void> pause() async {
    _errorMessage = null;
    await _audioService.pause();
  }

  Future<void> resume() async {
    _errorMessage = null;
    if (_activeMantra != null) {
      await _audioService.resume();
    }
  }

  Future<void> stop() async {
    await _audioService.stop();
  }

  Future<void> seek(Duration newPosition) async {
    await _audioService.seek(newPosition);
  }

  void resetSession() {
    _completedRepetitions = 0;
    _isTransitioningRepetition = false;
    _errorMessage = null;
    _audioService.stop();
    notifyListeners();
  }

  void toggleFavorite(String mantraId) {
    if (_favoriteMantraIds.contains(mantraId)) {
      _favoriteMantraIds.remove(mantraId);
    } else {
      _favoriteMantraIds.add(mantraId);
    }
    notifyListeners();
  }

  // Repetition and Japa logic with anti-double-counting barrier
  Future<void> _handlePlaybackCompleted() async {
    if (_activeMantra == null) return;
    if (_isTransitioningRepetition) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    // Guard: ignore spurious rapid callbacks within 400ms
    if (now - _lastCompletionTimestampMs < 400) {
      return;
    }

    _isTransitioningRepetition = true;
    _lastCompletionTimestampMs = now;
    _completedRepetitions++;
    notifyListeners();

    if (_completedRepetitions < _targetRepetitions) {
      // Loop to next repetition
      try {
        await _audioService.playMantra(_activeMantra!);
      } catch (e) {
        _errorMessage = 'Auto-repeat error: $e';
      } finally {
        _isTransitioningRepetition = false;
      }
    } else {
      // Target repetition achieved
      _isTransitioningRepetition = false;
      await _audioService.stop();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();
    _audioService.dispose();
    super.dispose();
  }
}

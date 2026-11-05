import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/models/japa_target_preset.dart';
import '../core/models/mantra_item.dart';
import '../core/services/audio_service.dart';

class AudioState extends ChangeNotifier {
  static const String _prefsKeyTargetRepetitions = 'vedam_japa_target_v1';
  static const String _prefsKeyAutoPause = 'vedam_japa_auto_pause_v1';
  static const String _prefsKeyCompletedRepetitions = 'vedam_japa_completed_v1';
  static const String _prefsKeyActiveMantraId = 'vedam_japa_active_mantra_id_v1';

  final AudioPlaybackService _audioService;
  final SharedPreferences? _injectedPrefs;

  MantraItem? _activeMantra;
  PlayerState _playerState = PlayerState.stopped;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  int _targetRepetitions = 108;
  int _completedRepetitions = 0;
  bool _autoPauseAtTarget = true;
  bool _isContinuingBeyondTarget = false;
  bool _hasTriggeredCompletionAlert = false;
  String? _errorMessage;

  final Set<String> _favoriteMantraIds = {};

  // Idempotent double-counting prevention guard
  int _lastCompletionTimestampMs = 0;
  bool _isTransitioningRepetition = false;

  StreamSubscription<PlayerState>? _stateSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration>? _durationSub;

  AudioState({
    required AudioPlaybackService audioService,
    SharedPreferences? prefs,
  })  : _audioService = audioService,
        _injectedPrefs = prefs {
    _initAudioListeners();
    init();
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

  Future<SharedPreferences> _getPrefs() async {
    final prefs = _injectedPrefs;
    if (prefs != null) return prefs;
    return await SharedPreferences.getInstance();
  }

  /// Initialize and restore persisted target and session settings
  Future<void> init() async {
    try {
      final prefs = await _getPrefs();
      final savedTarget = prefs.getInt(_prefsKeyTargetRepetitions);
      if (savedTarget != null && savedTarget > 0 && savedTarget <= kMaxPracticalJapaTarget) {
        _targetRepetitions = savedTarget;
      }

      final savedAutoPause = prefs.getBool(_prefsKeyAutoPause);
      if (savedAutoPause != null) {
        _autoPauseAtTarget = savedAutoPause;
      }

      final savedCompleted = prefs.getInt(_prefsKeyCompletedRepetitions);
      if (savedCompleted != null && savedCompleted >= 0) {
        _completedRepetitions = savedCompleted;
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error restoring AudioState preferences: $e');
    }
  }

  Future<void> _saveTargetPreference() async {
    try {
      final prefs = await _getPrefs();
      await prefs.setInt(_prefsKeyTargetRepetitions, _targetRepetitions);
    } catch (_) {}
  }

  Future<void> _saveAutoPausePreference() async {
    try {
      final prefs = await _getPrefs();
      await prefs.setBool(_prefsKeyAutoPause, _autoPauseAtTarget);
    } catch (_) {}
  }

  Future<void> _saveSessionProgress() async {
    try {
      final prefs = await _getPrefs();
      await prefs.setInt(_prefsKeyCompletedRepetitions, _completedRepetitions);
      if (_activeMantra != null) {
        await prefs.setString(_prefsKeyActiveMantraId, _activeMantra!.id);
      }
    } catch (_) {}
  }

  Future<void> _clearSessionProgress() async {
    try {
      final prefs = await _getPrefs();
      await prefs.remove(_prefsKeyCompletedRepetitions);
      await prefs.remove(_prefsKeyActiveMantraId);
    } catch (_) {}
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
  bool get hasReachedTarget => isSessionCompleted;
  bool get isContinuingBeyondTarget => _isContinuingBeyondTarget;
  bool get hasTriggeredCompletionAlert => _hasTriggeredCompletionAlert;
  bool get hasAcknowledgedCompletion => _hasTriggeredCompletionAlert;
  bool get autoPauseAtTarget => _autoPauseAtTarget;

  double get progressFraction => _targetRepetitions > 0
      ? (_completedRepetitions / _targetRepetitions).clamp(0.0, 1.0)
      : 0.0;

  String? get errorMessage => _errorMessage;
  Set<String> get favoriteMantraIds => Set.unmodifiable(_favoriteMantraIds);
  bool isFavorite(String mantraId) => _favoriteMantraIds.contains(mantraId);

  /// Check whether target can be changed without warning (only if session hasn't started)
  bool canChangeTargetWithoutConfirmation() => _completedRepetitions == 0;

  /// Target count setter with positive validation, practical safety bounds,
  /// and strict preservation of completed repetitions.
  void setTargetRepetitions(int count) {
    if (count <= 0 || count > kMaxPracticalJapaTarget) return;

    _targetRepetitions = count;

    // If new target is higher than completed count, allow completion alert to fire again when reached
    if (_completedRepetitions < _targetRepetitions) {
      _hasTriggeredCompletionAlert = false;
      _isContinuingBeyondTarget = false;
    }

    _saveTargetPreference();
    notifyListeners();
  }

  /// Toggle or update auto-pause at target preference
  void setAutoPauseAtTarget(bool enabled) {
    _autoPauseAtTarget = enabled;
    _saveAutoPausePreference();
    notifyListeners();
  }

  /// Devotee elects to continue chanting beyond original target
  void continueChanting() {
    _isContinuingBeyondTarget = true;
    _hasTriggeredCompletionAlert = true;
    notifyListeners();
  }

  /// Devotee elects to conclude the chanting session
  void finishSession() {
    _hasTriggeredCompletionAlert = true;
    stop();
    notifyListeners();
  }

  /// Manual bead increment (shares state with audio repetitions)
  void incrementManualRepetition() {
    _completedRepetitions++;
    _saveSessionProgress();

    if (_completedRepetitions >= _targetRepetitions && !_isContinuingBeyondTarget) {
      // Reached or passed target
      notifyListeners();
    } else {
      notifyListeners();
    }
  }

  /// Acknowledge completion alert (prevents multiple dialog popups)
  void acknowledgeCompletionAlert() {
    _hasTriggeredCompletionAlert = true;
    notifyListeners();
  }

  // Play mantra
  Future<void> playMantra(MantraItem mantra, {bool resetSessionCount = true}) async {
    _errorMessage = null;
    _activeMantra = mantra;

    if (resetSessionCount) {
      _completedRepetitions = 0;
      _isContinuingBeyondTarget = false;
      _hasTriggeredCompletionAlert = false;
      _clearSessionProgress();
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
    _isContinuingBeyondTarget = false;
    _hasTriggeredCompletionAlert = false;
    _isTransitioningRepetition = false;
    _errorMessage = null;
    _clearSessionProgress();
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
    _saveSessionProgress();
    notifyListeners();

    // Check if target count is achieved
    if (_completedRepetitions >= _targetRepetitions && !_isContinuingBeyondTarget) {
      // Reached target
      _isTransitioningRepetition = false;

      if (_autoPauseAtTarget) {
        // Stop audio playback at target and signal session completion
        await _audioService.stop();
        notifyListeners();
        return;
      }
    }

    // Continue to next repetition
    try {
      await _audioService.playMantra(_activeMantra!);
    } catch (e) {
      _errorMessage = 'Auto-repeat error: $e';
    } finally {
      _isTransitioningRepetition = false;
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

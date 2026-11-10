import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/models/japa_practice_session.dart';
import '../core/models/japa_target_preset.dart';
import '../core/models/mantra_item.dart';
import '../core/services/audio_service.dart';
import '../core/services/japa_session_service.dart';

/// Available devotional repeat modes.
enum DevotionalRepeatMode {
  /// Repeats the single chosen mantra continuously or until Japa target is met (Default for Japa).
  repeatOne,

  /// Plays the current mantra once and stops.
  repeatOff,

  /// Plays sequentially through the current playlist/collection.
  sequential,
}

class AudioState extends ChangeNotifier {
  static const String _prefsKeyTargetRepetitions = 'vedam_japa_target_v1';
  static const String _prefsKeyAutoPause = 'vedam_japa_auto_pause_v1';
  static const String _prefsKeyCompletedRepetitions = 'vedam_japa_completed_v1';
  static const String _prefsKeyActiveMantraId = 'vedam_japa_active_mantra_id_v1';
  static const String _prefsKeyFavorites = 'vedam_audio_favorites_v1';
  static const String _prefsKeyPlaybackSpeed = 'vedam_audio_speed_v1';
  static const String _prefsKeyRepeatMode = 'vedam_audio_repeat_mode_v1';

  final AudioPlaybackService _audioService;
  final SharedPreferences? _injectedPrefs;
  final JapaSessionService _japaSessionService;

  MantraItem? _activeMantra;
  PlayerState _playerState = PlayerState.stopped;
  bool _isLoading = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  // Playlist navigation
  List<MantraItem> _playlist = [];

  // Repeat and Speed
  DevotionalRepeatMode _repeatMode = DevotionalRepeatMode.repeatOne;
  double _playbackSpeed = 1.0;

  // Sleep Timer
  Timer? _sleepTimer;
  DateTime? _sleepTimerTarget;

  int _targetRepetitions = 108;
  int _completedRepetitions = 0;
  bool _autoPauseAtTarget = true;
  bool _isContinuingBeyondTarget = false;
  bool _hasTriggeredCompletionAlert = false;
  String? _errorMessage;

  final Set<String> _favoriteMantraIds = {};

  // Idempotent double-counting prevention guard and playback instance tokens
  int _lastCompletionTimestampMs = 0;
  int _lastManualTapTimestampMs = 0;
  bool _isTransitioningRepetition = false;
  bool _isDisposed = false;

  // Strict Japa completion integrity tokens
  int _currentPlaybackToken = 0;
  int _lastHandledPlaybackToken = -1;
  String? _playbackTrackId;
  String? _playbackSessionId;
  bool _isAudioPlayingOrActive = false;

  int get currentPlaybackToken => _currentPlaybackToken;
  int get lastHandledPlaybackToken => _lastHandledPlaybackToken;
  String? get playbackTrackId => _playbackTrackId;
  String? get playbackSessionId => _playbackSessionId;
  bool get isAudioPlayingOrActive => _isAudioPlayingOrActive;

  @override
  void notifyListeners() {
    if (_isDisposed) return;
    super.notifyListeners();
  }

  // Japa practice session and history
  JapaPracticeSession? _activeSession;
  List<JapaPracticeSession> _sessionHistory = [];

  StreamSubscription<PlayerState>? _stateSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration>? _durationSub;
  StreamSubscription<bool>? _loadingSub;

  AudioState({
    required AudioPlaybackService audioService,
    SharedPreferences? prefs,
    JapaSessionService? japaSessionService,
  })  : _audioService = audioService,
        _injectedPrefs = prefs,
        _japaSessionService =
            japaSessionService ?? JapaSessionService(prefs: prefs) {
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

    _loadingSub = _audioService.loadingStream.listen((loading) {
      _isLoading = loading;
      notifyListeners();
    });
  }

  Future<SharedPreferences> _getPrefs() async {
    final prefs = _injectedPrefs;
    if (prefs != null) return prefs;
    return await SharedPreferences.getInstance();
  }

  /// Initialize and restore persisted target, speed, favorites, and session settings
  Future<void> init() async {
    try {
      final prefs = await _getPrefs();
      final savedTarget = prefs.getInt(_prefsKeyTargetRepetitions);
      if (savedTarget != null &&
          savedTarget > 0 &&
          savedTarget <= kMaxPracticalJapaTarget) {
        _targetRepetitions = savedTarget;
      }

      final savedAutoPause = prefs.getBool(_prefsKeyAutoPause);
      if (savedAutoPause != null) {
        _autoPauseAtTarget = savedAutoPause;
      }

      final savedCompleted = prefs.getInt(_prefsKeyCompletedRepetitions);
      if (_completedRepetitions == 0 && savedCompleted != null && savedCompleted >= 0) {
        _completedRepetitions = savedCompleted;
      }

      final savedSpeed = prefs.getDouble(_prefsKeyPlaybackSpeed);
      if (savedSpeed != null && savedSpeed > 0) {
        _playbackSpeed = savedSpeed;
        await _audioService.setPlaybackRate(_playbackSpeed);
      }

      final savedRepeatModeIndex = prefs.getInt(_prefsKeyRepeatMode);
      if (savedRepeatModeIndex != null &&
          savedRepeatModeIndex >= 0 &&
          savedRepeatModeIndex < DevotionalRepeatMode.values.length) {
        _repeatMode = DevotionalRepeatMode.values[savedRepeatModeIndex];
      }

      final savedFavs = prefs.getStringList(_prefsKeyFavorites);
      if (savedFavs != null) {
        _favoriteMantraIds.clear();
        _favoriteMantraIds.addAll(savedFavs);
      }

      // Restore session history and active session without incrementing counts
      _sessionHistory = await _japaSessionService.loadSessionHistory();
      final recoveredSession = await _japaSessionService.loadActiveSession();
      if (_completedRepetitions == 0 && recoveredSession != null) {
        _activeSession = recoveredSession;
        _completedRepetitions = recoveredSession.completedRepetitions;
        _targetRepetitions = recoveredSession.targetRepetitions;
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

  Future<void> _saveFavorites() async {
    try {
      final prefs = await _getPrefs();
      await prefs.setStringList(_prefsKeyFavorites, _favoriteMantraIds.toList());
    } catch (_) {}
  }

  Future<void> _saveSpeed() async {
    try {
      final prefs = await _getPrefs();
      await prefs.setDouble(_prefsKeyPlaybackSpeed, _playbackSpeed);
    } catch (_) {}
  }

  Future<void> _saveRepeatMode() async {
    try {
      final prefs = await _getPrefs();
      await prefs.setInt(_prefsKeyRepeatMode, _repeatMode.index);
    } catch (_) {}
  }

  // Getters
  MantraItem? get activeMantra => _activeMantra;
  PlayerState get playerState => _playerState;
  bool get isLoading => _isLoading;
  bool get isPlaying => _playerState == PlayerState.playing;
  bool get isPaused => _playerState == PlayerState.paused;
  bool get isStopped => _playerState == PlayerState.stopped;

  Duration get position => _position;
  Duration get duration => _duration;

  int get targetRepetitions => _targetRepetitions;
  int get completedRepetitions => _completedRepetitions;
  int get remainingRepetitions => _targetRepetitions > _completedRepetitions
      ? _targetRepetitions - _completedRepetitions
      : 0;

  bool get isSessionCompleted => _completedRepetitions >= _targetRepetitions;
  bool get hasReachedTarget => isSessionCompleted;
  bool get isContinuingBeyondTarget => _isContinuingBeyondTarget;
  bool get hasTriggeredCompletionAlert => _hasTriggeredCompletionAlert;
  bool get hasAcknowledgedCompletion => _hasTriggeredCompletionAlert;
  bool get autoPauseAtTarget => _autoPauseAtTarget;

  // Session & History Getters
  JapaPracticeSession? get activeSession => _activeSession;
  List<JapaPracticeSession> get sessionHistory =>
      List.unmodifiable(_sessionHistory);
  bool get hasActiveOrPausedSession =>
      _activeSession != null &&
      (_activeSession!.status == JapaSessionStatus.active ||
          _activeSession!.status == JapaSessionStatus.paused);

  // Counting Mode Indicators
  bool get isAudioChantingMode => isPlaying || isPaused;
  String get countingModeLabel =>
      isAudioChantingMode ? 'Audio-Assisted Chanting' : 'Manual Bead Chanting';

  // Playlist Navigation Getters
  List<MantraItem> get playlist => List.unmodifiable(_playlist);
  int get currentPlaylistIndex {
    if (_activeMantra == null || _playlist.isEmpty) return -1;
    return _playlist.indexWhere((m) => m.id == _activeMantra!.id);
  }

  bool get hasPreviousMantra => currentPlaylistIndex > 0;
  bool get hasNextMantra =>
      currentPlaylistIndex >= 0 && currentPlaylistIndex < _playlist.length - 1;

  // Repeat & Speed
  DevotionalRepeatMode get repeatMode => _repeatMode;
  double get playbackSpeed => _playbackSpeed;

  // Sleep Timer Getters
  bool get isSleepTimerActive =>
      _sleepTimerTarget != null && _sleepTimerTarget!.isAfter(DateTime.now());

  Duration? get sleepTimerRemaining {
    if (_sleepTimerTarget == null) return null;
    final diff = _sleepTimerTarget!.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  double get progressFraction => _targetRepetitions > 0
      ? (_completedRepetitions / _targetRepetitions).clamp(0.0, 1.0)
      : 0.0;

  String? get errorMessage => _errorMessage;
  Set<String> get favoriteMantraIds => Set.unmodifiable(_favoriteMantraIds);
  bool isFavorite(String mantraId) => _favoriteMantraIds.contains(mantraId);

  /// Toggle favorite status of a mantra
  void toggleFavoriteMantra(String mantraId) {
    if (_favoriteMantraIds.contains(mantraId)) {
      _favoriteMantraIds.remove(mantraId);
    } else {
      _favoriteMantraIds.add(mantraId);
    }
    _saveFavorites();
    notifyListeners();
  }

  /// Configure active playlist for navigation
  void setPlaylist(List<MantraItem> list) {
    _playlist = List.from(list);
    notifyListeners();
  }

  /// Play the next mantra in the active playlist
  Future<void> playNextMantra() async {
    if (!hasNextMantra) return;
    final nextMantra = _playlist[currentPlaylistIndex + 1];
    await playMantra(nextMantra, resetSessionCount: true);
  }

  /// Play the previous mantra in the active playlist
  Future<void> playPreviousMantra() async {
    if (!hasPreviousMantra) return;
    final prevMantra = _playlist[currentPlaylistIndex - 1];
    await playMantra(prevMantra, resetSessionCount: true);
  }

  /// Update repeat mode
  void setRepeatMode(DevotionalRepeatMode mode) {
    _repeatMode = mode;
    _saveRepeatMode();
    notifyListeners();
  }

  /// Cycle through available repeat modes: repeatOne -> repeatOff -> sequential -> repeatOne
  void cycleRepeatMode() {
    switch (_repeatMode) {
      case DevotionalRepeatMode.repeatOne:
        setRepeatMode(DevotionalRepeatMode.repeatOff);
        break;
      case DevotionalRepeatMode.repeatOff:
        setRepeatMode(DevotionalRepeatMode.sequential);
        break;
      case DevotionalRepeatMode.sequential:
        setRepeatMode(DevotionalRepeatMode.repeatOne);
        break;
    }
  }

  /// Update playback speed (0.75x, 1.0x, 1.25x, 1.5x)
  Future<void> setPlaybackSpeed(double speed) async {
    if (speed <= 0) return;
    _playbackSpeed = speed;
    await _audioService.setPlaybackRate(speed);
    _saveSpeed();
    notifyListeners();
  }

  /// Set sleep timer with duration
  void setSleepTimer(Duration? duration) {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    _sleepTimerTarget = null;

    if (duration != null && duration > Duration.zero) {
      _sleepTimerTarget = DateTime.now().add(duration);
      _sleepTimer = Timer(duration, () {
        pause();
        _sleepTimerTarget = null;
        notifyListeners();
      });
    }

    notifyListeners();
  }

  /// Cancel active sleep timer
  void cancelSleepTimer() {
    setSleepTimer(null);
  }

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

    if (_activeSession != null) {
      _activeSession = _activeSession!.copyWith(
        targetRepetitions: count,
        lastUpdatedTime: DateTime.now(),
      );
      _japaSessionService.saveActiveSession(_activeSession!);
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

  /// Conclude and record the practice session
  void finishSession() {
    _hasTriggeredCompletionAlert = true;
    stop();

    if (_activeSession != null) {
      final finishedSession = _activeSession!.copyWith(
        completedRepetitions: _completedRepetitions,
        targetRepetitions: _targetRepetitions,
        status: JapaSessionStatus.completed,
        lastUpdatedTime: DateTime.now(),
      );
      _japaSessionService.recordCompletedSession(finishedSession).then((_) {
        _japaSessionService.loadSessionHistory().then((history) {
          _sessionHistory = history;
        });
      });
      _activeSession = null;
    }

    notifyListeners();
  }

  /// Deliberately abandon current active session.
  /// If legitimate progress was made (>0), archives as abandoned so effort is preserved.
  Future<void> abandonSession() async {
    _currentPlaybackToken++;
    _isAudioPlayingOrActive = false;
    _playbackSessionId = null;
    await stop();
    await _japaSessionService.abandonActiveSession();
    _activeSession = null;
    _completedRepetitions = 0;
    _isContinuingBeyondTarget = false;
    _hasTriggeredCompletionAlert = false;
    await _clearSessionProgress();
    _sessionHistory = await _japaSessionService.loadSessionHistory();
    notifyListeners();
  }

  /// Pause current practice session (manual or audio).
  void pauseSession() {
    if (isPlaying) {
      pause();
    } else if (_activeSession != null) {
      _activeSession = _activeSession!.copyWith(
        status: JapaSessionStatus.paused,
        lastUpdatedTime: DateTime.now(),
      );
      _japaSessionService.saveActiveSession(_activeSession!);
      notifyListeners();
    }
  }

  /// Resume paused practice session.
  void resumeSession() {
    if (isPaused) {
      resume();
    } else if (_activeSession != null) {
      _activeSession = _activeSession!.copyWith(
        status: JapaSessionStatus.active,
        lastUpdatedTime: DateTime.now(),
      );
      _japaSessionService.saveActiveSession(_activeSession!);
      notifyListeners();
    }
  }

  /// Refresh practice history list from storage.
  Future<void> refreshHistory() async {
    _sessionHistory = await _japaSessionService.loadSessionHistory();
    notifyListeners();
  }

  /// Clear practice history
  Future<void> clearPracticeHistory() async {
    await _japaSessionService.clearHistory();
    _sessionHistory = [];
    notifyListeners();
  }

  int manualTapDebounceMs = 0;

  /// Set manual bead tap debounce window in milliseconds (e.g. 250-300ms).
  void setManualTapDebounceMs(int ms) {
    manualTapDebounceMs = ms;
  }

  /// Helper to create or update active session upon repetition increment.
  void _updateActiveSessionOnIncrement(JapaCountingMode mode) {
    final now = DateTime.now();
    if (_activeSession == null) {
      final mantraId = _activeMantra?.id ?? 'VEDA-MTR-0001';
      final mantraTitle = _activeMantra?.title ?? 'Om Namah Shivaya';
      final deity = _activeMantra?.deity;
      _activeSession = JapaPracticeSession(
        id: 'japa_${now.millisecondsSinceEpoch}',
        mantraId: mantraId,
        mantraTitle: mantraTitle,
        deity: deity,
        targetRepetitions: _targetRepetitions,
        completedRepetitions: _completedRepetitions,
        countingMode: mode,
        startTime: now,
        lastUpdatedTime: now,
        status: JapaSessionStatus.active,
      );
    } else {
      final existingMode = _activeSession!.countingMode;
      final newMode = (existingMode != mode && existingMode != JapaCountingMode.mixed)
          ? JapaCountingMode.mixed
          : existingMode;
      _activeSession = _activeSession!.copyWith(
        completedRepetitions: _completedRepetitions,
        targetRepetitions: _targetRepetitions,
        countingMode: newMode,
        lastUpdatedTime: now,
        status: JapaSessionStatus.active,
      );
    }
    _japaSessionService.saveActiveSession(_activeSession!);
  }

  /// Manual bead increment (shares state with audio repetitions).
  /// [debounceMs]: optional threshold (e.g. 250-300ms) to prevent accidental double-taps in UI.
  /// If null, falls back to [manualTapDebounceMs]. If 0, increments unconditionally.
  bool incrementManualRepetition({int? debounceMs}) {
    final effectiveDebounce = debounceMs ?? manualTapDebounceMs;
    if (effectiveDebounce > 0) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final delta = now - _lastManualTapTimestampMs;
      if (delta < effectiveDebounce) {
        return false;
      }
      _lastManualTapTimestampMs = now;
    } else {
      _lastManualTapTimestampMs = DateTime.now().millisecondsSinceEpoch;
    }
    _completedRepetitions++;
    _saveSessionProgress();
    _updateActiveSessionOnIncrement(JapaCountingMode.manual);

    notifyListeners();
    return true;
  }

  /// Acknowledge completion alert (prevents multiple dialog popups)
  void acknowledgeCompletionAlert() {
    _hasTriggeredCompletionAlert = true;
    notifyListeners();
  }

  /// Sets active mantra without triggering audio playback.
  /// Ideal for opening Japa practice in manual chanting mode without sudden autoplay.
  void setActiveMantraWithoutPlaying(MantraItem mantra) {
    if (_activeMantra?.id == mantra.id) return;
    _activeMantra = mantra;

    // If an existing session belonged to a different mantra and had progress, archive it
    if (_activeSession != null && _activeSession!.mantraId != mantra.id) {
      if (_activeSession!.completedRepetitions > 0) {
        _japaSessionService.recordCompletedSession(
          _activeSession!.copyWith(
            status: JapaSessionStatus.abandoned,
            lastUpdatedTime: DateTime.now(),
          ),
        );
      }
      _activeSession = null;
      _completedRepetitions = 0;
      _isContinuingBeyondTarget = false;
      _hasTriggeredCompletionAlert = false;
      _clearSessionProgress();
    }
    notifyListeners();
  }

  // Play mantra
  Future<void> playMantra(MantraItem mantra,
      {bool resetSessionCount = true}) async {
    _errorMessage = null;
    _activeMantra = mantra;
    _currentPlaybackToken++;
    _playbackTrackId = mantra.id;
    _playbackSessionId = _activeSession?.id;
    _isAudioPlayingOrActive = true;

    if (resetSessionCount) {
      // If previous session had counts, archive before resetting
      if (_activeSession != null && _activeSession!.completedRepetitions > 0) {
        await _japaSessionService.recordCompletedSession(
          _activeSession!.copyWith(
            status: JapaSessionStatus.abandoned,
            lastUpdatedTime: DateTime.now(),
          ),
        );
      }
      _activeSession = null;
      _completedRepetitions = 0;
      _isContinuingBeyondTarget = false;
      _hasTriggeredCompletionAlert = false;
      _clearSessionProgress();
    }

    try {
      await _audioService.playMantra(mantra);
      if (_activeSession != null &&
          _activeSession!.status == JapaSessionStatus.paused) {
        _activeSession = _activeSession!.copyWith(
          status: JapaSessionStatus.active,
          lastUpdatedTime: DateTime.now(),
        );
        await _japaSessionService.saveActiveSession(_activeSession!);
      }
    } catch (e) {
      _errorMessage = 'Playback error: $e';
      notifyListeners();
    }
  }

  Future<void> pause() async {
    _errorMessage = null;
    _isAudioPlayingOrActive = false;
    await _audioService.pause();
    if (_activeSession != null &&
        _activeSession!.status == JapaSessionStatus.active) {
      _activeSession = _activeSession!.copyWith(
        status: JapaSessionStatus.paused,
        lastUpdatedTime: DateTime.now(),
      );
      await _japaSessionService.saveActiveSession(_activeSession!);
    }
    notifyListeners();
  }

  Future<void> resume() async {
    _errorMessage = null;
    _isAudioPlayingOrActive = true;
    if (_activeMantra != null) {
      await _audioService.resume();
    }
    if (_activeSession != null &&
        _activeSession!.status == JapaSessionStatus.paused) {
      _activeSession = _activeSession!.copyWith(
        status: JapaSessionStatus.active,
        lastUpdatedTime: DateTime.now(),
      );
      await _japaSessionService.saveActiveSession(_activeSession!);
    }
    notifyListeners();
  }

  Future<void> stop() async {
    _currentPlaybackToken++;
    _isAudioPlayingOrActive = false;
    _isTransitioningRepetition = false;
    _isLoading = false;
    await _audioService.stop();
    _position = Duration.zero;
    notifyListeners();
  }

  Future<void> seek(Duration newPosition) async {
    _position = newPosition;
    await _audioService.seek(newPosition);
    notifyListeners();
  }

  void resetSession() {
    _currentPlaybackToken++;
    _isAudioPlayingOrActive = false;
    _playbackSessionId = null;
    if (_activeSession != null && _activeSession!.completedRepetitions > 0) {
      final abandoned = _activeSession!.copyWith(
        status: JapaSessionStatus.abandoned,
        lastUpdatedTime: DateTime.now(),
      );
      _japaSessionService.recordCompletedSession(abandoned);
    } else {
      _japaSessionService.clearActiveSession();
    }
    _activeSession = null;
    _completedRepetitions = 0;
    _isContinuingBeyondTarget = false;
    _hasTriggeredCompletionAlert = false;
    _isTransitioningRepetition = false;
    _lastManualTapTimestampMs = 0;
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
    _saveFavorites();
    notifyListeners();
  }

  // Hardened Repetition and Japa logic with multi-condition completion integrity
  Future<void> _handlePlaybackCompleted() async {
    // Condition 1: Must have an active mantra matching playback track identity
    if (_activeMantra == null) return;
    if (_playbackTrackId != null && _activeMantra!.id != _playbackTrackId) {
      return; // Stale completion event from a different track
    }

    // Condition 2: Active playback flag check (must be actively playing, not paused or stopped)
    if (!_isAudioPlayingOrActive) {
      return; // Playback was paused, stopped, or abandoned; completion is invalid
    }

    // Condition 3: In-flight repetition lock
    if (_isTransitioningRepetition) return;

    // Condition 4: Session identity and active status check
    if (_activeSession != null) {
      if (_playbackSessionId != null && _activeSession!.id != _playbackSessionId) {
        return; // Stale completion event from a different session
      }
      if (_activeSession!.status == JapaSessionStatus.abandoned ||
          _activeSession!.status == JapaSessionStatus.completed) {
        return; // Abandoned or completed session cannot accept new completions
      }
    }

    // Condition 5: Single completion per playback run (cannot process same playback token twice)
    if (_currentPlaybackToken == _lastHandledPlaybackToken) {
      return; // Duplicate completion event from identical playback run
    }

    // Condition 6: Anti-rapid fire debounce guard
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastCompletionTimestampMs < 400) {
      return;
    }

    _isTransitioningRepetition = true;
    _lastCompletionTimestampMs = now;
    _lastHandledPlaybackToken = _currentPlaybackToken;
    _completedRepetitions++;
    _saveSessionProgress();
    _updateActiveSessionOnIncrement(JapaCountingMode.audio);
    notifyListeners();

    // Check if target count is achieved
    if (_completedRepetitions >= _targetRepetitions &&
        !_isContinuingBeyondTarget) {
      // Reached target
      _isTransitioningRepetition = false;

      if (_autoPauseAtTarget) {
        // Stop audio playback at target and signal session completion
        _isAudioPlayingOrActive = false;
        await _audioService.stop();
        notifyListeners();
        return;
      }
    }

    // Handle repeat mode
    switch (_repeatMode) {
      case DevotionalRepeatMode.repeatOff:
        // Do not loop; stop playback after single completion
        _isAudioPlayingOrActive = false;
        await _audioService.stop();
        _isTransitioningRepetition = false;
        notifyListeners();
        return;

      case DevotionalRepeatMode.sequential:
        if (hasNextMantra) {
          _isTransitioningRepetition = false;
          await playNextMantra();
          return;
        } else {
          _isAudioPlayingOrActive = false;
          await _audioService.stop();
          _isTransitioningRepetition = false;
          notifyListeners();
          return;
        }

      case DevotionalRepeatMode.repeatOne:
        // Continue repeating current mantra with fresh playback token for the next repetition
        _currentPlaybackToken++;
        _playbackTrackId = _activeMantra!.id;
        _playbackSessionId = _activeSession?.id;
        _isAudioPlayingOrActive = true;
        try {
          await _audioService.playMantra(_activeMantra!);
        } catch (e) {
          _errorMessage = 'Auto-repeat error: $e';
        } finally {
          _isTransitioningRepetition = false;
        }
        break;
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _sleepTimer?.cancel();
    _stateSub?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();
    _loadingSub?.cancel();
    _audioService.dispose();
    super.dispose();
  }
}

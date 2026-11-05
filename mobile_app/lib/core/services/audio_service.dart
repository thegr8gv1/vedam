import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import '../models/mantra_item.dart';

/// Abstract contract for devotional audio playback.
abstract class AudioPlaybackService {
  Stream<PlayerState> get playerStateStream;
  Stream<Duration> get positionStream;
  Stream<Duration> get durationStream;
  PlayerState get playerState;
  Duration get currentPosition;
  Duration get totalDuration;
  MantraItem? get activeMantra;

  Future<void> playMantra(MantraItem item);
  Future<void> pause();
  Future<void> resume();
  Future<void> stop();
  Future<void> seek(Duration position);
  Future<void> dispose();
}

/// Implementation of AudioPlaybackService using audioplayers package.
class AudioPlaybackServiceImpl implements AudioPlaybackService {
  final AudioPlayer _player;
  MantraItem? _activeMantra;

  StreamSubscription<PlayerState>? _stateSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration>? _durationSubscription;

  final _playerStateController = StreamController<PlayerState>.broadcast();
  final _positionController = StreamController<Duration>.broadcast();
  final _durationController = StreamController<Duration>.broadcast();

  PlayerState _currentState = PlayerState.stopped;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  // Local directory path fallback for full 455 WAV library
  final String localVaultDirectory;

  AudioPlaybackServiceImpl({
    AudioPlayer? player,
    this.localVaultDirectory = r'C:\ttv youtube premium\Mantras',
  }) : _player = player ?? AudioPlayer() {
    _initListeners();
  }

  void _initListeners() {
    _stateSubscription = _player.onPlayerStateChanged.listen((state) {
      _currentState = state;
      _playerStateController.add(state);
    });

    _positionSubscription = _player.onPositionChanged.listen((pos) {
      _currentPosition = pos;
      _positionController.add(pos);
    });

    _durationSubscription = _player.onDurationChanged.listen((dur) {
      _totalDuration = dur;
      _durationController.add(dur);
    });
  }

  @override
  Stream<PlayerState> get playerStateStream => _playerStateController.stream;

  @override
  Stream<Duration> get positionStream => _positionController.stream;

  @override
  Stream<Duration> get durationStream => _durationController.stream;

  @override
  PlayerState get playerState => _currentState;

  @override
  Duration get currentPosition => _currentPosition;

  @override
  Duration get totalDuration => _totalDuration;

  @override
  MantraItem? get activeMantra => _activeMantra;

  @override
  Future<void> playMantra(MantraItem item) async {
    _activeMantra = item;
    _currentPosition = Duration.zero;

    try {
      if (item.isBundled && item.bundledAssetPath != null) {
        // Strip leading "assets/" if audioplayers expects asset relative to flutter assets
        final assetPath = item.bundledAssetPath!.startsWith('assets/')
            ? item.bundledAssetPath!.substring(7)
            : item.bundledAssetPath!;
        await _player.stop();
        await _player.play(AssetSource(assetPath));
      } else {
        // Check if file exists in local storage vault
        final localFilePath = '$localVaultDirectory\\${item.filename}';
        final file = File(localFilePath);
        if (await file.exists()) {
          await _player.stop();
          await _player.play(DeviceFileSource(localFilePath));
        } else {
          debugPrint('Audio recording not found locally: $localFilePath');
          _currentState = PlayerState.stopped;
          _playerStateController.add(PlayerState.stopped);
          throw FileSystemException('Audio recording not found in local vault', localFilePath);
        }
      }
    } catch (e) {
      debugPrint('Playback error for ${item.title}: $e');
      _currentState = PlayerState.stopped;
      _playerStateController.add(PlayerState.stopped);
      rethrow;
    }
  }

  @override
  Future<void> pause() async {
    await _player.pause();
  }

  @override
  Future<void> resume() async {
    await _player.resume();
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    _currentPosition = Duration.zero;
    _positionController.add(Duration.zero);
  }

  @override
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  @override
  Future<void> dispose() async {
    await _stateSubscription?.cancel();
    await _positionSubscription?.cancel();
    await _durationSubscription?.cancel();
    await _playerStateController.close();
    await _positionController.close();
    await _durationController.close();
    await _player.dispose();
  }
}

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/heading_model.dart';

/// Abstract contract for device compass hardware or mock stream provider.
abstract class CompassSensorProvider {
  Stream<Map<String, dynamic>> get headingStream;
  Future<bool> isSensorAvailable();
}

/// Production platform channel provider streaming from Android/iOS native sensors.
class PlatformCompassSensorProvider implements CompassSensorProvider {
  static const EventChannel _channel = EventChannel('org.vedam.vedam_app/compass');

  const PlatformCompassSensorProvider();

  @override
  Stream<Map<String, dynamic>> get headingStream {
    if (kIsWeb) {
      // Return empty stream on web if no web plugin is registered
      return const Stream.empty();
    }
    return _channel.receiveBroadcastStream().map((dynamic event) {
      if (event is Map) {
        return Map<String, dynamic>.from(event);
      }
      return <String, dynamic>{};
    });
  }

  @override
  Future<bool> isSensorAvailable() async {
    if (kIsWeb) {
      // In web browser without sensor extension, compass hardware is unavailable
      return false;
    }
    // On native mobile platforms, availability is verified on stream subscription
    return true;
  }
}

/// Mock sensor provider for deterministic testing of all compass states.
class MockCompassSensorProvider implements CompassSensorProvider {
  final StreamController<Map<String, dynamic>> _controller =
      StreamController<Map<String, dynamic>>.broadcast();
  bool isAvailable;

  MockCompassSensorProvider({this.isAvailable = true});

  @override
  Stream<Map<String, dynamic>> get headingStream => _controller.stream;

  @override
  Future<bool> isSensorAvailable() async => isAvailable;

  void emitReading({
    required double heading,
    String reference = 'MAGNETIC',
    int accuracy = 3,
    int? timestamp,
  }) {
    if (!_controller.isClosed) {
      _controller.add({
        'heading': heading,
        'reference': reference,
        'accuracy': accuracy,
        'timestamp': timestamp ?? DateTime.now().millisecondsSinceEpoch,
      });
    }
  }

  void emitError(Object error) {
    if (!_controller.isClosed) {
      _controller.addError(error);
    }
  }

  void close() {
    _controller.close();
  }
}

/// Foreground-only, privacy-first lifecycle manager for device compass heading readings.
///
/// Governance & Safety Guarantees:
/// - Starts ONLY upon explicit devotee interaction (opt-in).
/// - Tears down sensor subscriptions immediately when stopped or disposed.
/// - Prevents duplicate sensor subscriptions.
/// - Never persists continuous heading history.
/// - Never transmits sensor readings over network.
/// - Distinguishes Magnetic North from True North without fabricating accuracy.
class CompassService extends ChangeNotifier {
  final CompassSensorProvider _provider;

  HeadingReading _reading = HeadingReading.inactive();
  StreamSubscription<Map<String, dynamic>>? _subscription;
  Timer? _stalenessTimer;
  Timer? _throttleTimer;
  DateTime? _lastEmitTime;
  Map<String, dynamic>? _pendingData;
  bool _wasActiveBeforePause = false;
  bool _isDisposed = false;

  /// Time after which missing sensor events trigger stale state.
  static const Duration stalenessThreshold = Duration(seconds: 4);

  /// Minimum delay between UI notification events to prevent 60fps widget thrashing.
  static const Duration throttleInterval = Duration(milliseconds: 50);

  CompassService({CompassSensorProvider? provider})
      : _provider = provider ?? const PlatformCompassSensorProvider();

  HeadingReading get reading => _reading;

  /// Whether compass is actively listening to sensor events.
  bool get isActive =>
      _subscription != null &&
      (_reading.state == HeadingSensorState.active ||
          _reading.state == HeadingSensorState.lowAccuracy ||
          _reading.state == HeadingSensorState.stale);

  /// Explicitly starts the device compass sensor in foreground.
  Future<void> startCompass() async {
    if (_isDisposed) return;
    // Prevent duplicate subscriptions
    if (_subscription != null) return;

    final available = await _provider.isSensorAvailable();
    if (!available) {
      _reading = HeadingReading.unavailable(
        reason: 'Geomagnetic orientation hardware is not available in this environment.',
      );
      if (!_isDisposed) notifyListeners();
      return;
    }

    _reading = HeadingReading.inactive(message: 'Initializing compass hardware...');
    if (!_isDisposed) notifyListeners();

    try {
      _subscription = _provider.headingStream.listen(
        _handleSensorData,
        onError: _handleSensorError,
        onDone: _handleSensorDone,
        cancelOnError: false,
      );
      _resetStalenessTimer();
    } catch (e) {
      _reading = HeadingReading.unavailable(
        reason: 'Unable to connect to device orientation sensor: $e',
      );
      if (!_isDisposed) notifyListeners();
    }
  }

  /// Explicitly stops the sensor and releases hardware resources immediately.
  void stopCompass() {
    _subscription?.cancel();
    _subscription = null;
    _stalenessTimer?.cancel();
    _stalenessTimer = null;
    _throttleTimer?.cancel();
    _throttleTimer = null;
    _pendingData = null;
    _lastEmitTime = null;
    _wasActiveBeforePause = false;

    _reading = HeadingReading.inactive();
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  /// Called when application or screen enters paused/background state.
  void pauseCompass() {
    if (isActive) {
      _wasActiveBeforePause = true;
      _subscription?.cancel();
      _subscription = null;
      _stalenessTimer?.cancel();
      _stalenessTimer = null;
      _throttleTimer?.cancel();
      _throttleTimer = null;
      _pendingData = null;
      _lastEmitTime = null;
      _reading = HeadingReading.inactive(message: 'Compass paused in background.');
      notifyListeners();
    }
  }

  /// Called when application or screen returns to foreground.
  Future<void> resumeCompass() async {
    if (_wasActiveBeforePause) {
      _wasActiveBeforePause = false;
      await startCompass();
    }
  }

  void _handleSensorData(Map<String, dynamic> data) {
    _resetStalenessTimer();

    final now = DateTime.now();
    if (_lastEmitTime != null && now.difference(_lastEmitTime!) < throttleInterval) {
      // Buffer the latest payload to throttle
      _pendingData = data;
      if (_throttleTimer == null || !_throttleTimer!.isActive) {
        _throttleTimer = Timer(throttleInterval, () {
          if (_pendingData != null) {
            _processPayload(_pendingData!);
            _pendingData = null;
          }
        });
      }
      return;
    }

    _lastEmitTime = now;
    _processPayload(data);
  }

  void _processPayload(Map<String, dynamic> data) {
    final rawHeading = (data['heading'] as num?)?.toDouble();
    if (rawHeading == null || rawHeading.isNaN || rawHeading.isInfinite) {
      return;
    }

    final ref = HeadingReference.fromString(data['reference'] as String?);
    final acc = HeadingAccuracy.fromCode(data['accuracy'] as int?);
    final ts = data['timestamp'] != null
        ? DateTime.fromMillisecondsSinceEpoch(data['timestamp'] as int)
        : DateTime.now();

    _reading = HeadingReading.active(
      heading: rawHeading,
      reference: ref,
      accuracy: acc,
      timestamp: ts,
    );
    notifyListeners();
  }

  void _handleSensorError(Object error) {
    _stalenessTimer?.cancel();
    if (error is PlatformException &&
        (error.code == 'PERMISSION_DENIED' || error.message?.toLowerCase().contains('permission') == true)) {
      _reading = HeadingReading.permissionDenied(reason: error.message);
    } else if (error is PlatformException && error.code == 'SENSOR_UNAVAILABLE') {
      _reading = HeadingReading.unavailable(reason: error.message);
    } else {
      _reading = HeadingReading.error(message: 'Sensor stream error: $error');
    }
    notifyListeners();
  }

  void _handleSensorDone() {
    stopCompass();
  }

  void _resetStalenessTimer() {
    _stalenessTimer?.cancel();
    _stalenessTimer = Timer(stalenessThreshold, () {
      if (isActive && _reading.hasValidHeading) {
        _reading = HeadingReading.stale(
          previous: _reading,
          reason: 'Sensor updates delayed or stopped. Move away from magnetic interference.',
        );
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _subscription?.cancel();
    _subscription = null;
    _stalenessTimer?.cancel();
    _stalenessTimer = null;
    _throttleTimer?.cancel();
    _throttleTimer = null;
    super.dispose();
  }
}

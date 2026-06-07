import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/storage/storage_service.dart';

import '../connect/data/models/cgm_device_model.dart';

import '../connect/data/repository/cgm_device_repository_impl.dart';

import '../sdk/cgm_sdk.dart';

import 'cgm_session_state.dart';

/// App-lifetime singleton that owns the CGM connection lifecycle.
///
/// Responsibilities:
///   - Owns the single SDK event subscription.
///   - Holds the canonical [CgmSessionState] and streams updates.
///   - Persists the last-paired device locally and auto-reconnects
///     on app start / app resume.
///   - Guards against duplicate connect/scan attempts.
///   - Tracks Bluetooth adapter state and surfaces it as a status.
///   - Schedules retries with exponential backoff when out of range.
class CgmSessionManager {
  CgmSessionManager._();

  static final CgmSessionManager
      instance =
      CgmSessionManager._();

  final _controller = StreamController<
      CgmSessionState>.broadcast();

  Stream<CgmSessionState>
      get states =>
          _controller.stream;

  CgmSessionState _state =
      const CgmSessionState.initial();

  CgmSessionState get state => _state;

  StreamSubscription? _eventSub;

  bool _bluetoothEnabled = true;

  bool _bootstrapped = false;

  bool _autoReconnect = true;

  /// True only after the user *manually* disconnects (Profile → Disconnect
  /// CGM). While set, every inbound SDK event is ignored so the native layer
  /// can't silently auto-reconnect; cleared on a user-initiated connect.
  /// Distinct from [_autoReconnect] so unexpected drops still auto-recover.
  bool _manuallyDisconnected = false;

  bool _attemptInFlight = false;

  Timer? _retryTimer;

  int _retryAttempt = 0;

  /// Wall-clock time the last glucose frame arrived. Drives the
  /// stale-reading watchdog.
  DateTime? _lastReadingAt;

  Timer? _staleWatchdog;

  /// The sensor's reading cadence in minutes, taken from `deviceInfo`.
  /// Defaults to 5 until the device reports its real interval.
  int _measurementIntervalMin = 5;

  /// How long without a reading (while we believe we're connected) before
  /// forcing a reconnect. Derived from the device's measurement interval so
  /// we tolerate a missed cycle without churning the connection: ~2 missed
  /// readings, clamped to a sane [5, 20] minute range.
  Duration get _staleThreshold {
    final minutes =
        (_measurementIntervalMin * 2 + 1).clamp(5, 20);
    return Duration(minutes: minutes);
  }

  final List<Duration>
      _retrySchedule = const [
    Duration(seconds: 3),
    Duration(seconds: 10),
    Duration(seconds: 30),
    Duration(minutes: 2),
    Duration(minutes: 5),
  ];

  CGMDeviceModel? _activeDeviceCache;

  CGMDeviceModel? get activeDevice =>
      _activeDeviceCache;

  bool _backendRegistered = false;

  final _deviceRepository =
      CgmDeviceRepository();

  /// Call once at app startup. Idempotent.
  ///
  /// Attaches SDK listeners, restores any saved session and (if
  /// auto-reconnect is enabled) begins a reconnect attempt.
  Future<void> bootstrap() async {
    if (_bootstrapped) return;

    _bootstrapped = true;

    _attachSdkStream();

    _startStaleWatchdog();

    _bluetoothEnabled =
        await CgmSdk.isBluetoothEnabled();

    final saved = await StorageService
        .getCgmSession();

    if (saved == null) {
      _emit(
        const CgmSessionState
            .initial(),
      );

      return;
    }

    _autoReconnect = await StorageService
        .getCgmAutoReconnect();

    _emit(
      _state.copyWith(
        status: _autoReconnect
            ? (_bluetoothEnabled
                ? CGMConnectionStatus
                    .reconnecting
                : CGMConnectionStatus
                    .bluetoothOff)
            : CGMConnectionStatus
                .disconnected,
        sn: saved["sn"],
        deviceName:
            saved["deviceName"],
        manufacturer:
            saved["manufacturer"],
        restoredFromStorage: true,
        message: null,
      ),
    );

    // Best-effort: warm device row + reading-list endpoint will pick
    // up whatever the backend already has.
    _refreshBackendDevice();

    if (_autoReconnect &&
        _bluetoothEnabled) {
      _attemptConnect(reason: "boot");
    }
  }

  /// Manual connect (from the pairing screen). Persists the device
  /// so future launches will auto-reconnect.
  Future<void> connect({
    required String sn,
    required String deviceName,
    required String manufacturer,
  }) async {
    await StorageService
        .setCgmSession(
      sn: sn,
      deviceName: deviceName,
      manufacturer: manufacturer,
      autoReconnect: true,
    );

    _autoReconnect = true;

    // User explicitly reconnected — re-enable normal monitoring.
    _manuallyDisconnected = false;

    _retryAttempt = 0;

    _emit(
      _state.copyWith(
        sn: sn,
        deviceName: deviceName,
        manufacturer: manufacturer,
        status: CGMConnectionStatus
            .searching,
        message: null,
        syncProgress: 0,
        // Clear any step left over from a prior session so the connect
        // checklist starts clean at "searching".
        lastBindStep: null,
      ),
    );

    await _attemptConnect(
      reason: "manual",
    );
  }

  /// Manual disconnect. Stops auto-reconnect and tears down the
  /// SDK connection. After this, the app routes the user back to the
  /// Connect Intro screen on next launch.
  Future<void> disconnect() async {
    _autoReconnect = false;

    _manuallyDisconnected = true;

    _retryTimer?.cancel();

    _retryTimer = null;

    _retryAttempt = 0;

    _attemptInFlight = false;

    try {
      await CgmSdk.stopHeartbeat();
    } catch (_) {}

    // Stop the native scanner too so the SDK can't re-find + auto-reconnect.
    try {
      await CgmSdk.stopScan();
    } catch (_) {}

    try {
      await CgmSdk.disconnect();
    } catch (_) {}

    await StorageService
        .clearCgmSession();

    _activeDeviceCache = null;

    _backendRegistered = false;

    _emit(
      const CgmSessionState
          .initial(),
    );
  }

  /// User-triggered "Reconnect now" (e.g. after they turned BT on).
  Future<void>
      reconnectNow() async {
    _retryTimer?.cancel();

    _retryAttempt = 0;

    _autoReconnect = true;

    _manuallyDisconnected = false;

    await StorageService
        .setCgmAutoReconnect(true);

    await _attemptConnect(
      reason: "manual_retry",
    );
  }

  /// App lifecycle hook — call from didChangeAppLifecycleState.
  Future<void> onAppResumed() async {
    if (!_autoReconnect) return;

    if (_state.sn == null) return;

    if (_state.status ==
            CGMConnectionStatus
                .active ||
        _state.status ==
            CGMConnectionStatus
                .syncing) {
      return;
    }

    // Refresh BT state — user may have toggled it.
    _bluetoothEnabled = await CgmSdk
        .isBluetoothEnabled();

    if (!_bluetoothEnabled) {
      _emit(
        _state.copyWith(
          status: CGMConnectionStatus
              .bluetoothOff,
          message:
              "Turn on Bluetooth to reconnect.",
        ),
      );

      return;
    }

    await _attemptConnect(
      reason: "resume",
    );
  }

  Future<void> _attemptConnect({
    required String reason,
  }) async {
    final sn = _state.sn;

    if (sn == null || sn.isEmpty) return;

    if (_attemptInFlight) return;

    _attemptInFlight = true;

    try {
      if (!_bluetoothEnabled) {
        _emit(
          _state.copyWith(
            status:
                CGMConnectionStatus
                    .bluetoothOff,
            message:
                "Turn on Bluetooth to reconnect.",
          ),
        );

        return;
      }

      // Permission gate.
      final granted = await CgmSdk
          .requestPermissions();

      if (!granted) {
        _emit(
          _state.copyWith(
            status:
                CGMConnectionStatus
                    .permissionsDenied,
            message:
                "Bluetooth and location permissions are required.",
          ),
        );

        return;
      }

      // Auth gate.
      final authorized = await CgmSdk
          .checkAuthorized();

      if (!authorized) {
        _emit(
          _state.copyWith(
            status:
                CGMConnectionStatus
                    .authenticating,
          ),
        );

        final ok = await CgmSdk
            .auth();

        if (!ok) {
          _emit(
            _state.copyWith(
              status:
                  CGMConnectionStatus
                      .authFailed,
              message:
                  "SDK authentication failed.",
            ),
          );

          return;
        }
      }

      _emit(
        _state.copyWith(
          status: _retryAttempt > 0
              ? CGMConnectionStatus
                  .reconnecting
              : CGMConnectionStatus
                  .searching,
          message: null,
        ),
      );

      debugPrint(
        "CGM connect attempt (#$_retryAttempt, reason=$reason) sn=$sn",
      );

      await CgmSdk.connect(sn);
      // Bind-step events drive the rest of the state machine.
    } catch (e) {
      _emit(
        _state.copyWith(
          status: CGMConnectionStatus
              .failed,
          message: e.toString(),
        ),
      );

      _scheduleRetryIfEligible();
    } finally {
      _attemptInFlight = false;
    }
  }

  void _scheduleRetryIfEligible() {
    if (!_autoReconnect) return;

    if (_state.sn == null) return;

    if (!_bluetoothEnabled) return;

    _retryTimer?.cancel();

    final delay =
        _retryAttempt < _retrySchedule
                .length
            ? _retrySchedule[
                _retryAttempt]
            : _retrySchedule.last;

    _retryAttempt++;

    debugPrint(
      "CGM retry scheduled in ${delay.inSeconds}s",
    );

    _retryTimer = Timer(
      delay,
      () {
        _attemptConnect(
          reason:
              "retry_$_retryAttempt",
        );
      },
    );
  }

  void _attachSdkStream() {
    _eventSub?.cancel();

    try {
      _eventSub = CgmSdk.events
          .listen(
        _onSdkEvent,
        onError: (e) {
          debugPrint(
            "Cgm stream error: $e",
          );
        },
        cancelOnError: false,
      );
    } catch (_) {
      // Native side missing — bootstrap still completes.
    }
  }

  /// Periodic watchdog: when we believe we're connected but no glucose
  /// frame has arrived within [_staleThreshold], the BLE link has
  /// silently died — force a reconnect. Mirrors the reference app's
  /// heartbeat-driven "rescan if newest reading is stale" behaviour.
  void _startStaleWatchdog() {
    _staleWatchdog?.cancel();

    _staleWatchdog = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _checkStaleReadings(),
    );
  }

  void _checkStaleReadings() {
    if (!_autoReconnect) return;

    if (_state.sn == null) return;

    if (!_bluetoothEnabled) return;

    // Only meaningful while we think data should be flowing.
    if (_state.status !=
            CGMConnectionStatus.active &&
        _state.status !=
            CGMConnectionStatus.syncing) {
      return;
    }

    if (_attemptInFlight) return;

    final last = _lastReadingAt;

    if (last == null) return;

    if (DateTime.now()
            .difference(last) <=
        _staleThreshold) {
      return;
    }

    debugPrint(
      "CGM readings stale (>${_staleThreshold.inMinutes}m) — forcing reconnect",
    );

    // Avoid an immediate re-trigger before the next frame lands.
    _lastReadingAt = DateTime.now();

    _retryAttempt = 0;

    _attemptConnect(
      reason: "stale_readings",
    );
  }

  void _onSdkEvent(
    Map<String, dynamic> event,
  ) {
    final type = event["type"];

    // After a manual disconnect, swallow everything the SDK emits (the
    // native layer may keep scanning / auto-reconnecting) so the app never
    // silently reconnects. Only keep the Bluetooth-adapter flag fresh for
    // the UI — without triggering any reconnect. Cleared on user connect.
    if (_manuallyDisconnected) {
      if (type == "bluetoothStateChanged") {
        _bluetoothEnabled = event["enabled"] == true;
      }
      return;
    }

    switch (type) {
      case "bluetoothStateChanged":
        final enabled =
            event["enabled"] ==
                true;

        _bluetoothEnabled = enabled;

        if (!enabled) {
          if (_state.sn != null) {
            _emit(
              _state.copyWith(
                status:
                    CGMConnectionStatus
                        .bluetoothOff,
                message:
                    "Bluetooth is off — turn it on to reconnect.",
              ),
            );
          }
        } else {
          if (_autoReconnect &&
              _state.sn != null &&
              _state.status !=
                  CGMConnectionStatus
                      .active &&
              _state.status !=
                  CGMConnectionStatus
                      .syncing) {
            _retryAttempt = 0;
            _attemptConnect(
              reason:
                  "bluetooth_on",
            );
          }
        }
        break;

      case "bindStep":
        _handleBindStep(
          event["step"] as String?,
        );
        break;

      case "glucoseData":
        // The SDK asks us to surface a sensor error on this batch.
        if (event["isErrorShow"] == true) {
          _emitMalfunction();
          break;
        }
        // An abandoned batch with no error flag is a normal warmup/invalid
        // window — discard it without resetting the staleness clock.
        if (event["isAbandoned"] == true) break;

        // Only the arrival time matters here — the dashboard provider
        // owns the actual readings. Resets the staleness clock.
        _lastReadingAt = DateTime.now();
        break;

      case "connected":
        _retryAttempt = 0;

        _lastReadingAt = DateTime.now();

        _emit(
          _state.copyWith(
            status:
                CGMConnectionStatus
                    .active,
            message: null,
          ),
        );

        CgmSdk.startHeartbeat();

        _registerWithBackendOnce();
        break;

      case "disconnected":
        // Distinguish user-initiated disconnect (handled in
        // disconnect()) from drop-while-paired.
        if (!_autoReconnect) break;

        if (_state.sn == null) break;

        _emit(
          _state.copyWith(
            status:
                CGMConnectionStatus
                    .outOfRange,
            message:
                "Sensor is out of range. Will keep retrying…",
          ),
        );

        _scheduleRetryIfEligible();
        break;

      case "deviceInfo":
        _handleDeviceInfo(event);
        break;

      case "syncProgress":
        final raw =
            event["progress"];

        if (raw is num) {
          final progress =
              (raw / 100.0)
                  .clamp(0.0, 1.0)
                  .toDouble();

          final next =
              _state.syncProgress >
                      progress
                  ? _state
                      .syncProgress
                  : progress;

          var status =
              _state.status;

          if (next < 1 &&
              status ==
                  CGMConnectionStatus
                      .active) {
            status =
                CGMConnectionStatus
                    .syncing;
          } else if (next >= 1) {
            status =
                CGMConnectionStatus
                    .active;
          }

          _emit(
            _state.copyWith(
              syncProgress: next,
              status: status,
            ),
          );

          _registerWithBackendOnce();
        }
        break;

      case "error":
        final msg =
            (event["error"]
                    as String?) ??
                "SDK error";

        final code = (event["errorCode"]
                as num?)
            ?.toInt();
        final name = event["errorName"]
            ?.toString();

        // Device malfunction (3003 "deviceAbandoned") — a hardware fault
        // that won't recover by retrying. Surface it even while active.
        if (code == 3003 ||
            name == "deviceAbandoned") {
          _emitMalfunction();
          break;
        }

        if (_state.status !=
                CGMConnectionStatus
                    .active &&
            _state.status !=
                CGMConnectionStatus
                    .syncing) {
          _emit(
            _state.copyWith(
              status:
                  CGMConnectionStatus
                      .failed,
              message: msg,
            ),
          );

          _scheduleRetryIfEligible();
        }
        break;

      case "authResult":
        if (event["success"] !=
            true) {
          _emit(
            _state.copyWith(
              status:
                  CGMConnectionStatus
                      .authFailed,
              message:
                  "SDK authentication failed.",
            ),
          );
        }
        break;
    }
  }

  void _handleBindStep(String? step) {
    if (step == null) return;

    var msg = _state.message;

    var status = _state.status;

    switch (step) {
      case "DeviceSearching":
        status = _retryAttempt > 0
            ? CGMConnectionStatus
                .reconnecting
            : CGMConnectionStatus
                .searching;
        break;

      case "DeviceFound":
      case "DeviceConnecting":
        status =
            CGMConnectionStatus
                .connecting;
        break;

      case "DeviceNotFound":
        status = CGMConnectionStatus
            .outOfRange;
        msg =
            "Sensor not found. Will keep retrying…";
        _scheduleRetryIfEligible();
        break;

      case "DeviceConnectFail":
      case "DeviceEnableServiceFail":
        status = CGMConnectionStatus
            .failed;
        msg ??=
            "Failed to connect to device.";
        _scheduleRetryIfEligible();
        break;

      case "DeviceActivating":
        status =
            CGMConnectionStatus
                .warmup;
        break;

      case "DeviceActivationFail":
        status = CGMConnectionStatus
            .failed;
        msg ??=
            "Device activation failed.";
        break;

      case "DeviceHistoryDataSyncing":
        status =
            CGMConnectionStatus
                .syncing;
        break;

      case "DeviceHistoryDataSyncSuccess":
        status = CGMConnectionStatus
            .active;
        break;
    }

    _emit(
      _state.copyWith(
        status: status,
        message: msg,
        lastBindStep: step,
      ),
    );
  }

  void _handleDeviceInfo(
    Map<String, dynamic> event,
  ) {
    final sn = event["sn"]
            ?.toString() ??
        _state.sn;

    if (sn == null) return;

    // Capture the sensor's reading cadence so the stale watchdog adapts to
    // the actual device (the SDK reports it in seconds when >= 60).
    final rawInterval =
        (event["measurementInterval"] as num?)
            ?.toInt();
    if (rawInterval != null && rawInterval > 0) {
      _measurementIntervalMin =
          rawInterval >= 60 ? rawInterval ~/ 60 : rawInterval;
    }

    final activatedSec =
        (event["deviceActivateTimestamp"]
                as num?) ??
            0;

    final activatedAt = activatedSec > 0
        ? DateTime
            .fromMillisecondsSinceEpoch(
            activatedSec.toInt() *
                1000,
          )
        : DateTime.now();

    final expiresAt = activatedAt.add(
      const Duration(days: 15),
    );

    final isExpired =
        event["isExpired"] == true;

    final cached = _activeDeviceCache;

    final updated = (cached ??
            CGMDeviceModel(
              id: sn,
              serialNumber: sn,
              deviceName: _state
                      .deviceName ??
                  "CGM Sensor",
              manufacturer: _state
                      .manufacturer ??
                  "Eaglenos",
              isActive: !isExpired,
              connectedAt:
                  activatedAt,
              expiresAt: expiresAt,
            ))
        .copyWith(
      isActive: !isExpired,
      connectedAt: activatedAt,
      expiresAt: expiresAt,
    );

    _activeDeviceCache = updated;

    // Warm-up window: the Eaglenos sensor preheats for 60 minutes after
    // activation. `isPreheating` is the sensor's own flag; `warmupEndsAt`
    // gives an exact countdown target derived from the activation time.
    final warmupEndsAt = activatedSec > 0
        ? activatedAt.add(
            const Duration(minutes: 60),
          )
        : null;

    final isPreheating =
        event["isPreheating"] == true;

    if (isExpired) {
      _emit(
        _state.copyWith(
          status: CGMConnectionStatus
              .expired,
          message:
              "Sensor expired. Please replace it.",
          warmupEndsAt: warmupEndsAt,
          isPreheating: false,
        ),
      );
    } else {
      _emit(
        _state.copyWith(
          warmupEndsAt: warmupEndsAt,
          isPreheating: isPreheating,
        ),
      );
    }
  }

  Future<void>
      _registerWithBackendOnce() async {
    if (_backendRegistered) return;

    final sn = _state.sn;

    if (sn == null) return;

    final created = await _deviceRepository
        .connectDevice(
      serialNumber: sn,
      deviceName: _state
              .deviceName ??
          "CGM Sensor",
      manufacturer:
          _state.manufacturer ??
              "Eaglenos",
    );

    if (created != null) {
      _backendRegistered = true;
      _activeDeviceCache = created;
      _emit(_state);
    }
  }

  Future<void>
      _refreshBackendDevice() async {
    final remote = await _deviceRepository
        .getActiveDevice();

    if (remote != null) {
      _activeDeviceCache = remote;
      _backendRegistered = true;
      _emit(_state);
    }
  }

  void _emit(
    CgmSessionState next,
  ) {
    _state = next;

    if (!_controller.isClosed) {
      _controller.add(next);
    }
  }

  /// Surface a sensor hardware fault. Retrying won't help, so cancel any
  /// pending reconnect and leave it to the user to replace the sensor.
  void _emitMalfunction() {
    _retryTimer?.cancel();

    if (_state.status ==
        CGMConnectionStatus.malfunction) {
      return;
    }

    _emit(
      _state.copyWith(
        status: CGMConnectionStatus
            .malfunction,
        message:
            "Sensor malfunction detected. Please replace your CGM sensor.",
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';

import '../../../session/cgm_session_manager.dart';

import '../../data/models/cgm_device_model.dart';

// Re-export so existing imports keep working.
export '../../../session/cgm_session_state.dart'
    show CGMConnectionStatus;

import '../../../session/cgm_session_state.dart';

/// ChangeNotifier facade over [CgmSessionManager].
///
/// All state lives in the manager; this provider just rebroadcasts via
/// the Provider package so widgets can `context.watch<CGMProvider>()`.
class CGMProvider extends ChangeNotifier {
  CGMProvider({
    CgmSessionManager? manager,
  }) : _manager = manager ??
            CgmSessionManager
                .instance {
    _sub = _manager.states.listen(
      (next) {
        _state = next;

        notifyListeners();
      },
    );
  }

  final CgmSessionManager _manager;

  late final StreamSubscription
      _sub;

  CgmSessionState _state = const
      CgmSessionState.initial();

  // --- Mirrors of state needed by existing widgets ---

  CGMConnectionStatus
      get connectionStatus =>
          _state.status;

  double get syncProgress =>
      _state.syncProgress;

  String? get lastError =>
      _state.message;

  String? get lastBindStep =>
      _state.lastBindStep;

  /// Sensor is still warming up (no valid readings yet).
  bool get isPreheating =>
      _state.isPreheating;

  /// Exact moment the warm-up completes; null when unknown.
  DateTime? get warmupEndsAt =>
      _state.warmupEndsAt;

  /// True while the warm-up nudge should be shown — the sensor is
  /// preheating and the 60-minute window hasn't elapsed.
  bool get isWarmingUp {
    final ends = _state.warmupEndsAt;
    if (!_state.isPreheating || ends == null) {
      return false;
    }
    return DateTime.now().isBefore(ends);
  }

  /// Always returns the currently known device (paired or attempting).
  CGMDeviceModel? get activeDevice {
    final cached =
        _manager.activeDevice;

    if (cached != null) return cached;

    final sn = _state.sn;

    if (sn == null) return null;

    // Fall back to a lightweight model from session state so the UI
    // can render "Reconnecting to <device>" before deviceInfo arrives.
    return CGMDeviceModel(
      id: sn,
      serialNumber: sn,
      deviceName: _state.deviceName ??
          "CGM Sensor",
      manufacturer:
          _state.manufacturer ??
              "Eaglenos",
      isActive: connectionStatus ==
              CGMConnectionStatus
                  .active ||
          connectionStatus ==
              CGMConnectionStatus
                  .syncing,
      connectedAt:
          DateTime.now(),
      expiresAt: DateTime.now().add(
        const Duration(days: 14),
      ),
    );
  }

  /// All devices known locally — currently just the active one, since
  /// the SDK exposes a single bound sensor at a time.
  List<CGMDeviceModel>
      get devices {
    final d = activeDevice;
    return d == null ? const [] : [d];
  }

  bool get isReconnecting {
    switch (connectionStatus) {
      case CGMConnectionStatus
            .reconnecting:
      case CGMConnectionStatus
            .searching:
      case CGMConnectionStatus
            .connecting:
      case CGMConnectionStatus
            .authenticating:
      case CGMConnectionStatus
            .outOfRange:
        return true;
      default:
        return false;
    }
  }

  bool get isBluetoothOff =>
      connectionStatus ==
          CGMConnectionStatus
              .bluetoothOff;

  // --- Actions ---

  /// Pull latest device info from backend (refresh).
  Future<void> fetchDevices() async {
    // The manager already loads /cgm-device/active during bootstrap
    // and on connect. This call is kept for backwards compat with
    // existing pull-to-refresh handlers.
    await _manager.reconnectNow();
  }

  /// Manual connect from the pairing screen.
  Future<void> connectDevice({
    required String serialNumber,
    required String deviceName,
    required String manufacturer,
  }) async {
    await _manager.connect(
      sn: serialNumber,
      deviceName: deviceName,
      manufacturer: manufacturer,
    );
  }

  Future<void> disconnect() async {
    await _manager.disconnect();
  }

  Future<void>
      retryReconnect() async {
    await _manager.reconnectNow();
  }

  Future<void> switchDevice(
    CGMDeviceModel device,
  ) async {
    await _manager.connect(
      sn: device.serialNumber,
      deviceName: device.deviceName,
      manufacturer:
          device.manufacturer,
    );
  }

  /// Legacy disconnect name kept for the older Profile-screen call site.
  Future<void>
      disconnectActive() async {
    await _manager.disconnect();
  }

  String get connectionText {
    switch (connectionStatus) {
      case CGMConnectionStatus
            .permissionsDenied:
        return "Permissions Required";
      case CGMConnectionStatus
            .bluetoothOff:
        return "Bluetooth Off";
      case CGMConnectionStatus
            .authenticating:
        return "Authenticating";
      case CGMConnectionStatus
            .authFailed:
        return "Auth Failed";
      case CGMConnectionStatus
            .reconnecting:
        return "Reconnecting";
      case CGMConnectionStatus
            .searching:
        return "Searching Sensor";
      case CGMConnectionStatus
            .connecting:
        return "Connecting";
      case CGMConnectionStatus
            .warmup:
        return "Sensor Warmup";
      case CGMConnectionStatus
            .syncing:
        return "Syncing Readings";
      case CGMConnectionStatus
            .active:
        return "Sensor Active";
      case CGMConnectionStatus
            .outOfRange:
        return "Out of Range";
      case CGMConnectionStatus
            .expired:
        return "Sensor Expired";
      case CGMConnectionStatus
            .failed:
        return "Connection Failed";
      case CGMConnectionStatus
            .disconnected:
        return "Disconnected";
    }
  }

  Color get statusColor {
    switch (connectionStatus) {
      case CGMConnectionStatus
            .active:
        return Colors.green;
      case CGMConnectionStatus
            .warmup:
        return Colors.orange;
      case CGMConnectionStatus
            .syncing:
      case CGMConnectionStatus
            .reconnecting:
      case CGMConnectionStatus
            .searching:
      case CGMConnectionStatus
            .connecting:
      case CGMConnectionStatus
            .authenticating:
        return Colors.blue;
      case CGMConnectionStatus
            .outOfRange:
        return Colors.amber;
      case CGMConnectionStatus
            .expired:
      case CGMConnectionStatus
            .failed:
      case CGMConnectionStatus
            .authFailed:
      case CGMConnectionStatus
            .permissionsDenied:
      case CGMConnectionStatus
            .bluetoothOff:
        return Colors.red;
      case CGMConnectionStatus
            .disconnected:
        return Colors.grey;
    }
  }

  @override
  void dispose() {
    _sub.cancel();

    super.dispose();
  }
}

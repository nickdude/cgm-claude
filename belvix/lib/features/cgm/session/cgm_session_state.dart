import 'package:flutter/material.dart';

/// All connection lifecycle states the UI cares about.
///
/// The order roughly tracks happy-path progression:
/// disconnected → reconnecting → searching → connecting → warmup →
/// syncing → active. Off-happy-path states (bluetoothOff, outOfRange,
/// failed, expired, permissionsDenied, authFailed) signal user-actionable
/// or recoverable conditions.
enum CGMConnectionStatus {
  /// User has never paired a device, or explicitly disconnected.
  disconnected,

  permissionsDenied,
  bluetoothOff,
  authenticating,
  authFailed,

  /// We have a saved device and are attempting an unattended reconnect.
  reconnecting,

  /// Actively scanning (whether initial pair or reconnect).
  searching,

  /// GATT handshake in progress.
  connecting,

  /// Sensor warmup (first 60 minutes after activation).
  warmup,

  /// Pulling historical readings.
  syncing,

  /// Live data flowing.
  active,

  /// Was connected, BLE link dropped; auto-reconnect will retry.
  outOfRange,

  /// Sensor past 15-day life.
  expired,

  /// Sensor hardware fault / abandoned by the SDK (error 3003 "Device
  /// malfunction" or a glucose batch flagged isErrorShow). User must
  /// replace the sensor.
  malfunction,

  /// Fatal error — user must act (re-pair, replace sensor, etc.).
  failed,
}

/// Immutable snapshot of CGM session state.
@immutable
class CgmSessionState {
  final CGMConnectionStatus status;

  /// SN of the device the session is bound to (paired or attempting).
  final String? sn;

  final String? deviceName;

  final String? manufacturer;

  /// 0.0–1.0 sync progress from the SDK.
  final double syncProgress;

  /// Human-readable error/last-state message; null when none.
  final String? message;

  /// Most recent bind-step name reported by the SDK.
  final String? lastBindStep;

  /// True once a saved session has been loaded from storage.
  final bool restoredFromStorage;

  /// When the sensor finishes its post-activation warm-up; null if unknown.
  final DateTime? warmupEndsAt;

  /// True while the sensor is still in its warm-up window (no valid
  /// readings yet) — drives the warm-up nudge.
  final bool isPreheating;

  const CgmSessionState({
    required this.status,
    this.sn,
    this.deviceName,
    this.manufacturer,
    this.syncProgress = 0,
    this.message,
    this.lastBindStep,
    this.restoredFromStorage = false,
    this.warmupEndsAt,
    this.isPreheating = false,
  });

  const CgmSessionState.initial()
      : status =
            CGMConnectionStatus
                .disconnected,
        sn = null,
        deviceName = null,
        manufacturer = null,
        syncProgress = 0,
        message = null,
        lastBindStep = null,
        restoredFromStorage = false,
        warmupEndsAt = null,
        isPreheating = false;

  CgmSessionState copyWith({
    CGMConnectionStatus? status,
    String? sn,
    String? deviceName,
    String? manufacturer,
    double? syncProgress,
    Object? message = _sentinel,
    Object? lastBindStep =
        _sentinel,
    bool? restoredFromStorage,
    Object? warmupEndsAt = _sentinel,
    bool? isPreheating,
  }) {
    return CgmSessionState(
      status: status ?? this.status,
      sn: sn ?? this.sn,
      deviceName: deviceName ??
          this.deviceName,
      manufacturer: manufacturer ??
          this.manufacturer,
      syncProgress: syncProgress ??
          this.syncProgress,
      message:
          identical(message, _sentinel)
              ? this.message
              : message as String?,
      lastBindStep: identical(
        lastBindStep,
        _sentinel,
      )
          ? this.lastBindStep
          : lastBindStep as String?,
      restoredFromStorage:
          restoredFromStorage ??
              this.restoredFromStorage,
      warmupEndsAt: identical(
        warmupEndsAt,
        _sentinel,
      )
          ? this.warmupEndsAt
          : warmupEndsAt as DateTime?,
      isPreheating: isPreheating ??
          this.isPreheating,
    );
  }
}

const _sentinel = Object();

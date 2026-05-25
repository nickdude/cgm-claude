import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:permission_handler/permission_handler.dart';

import '../../../app/constants/cgm_credentials.dart';

import 'cgm_event_channel.dart';

import 'cgm_method_channel.dart';

/// High-level Dart facade for the Eaglenos CGM SDK.
///
/// Wraps platform channel calls and surfaces a single broadcast event
/// stream ([events]) that emits normalised maps with a `type` discriminator.
class CgmSdk {
  /// Broadcast stream of all CGM SDK events.
  static Stream<Map<String, dynamic>>
      get events => CgmEventChannel.events;

  static Future<void> init() async {
    await CgmMethodChannel.init();
  }

  /// Request runtime permissions required for BLE + scanning.
  ///
  /// Returns true only when the permissions the SDK actually needs are
  /// granted. On Android 12+ that's just BLUETOOTH_SCAN +
  /// BLUETOOTH_CONNECT (the manifest declares `neverForLocation` so
  /// location is not required). On Android 11 or older we also need
  /// fine location.
  static Future<bool>
      requestPermissions() async {
    if (!Platform.isAndroid) {
      return false;
    }

    final required = <Permission>[
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ];

    final statuses =
        await required.request();

    final allGranted = statuses.values
        .every((s) => s.isGranted);

    if (!allGranted) {
      debugPrint(
        "CGM permissions denied: $statuses",
      );
    }

    // Notifications are best-effort; ask but don't block on the result.
    try {
      await Permission
          .notification
          .request();
    } catch (_) {}

    return allGranted;
  }

  static Future<bool> auth({
    String? appId,
    String? appSecret,
  }) async {
    final id = appId ??
        CgmCredentials.appId;

    final secret = appSecret ??
        CgmCredentials.appSecret;

    if (id.isEmpty ||
        secret.isEmpty) {
      debugPrint(
        "CGM credentials not configured",
      );

      return false;
    }

    return await CgmMethodChannel.auth(
      appId: id,
      appSecret: secret,
    );
  }

  static Future<bool>
      checkAuthorized() async {
    return await CgmMethodChannel
        .checkAuthorized();
  }

  static Future<void>
      startScan() async {
    await CgmMethodChannel.startScan();
  }

  static Future<void>
      stopScan() async {
    await CgmMethodChannel.stopScan();
  }

  static Future<bool> connect(
    String sn, {
    bool autoConnect = false,
  }) async {
    return await CgmMethodChannel
        .connect(
      sn: sn,
      autoConnect: autoConnect,
    );
  }

  static Future<void>
      disconnect() async {
    await CgmMethodChannel
        .disconnect();
  }

  static Future<bool>
      isConnected() async {
    return await CgmMethodChannel
        .isConnected();
  }

  static Future<
          List<Map<String, dynamic>>>
      getHistory(
    String sn, {
    int indexStart = 1,
  }) async {
    final raw =
        await CgmMethodChannel
            .getHistory(
      sn: sn,
      indexStart: indexStart,
    );

    return raw
        .whereType<Map>()
        .map(
          (m) =>
              Map<String, dynamic>.from(
            m,
          ),
        )
        .toList();
  }

  static Future<void>
      startHeartbeat() async {
    await CgmMethodChannel
        .startHeartbeat();
  }

  static Future<void>
      stopHeartbeat() async {
    await CgmMethodChannel
        .stopHeartbeat();
  }

  static Future<bool>
      isBluetoothEnabled() async {
    try {
      return await CgmMethodChannel
          .isBluetoothEnabled();
    } catch (_) {
      return false;
    }
  }
}

/// Convert mmol/L (the SDK's native unit for processedBloodSugar)
/// to mg/dL (what the dashboard renders).
double mmolToMgDl(num mmol) {
  return mmol.toDouble() * 18.0182;
}

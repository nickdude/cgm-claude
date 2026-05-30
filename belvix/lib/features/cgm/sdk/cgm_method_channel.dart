import 'package:flutter/services.dart';

class CgmMethodChannel {
  static const MethodChannel _channel =
      MethodChannel("cgm_sdk/method");

  static Future<void> init() async {
    await _channel.invokeMethod("init");
  }

  static Future<bool> auth({
    required String appId,
    required String appSecret,
  }) async {
    final result =
        await _channel.invokeMethod<bool>(
      "auth",
      {
        "appId": appId,
        "appSecret": appSecret,
      },
    );

    return result ?? false;
  }

  static Future<bool>
      checkAuthorized() async {
    final result =
        await _channel.invokeMethod<bool>(
      "checkAuthorized",
    );

    return result ?? false;
  }

  static Future<void> startScan() async {
    await _channel.invokeMethod(
      "startScan",
    );
  }

  static Future<void> stopScan() async {
    await _channel.invokeMethod(
      "stopScan",
    );
  }

  static Future<bool> connect({
    required String sn,
    bool autoConnect = false,
  }) async {
    final result =
        await _channel.invokeMethod<bool>(
      "connect",
      {
        "sn": sn,
        "autoConnect": autoConnect,
      },
    );

    return result ?? false;
  }

  static Future<void>
      disconnect() async {
    await _channel.invokeMethod(
      "disconnect",
    );
  }

  static Future<bool>
      isConnected() async {
    final result =
        await _channel.invokeMethod<bool>(
      "isConnected",
    );

    return result ?? false;
  }

  static Future<List<dynamic>>
      getHistory({
    required String sn,
    required int indexStart,
  }) async {
    final result = await _channel
        .invokeMethod<List<dynamic>>(
      "getHistory",
      {
        "sn": sn,
        "indexStart": indexStart,
      },
    );

    return result ?? const [];
  }

  static Future<void>
      startHeartbeat() async {
    await _channel.invokeMethod(
      "startHeartbeat",
    );
  }

  static Future<void>
      stopHeartbeat() async {
    await _channel.invokeMethod(
      "stopHeartbeat",
    );
  }

  static Future<bool>
      isBluetoothEnabled() async {
    final v = await _channel
        .invokeMethod<bool>(
      "isBluetoothEnabled",
    );

    return v ?? false;
  }
}

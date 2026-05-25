import 'package:flutter/services.dart';

class CgmMethodChannel {
  static const MethodChannel
      _channel = MethodChannel(
    'cgm_sdk/method',
  );

  static Future<void> init() async {
    await _channel.invokeMethod(
      'init',
    );
  }

  static Future<bool> auth({
    required String appId,
    required String appSecret,
  }) async {
    final result =
        await _channel.invokeMethod(
      'auth',
      {
        'appId': appId,
        'appSecret': appSecret,
      },
    );

    return result ?? false;
  }

  static Future<bool>
      checkAuthorized() async {
    final result =
        await _channel.invokeMethod(
      'checkAuthorized',
    );

    return result ?? false;
  }

  static Future<void>
      startScan() async {
    await _channel.invokeMethod(
      'startScan',
    );
  }

  static Future<void>
      stopScan() async {
    await _channel.invokeMethod(
      'stopScan',
    );
  }

  static Future<bool> connect(
    String sn,
  ) async {
    final result =
        await _channel.invokeMethod(
      'connect',
      {
        'sn': sn,
      },
    );

    return result ?? false;
  }

  static Future<void>
      disconnect() async {
    await _channel.invokeMethod(
      'disconnect',
    );
  }

  static Future<bool>
      isConnected() async {
    final result =
        await _channel.invokeMethod(
      'isConnected',
    );

    return result ?? false;
  }

  static Future<List<dynamic>>
      getHistory({
    required String sn,
    required int indexStart,
  }) async {
    final result =
        await _channel.invokeMethod(
      'getHistory',
      {
        'sn': sn,
        'indexStart': indexStart,
      },
    );

    return result ?? [];
  }
}
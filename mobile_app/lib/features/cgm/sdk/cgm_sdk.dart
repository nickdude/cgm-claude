import 'cgm_event_channel.dart';

import 'cgm_method_channel.dart';

class CgmSdk {
  static Stream<dynamic> get events =>
      CgmEventChannel.events;

  static Future<void> init() async {
    await CgmMethodChannel.init();
  }

  static Future<bool> auth(
    String appId,
    String appSecret,
  ) async {
    return await CgmMethodChannel
        .auth(
      appId: appId,
      appSecret: appSecret,
    );
  }

  static Future<bool>
      checkAuthorized() async {
    return await CgmMethodChannel
        .checkAuthorized();
  }

  static Future<void>
      startScan() async {
    await CgmMethodChannel
        .startScan();
  }

  static Future<void>
      stopScan() async {
    await CgmMethodChannel
        .stopScan();
  }

  static Future<bool> connect(
    String sn,
  ) async {
    return await CgmMethodChannel
        .connect(sn);
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

  static Future<List<dynamic>>
      getHistory(
    String sn,
    int indexStart,
  ) async {
    return await CgmMethodChannel
        .getHistory(
      sn: sn,
      indexStart: indexStart,
    );
  }
}
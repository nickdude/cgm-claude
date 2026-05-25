import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  static const FlutterSecureStorage
      _storage =
      FlutterSecureStorage();

  static const _kToken = "token";

  static const _kUser = "user";

  static const _kProfileCompleted =
      "isProfileCompleted";

  static const _kOnboardingCompleted =
      "isOnboardingCompleted";

  static const _kCgmConnected =
      "isCgmConnected";

  static const _kCgmSn =
      "cgm_last_sn";

  static const _kCgmDeviceName =
      "cgm_last_device_name";

  static const _kCgmManufacturer =
      "cgm_last_manufacturer";

  static const _kCgmAutoReconnect =
      "cgm_auto_reconnect";

  static Future<void> setToken(
    String token,
  ) async {
    await _storage.write(
      key: _kToken,
      value: token,
    );
  }

  static Future<String?>
      getToken() async {
    return await _storage.read(
      key: _kToken,
    );
  }

  static Future<void> setUser(
    Map<String, dynamic> user,
  ) async {
    await _storage.write(
      key: _kUser,
      value: jsonEncode(user),
    );
  }

  static Future<Map<String, dynamic>?>
      getUser() async {
    final raw = await _storage.read(
      key: _kUser,
    );

    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(raw);

      if (decoded
          is Map<String, dynamic>) {
        return decoded;
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<void>
      setProfileCompleted(
    bool value,
  ) async {
    await _storage.write(
      key: _kProfileCompleted,
      value: value.toString(),
    );
  }

  static Future<bool>
      isProfileCompleted() async {
    final v = await _storage.read(
      key: _kProfileCompleted,
    );

    return v == "true";
  }

  static Future<void>
      setOnboardingCompleted(
    bool value,
  ) async {
    await _storage.write(
      key: _kOnboardingCompleted,
      value: value.toString(),
    );
  }

  static Future<bool>
      isOnboardingCompleted() async {
    final v = await _storage.read(
      key: _kOnboardingCompleted,
    );

    return v == "true";
  }

  static Future<void> setCgmConnected(
    bool value,
  ) async {
    await _storage.write(
      key: _kCgmConnected,
      value: value.toString(),
    );
  }

  static Future<bool>
      isCgmConnected() async {
    final v = await _storage.read(
      key: _kCgmConnected,
    );

    return v == "true";
  }

  static Future<void> setCgmSession({
    required String sn,
    required String deviceName,
    required String manufacturer,
    bool autoReconnect = true,
  }) async {
    await _storage.write(
      key: _kCgmSn,
      value: sn,
    );

    await _storage.write(
      key: _kCgmDeviceName,
      value: deviceName,
    );

    await _storage.write(
      key: _kCgmManufacturer,
      value: manufacturer,
    );

    await _storage.write(
      key: _kCgmAutoReconnect,
      value:
          autoReconnect.toString(),
    );
  }

  static Future<
          Map<String, String>?>
      getCgmSession() async {
    final sn = await _storage.read(
      key: _kCgmSn,
    );

    if (sn == null || sn.isEmpty) {
      return null;
    }

    return {
      "sn": sn,
      "deviceName": (await _storage
              .read(
            key: _kCgmDeviceName,
          )) ??
          "CGM Sensor",
      "manufacturer": (await _storage
              .read(
            key: _kCgmManufacturer,
          )) ??
          "Eaglenos",
    };
  }

  static Future<bool>
      getCgmAutoReconnect() async {
    final v = await _storage.read(
      key: _kCgmAutoReconnect,
    );

    // Default true so a session created before this flag existed
    // (or any non-disconnected session) is treated as eligible.
    return v != "false";
  }

  static Future<void>
      setCgmAutoReconnect(
    bool value,
  ) async {
    await _storage.write(
      key: _kCgmAutoReconnect,
      value: value.toString(),
    );
  }

  static Future<void>
      clearCgmSession() async {
    await _storage.delete(
      key: _kCgmSn,
    );

    await _storage.delete(
      key: _kCgmDeviceName,
    );

    await _storage.delete(
      key: _kCgmManufacturer,
    );

    await _storage.delete(
      key: _kCgmAutoReconnect,
    );
  }

  static Future<void> clear() async {
    await _storage.deleteAll();
  }
}

import 'package:flutter/foundation.dart';

import '../datasource/cgm_device_remote_datasource.dart';

import '../models/cgm_device_model.dart';

class CgmDeviceRepository {
  final CgmDeviceRemoteDatasource
      _datasource =
      CgmDeviceRemoteDatasource();

  Future<CGMDeviceModel?>
      connectDevice({
    required String serialNumber,
    required String deviceName,
    required String manufacturer,
  }) async {
    try {
      final res = await _datasource
          .connectDevice(
        serialNumber: serialNumber,
        deviceName: deviceName,
        manufacturer: manufacturer,
      );

      final data = res.data?["data"];

      if (data is Map<String, dynamic>) {
        return CGMDeviceModel.fromJson(
          data,
        );
      }

      return null;
    } catch (e) {
      debugPrint(
        "connectDevice (backend) failed: $e",
      );

      return null;
    }
  }

  Future<CGMDeviceModel?>
      getActiveDevice() async {
    try {
      final res = await _datasource
          .getActiveDevice();

      final data = res.data?["data"];

      if (data is Map<String, dynamic>) {
        return CGMDeviceModel.fromJson(
          data,
        );
      }

      return null;
    } catch (e) {
      debugPrint(
        "getActiveDevice failed: $e",
      );

      return null;
    }
  }
}

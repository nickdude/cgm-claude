import 'package:dio/dio.dart';

import '../../../../../core/network/dio_client.dart';

class CgmDeviceRemoteDatasource {
  final Dio dio = DioClient.dio;

  Future<Response> connectDevice({
    required String serialNumber,
    required String deviceName,
    required String manufacturer,
  }) async {
    return await dio.post(
      "/cgm-device/connect",
      data: {
        "serialNumber":
            serialNumber,
        "deviceName": deviceName,
        "manufacturer":
            manufacturer,
      },
    );
  }

  Future<Response>
      getActiveDevice() async {
    return await dio.get(
      "/cgm-device/active",
    );
  }
}

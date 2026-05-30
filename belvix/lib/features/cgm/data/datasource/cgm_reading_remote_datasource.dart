import 'package:dio/dio.dart';

import '../../../../core/network/dio_client.dart';

class CgmReadingRemoteDatasource {
  final Dio dio = DioClient.dio;

  Future<Response> addReading({
    required double glucoseValue,
    required String trend,
    required DateTime readingAt,
  }) async {
    return await dio.post(
      "/cgm-reading/add",
      data: {
        "glucoseValue": glucoseValue,
        "trend": trend,
        "readingAt":
            readingAt.toIso8601String(),
      },
    );
  }

  Future<Response>
      listReadings() async {
    return await dio.get(
      "/cgm-reading/list",
    );
  }
}

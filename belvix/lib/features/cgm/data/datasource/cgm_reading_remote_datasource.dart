import 'package:dio/dio.dart';

import '../../../../core/network/dio_client.dart';
import '../models/cgm_reading_model.dart';

class CgmReadingRemoteDatasource {
  final Dio dio = DioClient.dio;

  Future<Response> addReading({
    required double glucoseValue,
    required String trend,
    required DateTime readingAt,
    String? sensorSerial,
    int? sequenceNumber,
  }) async {
    return await dio.post(
      "/cgm-reading/add",
      data: {
        "glucoseValue": glucoseValue,
        "trend": trend,
        "readingAt":
            readingAt.toIso8601String(),
        if (sensorSerial != null)
          "sensorSerial": sensorSerial,
        if (sequenceNumber != null)
          "sequenceNumber": sequenceNumber,
      },
    );
  }

  /// One round-trip idempotent upsert of a whole batch — used by the reconnect
  /// backfill so a multi-hour buffer isn't N sequential POSTs.
  Future<Response> addReadingsBulk(
    List<CgmReadingModel> readings,
  ) async {
    return await dio.post(
      "/cgm-reading/bulk",
      data: {
        "readings": readings
            .map((r) => r.toJson())
            .toList(),
      },
    );
  }

  /// Highest stored sequence for [sensorSerial] — the restart-safe checkpoint
  /// the app backfills from.
  Future<Response> getCheckpoint(
    String sensorSerial,
  ) async {
    return await dio.get(
      "/cgm-reading/checkpoint",
      queryParameters: {
        "sn": sensorSerial,
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

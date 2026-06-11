import 'package:flutter/foundation.dart';

import '../datasource/cgm_reading_remote_datasource.dart';

import '../models/cgm_reading_model.dart';

class CgmReadingRepository {
  final CgmReadingRemoteDatasource
      _datasource =
      CgmReadingRemoteDatasource();

  Future<CgmReadingModel?> addReading({
    required double glucoseValue,
    required String trend,
    required DateTime readingAt,
    String? sensorSerial,
    int? sequenceNumber,
  }) async {
    try {
      final res = await _datasource
          .addReading(
        glucoseValue: glucoseValue,
        trend: trend,
        readingAt: readingAt,
        sensorSerial: sensorSerial,
        sequenceNumber: sequenceNumber,
      );

      final data = res.data?["data"];

      if (data is Map<String, dynamic>) {
        return CgmReadingModel.fromJson(
          data,
        );
      }

      return null;
    } catch (e) {
      debugPrint(
        "addReading failed: $e",
      );

      return null;
    }
  }

  /// Idempotent bulk upsert. Returns the stored rows (backend = source of
  /// truth), or `null` on failure so the caller can fall back / retry.
  Future<List<CgmReadingModel>?> addReadingsBulk(
    List<CgmReadingModel> readings,
  ) async {
    if (readings.isEmpty) return const [];

    try {
      final res = await _datasource
          .addReadingsBulk(readings);

      final raw = res.data?["data"];

      if (raw is! List) return const [];

      return raw
          .whereType<Map>()
          .map(
            (m) => CgmReadingModel.fromJson(
              Map<String, dynamic>.from(m),
            ),
          )
          .toList();
    } catch (e) {
      debugPrint("addReadingsBulk failed: $e");

      return null;
    }
  }

  /// Highest sequence number the backend already holds for [sensorSerial].
  /// Returns 0 when none / on error (→ backfill everything).
  Future<int> getCheckpoint(
    String sensorSerial,
  ) async {
    try {
      final res = await _datasource
          .getCheckpoint(sensorSerial);

      final data = res.data?["data"];

      if (data is Map) {
        return (data["maxSequence"] as num? ?? 0)
            .toInt();
      }

      return 0;
    } catch (e) {
      debugPrint("getCheckpoint failed: $e");

      return 0;
    }
  }

  Future<List<CgmReadingModel>>
      listReadings() async {
    try {
      final res = await _datasource
          .listReadings();

      final raw = res.data?["data"];

      if (raw is! List) return const [];

      return raw
          .whereType<Map>()
          .map(
            (m) =>
                CgmReadingModel.fromJson(
              Map<String, dynamic>.from(
                m,
              ),
            ),
          )
          .toList();
    } catch (e) {
      debugPrint(
        "listReadings failed: $e",
      );

      return const [];
    }
  }
}

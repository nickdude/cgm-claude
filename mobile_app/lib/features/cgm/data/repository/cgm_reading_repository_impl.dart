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
  }) async {
    try {
      final res = await _datasource
          .addReading(
        glucoseValue: glucoseValue,
        trend: trend,
        readingAt: readingAt,
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

import 'package:flutter/foundation.dart';

import '../datasource/finger_blood_remote_datasource.dart';
import '../models/finger_blood_model.dart';

class FingerBloodRepository {
  final FingerBloodRemoteDatasource _datasource =
      FingerBloodRemoteDatasource();

  Future<List<FingerBloodModel>> list() async {
    try {
      final res = await _datasource.list();
      final raw = res.data?["data"];
      if (raw is! List) return const [];
      return raw
          .whereType<Map>()
          .map((m) => FingerBloodModel.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    } catch (e) {
      debugPrint("FingerBlood list failed: $e");
      return const [];
    }
  }

  Future<FingerBloodModel?> create(FingerBloodModel reading) async {
    try {
      final res = await _datasource.create(reading.toCreateJson());
      final data = res.data?["data"];
      if (data is Map<String, dynamic>) {
        return FingerBloodModel.fromJson(data);
      }
      return null;
    } catch (e) {
      debugPrint("FingerBlood create failed: $e");
      return null;
    }
  }

  Future<FingerBloodModel?> update(String id, FingerBloodModel reading) async {
    try {
      final res = await _datasource.update(id, reading.toCreateJson());
      final data = res.data?["data"];
      if (data is Map<String, dynamic>) {
        return FingerBloodModel.fromJson(data);
      }
      return null;
    } catch (e) {
      debugPrint("FingerBlood update failed: $e");
      return null;
    }
  }

  Future<bool> delete(String id) async {
    try {
      await _datasource.delete(id);
      return true;
    } catch (e) {
      debugPrint("FingerBlood delete failed: $e");
      return false;
    }
  }
}

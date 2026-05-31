import 'package:flutter/foundation.dart';

import '../datasource/insulin_remote_datasource.dart';
import '../models/insulin_model.dart';

class InsulinRepository {
  final InsulinRemoteDatasource _datasource = InsulinRemoteDatasource();

  Future<List<InsulinModel>> list() async {
    try {
      final res = await _datasource.list();
      final raw = res.data?["data"];
      if (raw is! List) return const [];
      return raw
          .whereType<Map>()
          .map((m) => InsulinModel.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    } catch (e) {
      debugPrint("Insulin list failed: $e");
      return const [];
    }
  }

  Future<InsulinModel?> create(InsulinModel insulin) async {
    try {
      final res = await _datasource.create(insulin.toCreateJson());
      final data = res.data?["data"];
      if (data is Map<String, dynamic>) {
        return InsulinModel.fromJson(data);
      }
      return null;
    } catch (e) {
      debugPrint("Insulin create failed: $e");
      return null;
    }
  }

  Future<bool> delete(String id) async {
    try {
      await _datasource.delete(id);
      return true;
    } catch (e) {
      debugPrint("Insulin delete failed: $e");
      return false;
    }
  }
}

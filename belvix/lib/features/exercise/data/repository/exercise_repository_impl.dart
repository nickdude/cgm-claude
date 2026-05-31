import 'package:flutter/foundation.dart';

import '../datasource/exercise_remote_datasource.dart';
import '../models/exercise_model.dart';

class ExerciseRepository {
  final ExerciseRemoteDatasource _datasource = ExerciseRemoteDatasource();

  Future<List<ExerciseModel>> list() async {
    try {
      final res = await _datasource.list();
      final raw = res.data?["data"];
      if (raw is! List) return const [];
      return raw
          .whereType<Map>()
          .map((m) => ExerciseModel.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    } catch (e) {
      debugPrint("Exercise list failed: $e");
      return const [];
    }
  }

  Future<ExerciseModel?> create(ExerciseModel exercise) async {
    try {
      final res = await _datasource.create(exercise.toCreateJson());
      final data = res.data?["data"];
      if (data is Map<String, dynamic>) {
        return ExerciseModel.fromJson(data);
      }
      return null;
    } catch (e) {
      debugPrint("Exercise create failed: $e");
      return null;
    }
  }

  Future<bool> delete(String id) async {
    try {
      await _datasource.delete(id);
      return true;
    } catch (e) {
      debugPrint("Exercise delete failed: $e");
      return false;
    }
  }
}

import 'package:flutter/foundation.dart';

import '../datasource/food_remote_datasource.dart';
import '../models/food_model.dart';

class FoodRepository {
  final FoodRemoteDatasource _datasource = FoodRemoteDatasource();

  Future<List<FoodModel>> list() async {
    try {
      final res = await _datasource.list();
      final raw = res.data?["data"];
      if (raw is! List) return const [];
      return raw
          .whereType<Map>()
          .map((m) => FoodModel.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    } catch (e) {
      debugPrint("Food list failed: $e");
      return const [];
    }
  }

  Future<FoodModel?> create(FoodModel food) async {
    try {
      final res = await _datasource.create(food.toCreateJson());
      final data = res.data?["data"];
      if (data is Map<String, dynamic>) {
        return FoodModel.fromJson(data);
      }
      return null;
    } catch (e) {
      debugPrint("Food create failed: $e");
      return null;
    }
  }

  Future<FoodModel?> update(String id, FoodModel food) async {
    try {
      final res = await _datasource.update(id, food.toCreateJson());
      final data = res.data?["data"];
      if (data is Map<String, dynamic>) {
        return FoodModel.fromJson(data);
      }
      return null;
    } catch (e) {
      debugPrint("Food update failed: $e");
      return null;
    }
  }

  Future<bool> delete(String id) async {
    try {
      await _datasource.delete(id);
      return true;
    } catch (e) {
      debugPrint("Food delete failed: $e");
      return false;
    }
  }
}

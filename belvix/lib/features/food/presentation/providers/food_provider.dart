import 'package:flutter/material.dart';

import '../../data/models/food_model.dart';
import '../../data/repository/food_repository_impl.dart';

class FoodProvider extends ChangeNotifier {
  final FoodRepository _repository = FoodRepository();

  bool isLoading = false;

  List<FoodModel> foods = [];

  Future<void> fetchFoods() async {
    isLoading = true;
    notifyListeners();

    foods = await _repository.list();

    isLoading = false;
    notifyListeners();
  }

  Future<bool> addFood({
    required String title,
    required int calories,
    required int carbs,
    int protein = 0,
    int fat = 0,
    int fiber = 0,
    DateTime? loggedAt,
  }) async {
    final created = await _repository.create(
      FoodModel(
        id: "",
        title: title,
        calories: calories,
        carbs: carbs,
        protein: protein,
        fat: fat,
        fiber: fiber,
        loggedAt: loggedAt ?? DateTime.now(),
      ),
    );

    if (created == null) return false;

    foods.insert(0, created);
    notifyListeners();
    return true;
  }

  Future<bool> updateFood({
    required String id,
    required String title,
    required int calories,
    required int carbs,
    int protein = 0,
    int fat = 0,
    int fiber = 0,
    DateTime? loggedAt,
  }) async {
    final updated = await _repository.update(
      id,
      FoodModel(
        id: id,
        title: title,
        calories: calories,
        carbs: carbs,
        protein: protein,
        fat: fat,
        fiber: fiber,
        loggedAt: loggedAt ?? DateTime.now(),
      ),
    );

    if (updated == null) return false;

    final index = foods.indexWhere((f) => f.id == id);
    if (index != -1) {
      foods[index] = updated;
    } else {
      foods.insert(0, updated);
    }
    notifyListeners();
    return true;
  }

  Future<bool> deleteFood(String id) async {
    final ok = await _repository.delete(id);
    if (ok) {
      foods.removeWhere((f) => f.id == id);
      notifyListeners();
    }
    return ok;
  }
}

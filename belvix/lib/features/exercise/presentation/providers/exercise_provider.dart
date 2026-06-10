import 'package:flutter/material.dart';

import '../../data/models/exercise_model.dart';
import '../../data/repository/exercise_repository_impl.dart';

class ExerciseProvider extends ChangeNotifier {
  final ExerciseRepository _repository = ExerciseRepository();

  bool isLoading = false;

  List<ExerciseModel> exercises = [];

  Future<void> fetchExercises() async {
    isLoading = true;
    notifyListeners();

    exercises = await _repository.list();

    isLoading = false;
    notifyListeners();
  }

  Future<bool> addExercise({
    required String title,
    required int duration,
    required int caloriesBurned,
    DateTime? loggedAt,
  }) async {
    final created = await _repository.create(
      ExerciseModel(
        id: "",
        title: title,
        duration: duration,
        caloriesBurned: caloriesBurned,
        loggedAt: loggedAt ?? DateTime.now(),
      ),
    );

    if (created == null) return false;

    exercises.insert(0, created);
    notifyListeners();
    return true;
  }

  Future<bool> updateExercise({
    required String id,
    required String title,
    required int duration,
    required int caloriesBurned,
    DateTime? loggedAt,
  }) async {
    final updated = await _repository.update(
      id,
      ExerciseModel(
        id: id,
        title: title,
        duration: duration,
        caloriesBurned: caloriesBurned,
        loggedAt: loggedAt ?? DateTime.now(),
      ),
    );

    if (updated == null) return false;

    final index = exercises.indexWhere((e) => e.id == id);
    if (index != -1) {
      exercises[index] = updated;
    } else {
      exercises.insert(0, updated);
    }
    notifyListeners();
    return true;
  }

  Future<bool> deleteExercise(String id) async {
    final ok = await _repository.delete(id);
    if (ok) {
      exercises.removeWhere((e) => e.id == id);
      notifyListeners();
    }
    return ok;
  }
}

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
  }) async {
    final created = await _repository.create(
      ExerciseModel(
        id: "",
        title: title,
        duration: duration,
        caloriesBurned: caloriesBurned,
        loggedAt: DateTime.now(),
      ),
    );

    if (created == null) return false;

    exercises.insert(0, created);
    notifyListeners();
    return true;
  }

  Future<void> deleteExercise(String id) async {
    final ok = await _repository.delete(id);
    if (ok) {
      exercises.removeWhere((e) => e.id == id);
      notifyListeners();
    }
  }
}

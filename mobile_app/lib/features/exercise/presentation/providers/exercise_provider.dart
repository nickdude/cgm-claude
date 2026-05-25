import 'package:flutter/material.dart';

import '../../data/models/exercise_model.dart';
import '../../../../core/constants/app_globals.dart';

class ExerciseProvider
    extends ChangeNotifier {
  List<ExerciseModel> exercises =
      [];

  Future<void> fetchExercises() async {
    exercises = [
      ExerciseModel(
        id: "1",

        title: "Morning Walk",

        duration: 30,

        caloriesBurned: 180,

        image: "",

        time: "07:30 AM",
      ),

      ExerciseModel(
        id: "2",

        title: "Gym Workout",

        duration: 60,

        caloriesBurned: 420,

        image: "",

        time: "06:00 PM",
      ),
    ];

    notifyListeners();
  }

  Future<void> addExercise({
    required String title,
    required int duration,
    required int caloriesBurned,
  }) async {
    exercises.insert(
      0,
      ExerciseModel(
        id: DateTime.now()
            .toString(),

        title: title,

        duration: duration,

        caloriesBurned:
            caloriesBurned,

        image: "",

        time: TimeOfDay.now()
            .format(
          navigatorKey
              .currentContext!,
        ),
      ),
    );

    notifyListeners();
  }
}

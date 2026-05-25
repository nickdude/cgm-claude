import 'package:flutter/material.dart';

import '../../data/models/food_model.dart';

import '../../../../core/constants/app_globals.dart';

class FoodProvider
    extends ChangeNotifier {
  bool isLoading = false;

  List<FoodModel> foods = [];

  Future<void> fetchFoods() async {
    foods = [
      FoodModel(
        id: "1",

        title: "Apple",

        calories: 95,

        carbs: 25,

        image: "",

        time: "08:30 AM",
      ),

      FoodModel(
        id: "2",

        title: "Rice Bowl",

        calories: 220,

        carbs: 45,

        image: "",

        time: "01:00 PM",
      ),
    ];

    notifyListeners();
  }

  Future<void> addFood({
    required String title,
    required int calories,
    required int carbs,
  }) async {
    foods.insert(
      0,
      FoodModel(
        id: DateTime.now()
            .toString(),

        title: title,

        calories: calories,

        carbs: carbs,

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
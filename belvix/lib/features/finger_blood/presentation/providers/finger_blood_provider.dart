import 'package:flutter/material.dart';

import '../../data/models/finger_blood_model.dart';

import '../../../../core/constants/app_globals.dart';

class FingerBloodProvider
    extends ChangeNotifier {
  List<FingerBloodModel>
      fingerBloods = [];

  Future<void> fetchFingerBloods() async {
    fingerBloods = [
      FingerBloodModel(
        id: "1",

        glucoseValue: 118,

        notes:
            "Before Breakfast",

        time: "08:10 AM",
      ),

      FingerBloodModel(
        id: "2",

        glucoseValue: 145,

        notes:
            "After Lunch",

        time: "02:00 PM",
      ),
    ];

    notifyListeners();
  }

  Future<void> addFingerBlood({
    required int glucoseValue,
    required String notes,
  }) async {
    fingerBloods.insert(
      0,
      FingerBloodModel(
        id: DateTime.now()
            .toString(),

        glucoseValue:
            glucoseValue,

        notes: notes,

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

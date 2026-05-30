import 'package:flutter/material.dart';

import '../../data/models/insulin_model.dart';

import '../../../../core/constants/app_globals.dart';

class InsulinProvider
    extends ChangeNotifier {
  List<InsulinModel> insulins =
      [];

  Future<void> fetchInsulins() async {
    insulins = [
      InsulinModel(
        id: "1",

        insulinType: "Rapid",

        dosage: 5,

        time: "08:00 AM",
      ),

      InsulinModel(
        id: "2",

        insulinType: "Long Acting",

        dosage: 12,

        time: "10:00 PM",
      ),
    ];

    notifyListeners();
  }

  Future<void> addInsulin({
    required String insulinType,
    required int dosage,
  }) async {
    insulins.insert(
      0,
      InsulinModel(
        id: DateTime.now()
            .toString(),

        insulinType:
            insulinType,

        dosage: dosage,

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
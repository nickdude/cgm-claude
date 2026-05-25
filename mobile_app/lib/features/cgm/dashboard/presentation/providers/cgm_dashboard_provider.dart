import 'dart:async';

import 'package:fl_chart/fl_chart.dart';

import 'package:flutter/material.dart';

import '../../../../../core/services/notification_service.dart';

class CGMDashboardProvider
    extends ChangeNotifier {

  int glucose = 120;

  String trend = "Stable";

  bool syncing = true;

  bool showAlert = false;

  String alertMessage = "";

  Color alertColor = Colors.red;

  DateTime? lastNotificationTime;

  Timer? timer;

  List<FlSpot> glucoseSpots = [
    const FlSpot(0, 120),
    const FlSpot(1, 122),
    const FlSpot(2, 124),
    const FlSpot(3, 121),
    const FlSpot(4, 126),
  ];

  void startRealtimeUpdates() {
    timer?.cancel();

    timer = Timer.periodic(
      const Duration(seconds: 5),
      (timer) {
        glucose +=
            [-30, -15, 10, 25, 40]
                .elementAt(
          DateTime.now()
                  .second %
              5,
        );

        showAlert = false;

        if (glucose < 70) {
          trend = "Low";

          showAlert = true;

          alertMessage =
              "Low glucose detected";

          alertColor = Colors.red;

          sendAlertNotification(
            title:
                "Low Glucose Alert",

            body:
                "Your glucose is below safe range.",
          );
        } else if (glucose >
            180) {
          trend = "High";

          showAlert = true;

          alertMessage =
              "High glucose detected";

          alertColor =
              Colors.orange;

          sendAlertNotification(
            title:
                "High Glucose Alert",

            body:
                "Your glucose is above safe range.",
          );
        } else {
          trend = "Stable";
        }

        final nextX =
            glucoseSpots.isEmpty
                ? 0
                : glucoseSpots
                        .last
                        .x +
                    1;

        glucoseSpots.add(
          FlSpot(
            nextX.toDouble(),
            glucose.toDouble(),
          )
        );

        if (glucoseSpots.length >
            15) {
          glucoseSpots.removeAt(
            0,
          );
        }

        syncing = false;

        notifyListeners();
      },
    );
  }

  Future<void>
      sendAlertNotification({
    required String title,
    required String body,
  }) async {
    final now = DateTime.now();

    if (lastNotificationTime !=
            null &&
        now
                .difference(
                  lastNotificationTime!,
                )
                .inSeconds <
            30) {
      return;
    }

    lastNotificationTime = now;

    await NotificationService
        .showNotification(
      title: title,
      body: body,
    );
  }

  void stopUpdates() {
    timer?.cancel();
  }

  @override
  void dispose() {
    timer?.cancel();

    super.dispose();
  }
}
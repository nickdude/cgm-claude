import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/models/cgm_device_model.dart';

enum CGMConnectionStatus {
  disconnected,
  connecting,
  warmup,
  syncing,
  active,
  expired,
}

class CGMProvider
    extends ChangeNotifier {
  List<CGMDeviceModel> devices =
      [];

  CGMDeviceModel? activeDevice;

  CGMConnectionStatus
      connectionStatus =
      CGMConnectionStatus
          .disconnected;

  double syncProgress = 0;

  Timer? syncTimer;

  Future<void> fetchDevices() async {
    devices = [
      CGMDeviceModel(
        id: "1",

        serialNumber: "SN123456",

        deviceName:
            "Libre Sensor",

        manufacturer:
            "Abbott",

        isActive: true,

        connectedAt:
            DateTime.now().subtract(
          const Duration(days: 2),
        ),

        expiresAt:
            DateTime.now().add(
          const Duration(days: 12),
        ),
      ),
    ];

    activeDevice = devices.first;

    connectionStatus =
        CGMConnectionStatus.active;

    notifyListeners();
  }

  Future<void> connectDevice({
    required String serialNumber,
    required String deviceName,
    required String manufacturer,
  }) async {
    connectionStatus =
        CGMConnectionStatus
            .connecting;

    notifyListeners();

    await Future.delayed(
      const Duration(seconds: 2),
    );

    final device =
        CGMDeviceModel(
      id: DateTime.now().toString(),

      serialNumber: serialNumber,

      deviceName: deviceName,

      manufacturer: manufacturer,

      isActive: true,

      connectedAt: DateTime.now(),

      expiresAt:
          DateTime.now().add(
        const Duration(days: 14),
      ),
    );

    devices.insert(0, device);

    activeDevice = device;

    connectionStatus =
        CGMConnectionStatus.warmup;

    notifyListeners();

    await Future.delayed(
      const Duration(seconds: 5),
    );

    startSyncing();
  }

  void startSyncing() {
    connectionStatus =
        CGMConnectionStatus.syncing;

    syncProgress = 0;

    notifyListeners();

    syncTimer = Timer.periodic(
      const Duration(milliseconds: 500),
      (timer) {
        syncProgress += 0.1;

        if (syncProgress >= 1) {
          syncProgress = 1;

          connectionStatus =
              CGMConnectionStatus
                  .active;

          timer.cancel();
        }

        notifyListeners();
      },
    );
  }

  Future<void> switchDevice(
    CGMDeviceModel device,
  ) async {
    activeDevice = device;

    notifyListeners();
  }

  String get connectionText {
    switch (connectionStatus) {
      case CGMConnectionStatus
            .connecting:
        return "Connecting";

      case CGMConnectionStatus
            .warmup:
        return "Sensor Warmup";

      case CGMConnectionStatus
            .syncing:
        return "Syncing Readings";

      case CGMConnectionStatus
            .active:
        return "Sensor Active";

      case CGMConnectionStatus
            .expired:
        return "Sensor Expired";

      default:
        return "Disconnected";
    }
  }

  Color get statusColor {
    switch (connectionStatus) {
      case CGMConnectionStatus
            .active:
        return Colors.green;

      case CGMConnectionStatus
            .warmup:
        return Colors.orange;

      case CGMConnectionStatus
            .syncing:
        return Colors.blue;

      case CGMConnectionStatus
            .expired:
        return Colors.red;

      default:
        return Colors.grey;
    }
  }

  @override
  void dispose() {
    syncTimer?.cancel();

    super.dispose();
  }
}
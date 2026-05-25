# CGM Integration Guide

This guide shows how to integrate the CGM SDK into a real Flutter app using the `CgmSdk` wrapper that already exists in this project.

## What You Get

- Bluetooth permission handling
- SDK initialization and authorization
- Sensor scan/connect/disconnect flow
- Live event stream for glucose updates and device state
- History retrieval by sensor SN

## Recommended App Flow

1. Request Bluetooth permissions.
2. Initialize the SDK.
3. Authenticate the app.
4. Start scan or connect directly with the sensor SN.
5. Listen to `CgmSdk.events` for live updates.
6. Load history.

## Flutter Setup

Import the SDK wrapper:

```dart
import 'package:cgm_app/cgm_sdk.dart';
```

## Core API

### 1) Request permissions

```dart
final granted = await CgmSdk.requestPermissions();
```

Use this before scan/connect on Android and iOS.

### 2) Initialize the SDK

```dart
await CgmSdk.init();
```

Call this once during app startup.

### 3) Authenticate

```dart
final success = await CgmSdk.auth(appId, appSecret);
```

There is also a labeled helper if you want better logs while testing multiple credential pairs:

```dart
final success = await CgmSdk.authWithLabel('primary', appId, appSecret);
```

### 4) Check authorization

```dart
final authorized = await CgmSdk.checkAuthorized();
```

### 5) Scan for devices

```dart
await CgmSdk.startScan();
await CgmSdk.stopScan();
```

### 6) Connect to a sensor

```dart
final connected = await CgmSdk.connect('50101990');
```

The SN should match the sensor/device code expected by your CGM backend.

### 7) Disconnect

```dart
await CgmSdk.disconnect();
```

### 8) Check current connection state

```dart
final connected = await CgmSdk.isConnected();
```

### 9) Load history

```dart
final history = await CgmSdk.getHistory('50101990', 0);
```

The second argument is the starting index for the history query.

## Live Events

Listen to the broadcast stream to react to realtime updates:

```dart
final subscription = CgmSdk.events.listen((event) {
  print(event);
});
```

Cancel the subscription in `dispose()`:

```dart
await subscription.cancel();
```

## Event Types

The event stream may emit the following `type` values:

- `glucoseData`
- `deviceInfo`
- `scanResult`
- `connected`
- `disconnected`
- `error`
- `scanStarted`
- `scanStopped`
- `syncProgress`
- `log`
- `bindStep`

## Event Payloads

### `glucoseData`

Contains the current batch of readings.

Typical fields:

- `type`
- `isAbandoned`
- `isErrorShow`
- `abnormalStates`
- `bloodSugars`

Each item in `bloodSugars` typically includes:

- `originalBloodSugar`
- `processedBloodSugar`
- `createTime`
- `timeOffset`
- `trend`

### `deviceInfo`

Typical fields you may see from the native layer:

- `type`
- `sn`
- `firmwareVersion`
- `measurementInterval`
- `isPreheating`
- `isInUse`
- `isExpired`
- `timeOffset`
- `deviceActivateTimestamp`

### `scanResult`

Typical fields:

- `type`
- `deviceName`
- `deviceAddress`
- `rssi`

### `error`

Typical fields:

- `type`
- `error`
- `sn` or `errorCode` depending on the native path

## Example Integration Pattern

```dart
class CgmService {
  StreamSubscription? _subscription;

  Future<void> start() async {
    await CgmSdk.requestPermissions();
    await CgmSdk.init();
    await CgmSdk.auth(appId, appSecret);

    _subscription = CgmSdk.events.listen((event) {
      final type = event['type'];

      switch (type) {
        case 'glucoseData':
          final readings = (event['bloodSugars'] as List? ?? [])
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
          // Update UI/state with the new readings.
          break;
        case 'deviceInfo':
          // Cache device metadata.
          break;
        case 'connected':
          // Mark the device connected.
          break;
        case 'disconnected':
          // Mark the device disconnected.
          break;
        case 'error':
          // Show error message.
          break;
      }
    });
  }

  Future<void> connectSensor(String sn) async {
    await CgmSdk.connect(sn);
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    await CgmSdk.disconnect();
  }
}
```

## Displaying Glucose Values

The native payload may return glucose values in the SDK’s original unit. In this app, readings are displayed in mg/dL by converting with:

```dart
double? mmolToMgDl(double? value) {
  if (value == null) return null;
  return value * 18.0182;
}
```

If your target app wants to show mmol/L instead, skip the conversion and format directly from `processedBloodSugar`.

## Practical UI Notes

- Treat `glucoseData` as realtime updates, not just history.
- Sort readings by `createTime` before charting them.
- Merge incoming batches instead of replacing existing points blindly.
- Use a warm-up countdown if the device sends `deviceActivateTimestamp`.
- Show a visible connection state, last scan/connect timestamps, and alert banners for low/high glucose.

## Troubleshooting

### No realtime updates

- Confirm `CgmSdk.events` is being listened to before connecting.
- Verify scan/connect succeeds and the device is not already attached to another app.
- Check that Bluetooth permissions are granted.

### Connection fails with GATT 133

- This usually means the device is out of range, busy, or still attached to another app.
- Disconnect from the original app completely and retry after a short wait.

### Values look stale

- Make sure you are not overwriting the current list with an empty batch.
- Merge and sort readings by `createTime`.

## Suggested File Usage

A common pattern is to keep this guide next to your app code and reuse the helper methods from `cgm_sdk.dart` inside a dedicated service or repository class.

---

If you want, I can also create a ready-to-paste `cgm_service.dart` file that wraps the SDK into a clean production-style service layer for your real app.

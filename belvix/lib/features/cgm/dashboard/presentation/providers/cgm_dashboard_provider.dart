import 'dart:async';

import 'package:fl_chart/fl_chart.dart';

import 'package:flutter/material.dart';

import '../../../../../core/services/notification_service.dart';

import '../../../data/models/cgm_reading_model.dart';

import '../../../data/repository/cgm_reading_repository_impl.dart';

import '../../../sdk/cgm_sdk.dart';

/// Drives the CGM dashboard from real sensor data.
///
/// Data sources (in priority):
///  1. Live SDK `glucoseData` events. Every reading is POSTed to the
///     backend and added to local state.
///  2. Backend `/api/cgm-reading/list` on mount, so the chart shows the
///     user's persisted history immediately.
///
/// There is no synthetic data. If no readings exist, the dashboard
/// shows an empty/waiting state via [hasReadings].
class CGMDashboardProvider
    extends ChangeNotifier {
  /// Latest glucose in mg/dL, null while we wait for the first reading.
  int? glucose;

  String trend = "Stable";

  /// Time of latest reading (for "x min ago" UI).
  DateTime? lastReadingAt;

  bool isLoadingHistory = false;

  bool showAlert = false;

  String alertMessage = "";

  Color alertColor = Colors.red;

  DateTime? lastNotificationTime;

  StreamSubscription? _sdkSubscription;

  final CgmReadingRepository
      _repository =
      CgmReadingRepository();

  /// Ordered oldest → newest; used directly by the chart and by
  /// aggregations (time-in-range, average).
  List<CgmReadingModel> readings = const [];

  List<FlSpot> get glucoseSpots {
    if (readings.isEmpty) {
      return const [];
    }

    final spots = <FlSpot>[];

    for (var i = 0; i < readings.length; i++) {
      spots.add(
        FlSpot(
          i.toDouble(),
          readings[i].glucoseValue,
        ),
      );
    }

    return spots;
  }

  bool get hasReadings =>
      readings.isNotEmpty;

  void startRealtimeUpdates() {
    _attachSdkStream();

    _loadHistoryFromBackend();
  }

  Future<void>
      _loadHistoryFromBackend() async {
    isLoadingHistory = true;

    notifyListeners();

    final fetched = await _repository
        .listReadings();

    // Backend returns newest first; we want oldest → newest for the chart.
    fetched.sort(
      (a, b) => a.readingAt.compareTo(
        b.readingAt,
      ),
    );

    // Keep readings from the last 7 days so the per-day filter on
    // the dashboard week strip has data for every visible weekday.
    readings = _capToWindow(fetched);

    if (readings.isNotEmpty) {
      final latest = readings.last;

      glucose =
          latest.glucoseValue.round();

      trend = latest.trend;

      lastReadingAt = latest.readingAt;

      _updateAlerts();
    }

    isLoadingHistory = false;

    notifyListeners();
  }

  void _attachSdkStream() {
    _sdkSubscription?.cancel();

    try {
      _sdkSubscription =
          CgmSdk.events.listen(
        _onSdkEvent,
        onError: (_) {},
        cancelOnError: false,
      );
    } catch (_) {
      // Native side missing — UI will simply stay in empty state.
    }
  }

  void _onSdkEvent(
    Map<String, dynamic> event,
  ) {
    if (event["type"] !=
        "glucoseData") {
      return;
    }

    final raw = (event["bloodSugars"]
            as List?) ??
        const [];

    if (raw.isEmpty) {
      return;
    }

    // Convert SDK readings → typed local model.
    final incoming =
        <CgmReadingModel>[];

    for (final r in raw) {
      if (r is! Map) continue;

      final m = Map<String,
          dynamic>.from(r);

      final processed = (m[
          "processedBloodSugar"] as num?);

      if (processed == null) continue;

      final mgdl =
          mmolToMgDl(processed);

      final nowMs = DateTime.now()
          .millisecondsSinceEpoch;

      final rawCreate =
          (m["createTime"] as num?)
              ?.toInt();

      // The SDK sometimes returns createTime near the unix epoch
      // (e.g. on synthetic/early readings before the sensor has a
      // clock sync). Treat anything older than 2020 as invalid and
      // stamp it with receive-time.
      const sane = 1577836800000; // 2020-01-01 UTC

      final createMs = rawCreate ==
                  null ||
              rawCreate < sane
          ? nowMs
          : rawCreate;

      incoming.add(
        CgmReadingModel(
          glucoseValue: mgdl,
          trend: _trendLabel(
            (m["trend"] as num?)
                ?.toInt(),
          ),
          readingAt: DateTime
              .fromMillisecondsSinceEpoch(
            createMs,
          ),
        ),
      );
    }

    if (incoming.isEmpty) return;

    _mergeReadings(incoming);

    final latest = readings.last;

    glucose =
        latest.glucoseValue.round();

    trend = latest.trend;

    lastReadingAt = latest.readingAt;

    _updateAlerts();

    notifyListeners();

    // Persist each new reading to the backend.
    for (final r in incoming) {
      _repository.addReading(
        glucoseValue: r.glucoseValue,
        trend: r.trend,
        readingAt: r.readingAt,
      );
    }
  }

  void _mergeReadings(
    List<CgmReadingModel> incoming,
  ) {
    // Dedupe by backend id when present (each row in the DB is
    // distinct), and by `${ms}_${value}` for not-yet-persisted local
    // readings — this is precise enough to drop true duplicates while
    // preserving distinct readings that share a millisecond timestamp.
    final byKey =
        <String, CgmReadingModel>{};

    String keyOf(CgmReadingModel r) {
      if (r.id != null && r.id!.isNotEmpty) {
        return 'id:${r.id}';
      }
      return 'ts:${r.readingAt.millisecondsSinceEpoch}_${r.glucoseValue}';
    }

    for (final r in readings) {
      byKey[keyOf(r)] = r;
    }

    for (final r in incoming) {
      byKey[keyOf(r)] = r;
    }

    final merged = byKey.values
        .toList()
      ..sort(
        (a, b) =>
            a.readingAt.compareTo(
          b.readingAt,
        ),
      );

    readings = _capToWindow(merged);
  }

  /// Trims [all] to readings inside the last 7 days, with a 5000-entry
  /// hard safety cap to bound memory. Older readings drop off so the
  /// dashboard's week strip + per-day chart stay accurate without
  /// growing the list forever.
  List<CgmReadingModel> _capToWindow(
    List<CgmReadingModel> all,
  ) {
    if (all.isEmpty) return const [];

    final now = DateTime.now();
    final cutoff = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 6));

    final windowed = all
        .where(
          (r) => !r.readingAt.isBefore(cutoff),
        )
        .toList();

    // If the backend has only historical readings and none in the
    // last week (e.g. fresh-installed app + test data), fall back to
    // showing whatever we have so the screen isn't blank.
    final result = windowed.isEmpty ? all : windowed;

    // The 7-day window is the natural bound (~7×288=2k for a real
    // sensor). Hard cap is just a runaway-data guardrail; when it
    // trips we downsample evenly across the list so the oldest days
    // don't get evicted.
    const hardCap = 4000;
    if (result.length <= hardCap) {
      return result;
    }

    final step = result.length / hardCap;
    final sampled = <CgmReadingModel>[];
    var i = 0.0;
    while (i < result.length) {
      sampled.add(result[i.toInt()]);
      i += step;
    }
    return sampled;
  }

  void _updateAlerts() {
    showAlert = false;

    if (glucose == null) return;

    if (glucose! < 70) {
      showAlert = true;
      alertMessage =
          "Low glucose detected";
      alertColor = Colors.red;

      _maybeNotify(
        title: "Low Glucose Alert",
        body:
            "Your glucose is below safe range.",
      );
    } else if (glucose! > 180) {
      showAlert = true;
      alertMessage =
          "High glucose detected";
      alertColor = Colors.orange;

      _maybeNotify(
        title: "High Glucose Alert",
        body:
            "Your glucose is above safe range.",
      );
    }
  }

  String _trendLabel(int? code) {
    switch (code) {
      case 5:
        return "Rising";
      case 10:
        return "Falling";
      case 15:
        return "Rising Fast";
      case 20:
        return "Falling Fast";
      case 1:
        return "Stable";
      default:
        return "Stable";
    }
  }

  /// Time-in-range percentage (70–180 mg/dL) over current readings.
  int get timeInRangePercent {
    if (readings.isEmpty) return 0;

    final inRange = readings
        .where(
          (r) =>
              r.glucoseValue >= 70 &&
              r.glucoseValue <= 180,
        )
        .length;

    return ((inRange /
                readings.length) *
            100)
        .round();
  }

  int get averageGlucose {
    if (readings.isEmpty) return 0;

    final total = readings
        .map((r) => r.glucoseValue)
        .reduce((a, b) => a + b);

    return (total / readings.length)
        .round();
  }

  Future<void> _maybeNotify({
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

    try {
      await NotificationService
          .showNotification(
        title: title,
        body: body,
      );
    } catch (_) {}
  }

  Future<void> refresh() async {
    await _loadHistoryFromBackend();
  }

  void stopUpdates() {
    _sdkSubscription?.cancel();

    _sdkSubscription = null;
  }

  @override
  void dispose() {
    stopUpdates();

    super.dispose();
  }
}

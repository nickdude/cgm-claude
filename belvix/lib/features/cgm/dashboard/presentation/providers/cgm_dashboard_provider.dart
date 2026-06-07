import 'dart:async';

import 'package:fl_chart/fl_chart.dart';

import 'package:flutter/material.dart';

import '../../../../../core/services/notification_service.dart';

import '../../../data/models/cgm_reading_model.dart';

import '../../../data/repository/cgm_reading_repository_impl.dart';

import '../../../sdk/cgm_sdk.dart';

/// A single out-of-range glucose event for the notifications feed.
class GlucoseEvent {
  const GlucoseEvent({
    required this.isLow,
    required this.value,
    required this.at,
  });

  /// True = low (<70), false = high (>180).
  final bool isLow;

  final int value;

  final DateTime at;
}

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
class CGMDashboardProvider extends ChangeNotifier {
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

  /// Periodically re-fetches the backend so new readings appear without a
  /// manual refresh. This is the only real-time path on platforms without the
  /// native BLE SDK (e.g. web) and the safety net everywhere else — the live
  /// `glucoseData` events make mobile updates instant, the 15s poll guarantees
  /// the UI never sits on a stale snapshot while the screen is open.
  Timer? _pollTimer;

  static const _pollInterval = Duration(seconds: 15);

  final CgmReadingRepository _repository = CgmReadingRepository();

  /// Keys (`ts_value`) of readings already persisted to the backend or
  /// loaded from it this session. Guards against re-uploading the same
  /// reading when live events and the history backfill overlap, and when
  /// the SDK replays buffered history on each reconnect.
  final Set<String> _syncedKeys = {};

  /// SN of the device whose buffered history we've already pulled this
  /// connection. Reset on disconnect so the next connect re-syncs.
  String? _historySyncedForSn;

  /// Last SN we saw connected — lets [onAppResumed] re-pull the sensor's
  /// buffer for readings collected while the app was backgrounded, without
  /// waiting for a fresh connection.
  String? _lastKnownSn;

  bool _historySyncInFlight = false;

  /// Ordered oldest → newest; used directly by the chart and by
  /// aggregations (time-in-range, average).
  List<CgmReadingModel> readings = const [];

  List<FlSpot> get glucoseSpots {
    if (readings.isEmpty) {
      return const [];
    }

    final spots = <FlSpot>[];

    for (var i = 0; i < readings.length; i++) {
      spots.add(FlSpot(i.toDouble(), readings[i].glucoseValue));
    }

    return spots;
  }

  bool get hasReadings => readings.isNotEmpty;

  /// Low (<70) / high (>180) excursion events derived from the loaded
  /// readings — the first reading of each out-of-range stretch — newest
  /// first, capped to 30. Backs the notifications feed.
  List<GlucoseEvent> get glucoseEvents {
    final out = <GlucoseEvent>[];

    String? zone;
    for (final r in readings) {
      final v = r.glucoseValue;
      final z = v < 70 ? 'low' : (v > 180 ? 'high' : 'in');

      if ((z == 'low' || z == 'high') && z != zone) {
        out.add(
          GlucoseEvent(isLow: z == 'low', value: v.round(), at: r.readingAt),
        );
      }
      zone = z;
    }

    return out.reversed.take(30).toList();
  }

  void startRealtimeUpdates() {
    _attachSdkStream();

    _loadHistoryFromBackend();

    _startBackendPolling();
  }

  /// Starts the periodic backend refresh. Idempotent.
  void _startBackendPolling() {
    _pollTimer?.cancel();

    _pollTimer = Timer.periodic(
      _pollInterval,
      (_) => _mergeFromBackend(),
    );
  }

  Future<void> _loadHistoryFromBackend() async {
    isLoadingHistory = true;

    notifyListeners();

    final fetched = await _repository.listReadings();

    // Backend returns newest first; we want oldest → newest for the chart.
    fetched.sort((a, b) => a.readingAt.compareTo(b.readingAt));

    // Everything already on the backend is "synced" — seed the dedup
    // set from the full fetch (not the windowed list) so the history
    // backfill never re-uploads a reading the backend already has.
    for (final r in fetched) {
      _syncedKeys.add(_keyOf(r));
    }

    // Keep readings from the last year so the per-day filter on
    // the dashboard week strip has data for every visible weekday.
    readings = _capToWindow(fetched);

    _recomputeLatest();

    isLoadingHistory = false;

    notifyListeners();
  }

  void _attachSdkStream() {
    _sdkSubscription?.cancel();

    try {
      _sdkSubscription = CgmSdk.events.listen(
        _onSdkEvent,
        onError: (_) {},
        cancelOnError: false,
      );
    } catch (_) {
      // Native side missing — UI will simply stay in empty state.
    }
  }

  void _onSdkEvent(Map<String, dynamic> event) {
    switch (event["type"]) {
      case "glucoseData":
        _handleGlucoseData(event);
        break;

      // Once we know the bound SN (either from the connect ack or the
      // first deviceInfo frame), pull whatever readings the sensor
      // buffered while the app was closed/disconnected.
      case "connected":
      case "deviceInfo":
        final sn = event["sn"]?.toString();
        if (sn != null && sn.isNotEmpty) {
          _lastKnownSn = sn;
          _syncHistoryFromSdk(sn);
        }
        break;

      case "disconnected":
        // Allow a fresh backfill on the next connect.
        _historySyncedForSn = null;
        break;
    }
  }

  void _handleGlucoseData(Map<String, dynamic> event) {
    // The reference app discards the entire batch when the SDK marks it
    // abandoned (sensor warmup / invalid measurement window). Mirror
    // that — these are not real glucose values.
    if (event["isAbandoned"] == true) {
      return;
    }

    final raw = (event["bloodSugars"] as List?) ?? const [];

    // Live readings genuinely just arrived → receive-time is acceptable.
    final incoming = _convertReadings(raw, allowNowFallback: true);

    if (incoming.isEmpty) return;

    _mergeReadings(incoming);

    _recomputeLatest();

    notifyListeners();

    _persistNew(incoming);
  }

  /// Pulls sensor-buffered history via the SDK and folds it into the
  /// chart + backend. Runs at most once per SN per connection.
  Future<void> _syncHistoryFromSdk(String sn) async {
    if (_historySyncInFlight) return;

    if (_historySyncedForSn == sn) {
      return;
    }

    _historySyncInFlight = true;

    try {
      // indexStart=1 pulls the device's full buffer; already-known
      // readings are filtered out by [_syncedKeys] before upload, so
      // re-pulling on every reconnect is cheap and idempotent.
      final raw = await CgmSdk.getHistory(sn, indexStart: 1);

      // History is not "now" — drop readings the SDK gave no valid
      // timestamp for instead of collapsing them onto the current instant.
      final incoming = _convertReadings(raw, allowNowFallback: false);

      if (incoming.isNotEmpty) {
        _mergeReadings(incoming);

        _recomputeLatest();

        notifyListeners();

        await _persistNew(incoming);
      }

      _historySyncedForSn = sn;
    } catch (e) {
      debugPrint("CGM history sync failed: $e");
    } finally {
      _historySyncInFlight = false;
    }
  }

  /// Converts raw SDK blood-sugar maps into typed readings.
  ///
  /// Shared by the live stream and the history backfill so the value,
  /// timestamp and trend logic stay identical.
  ///
  /// [allowNowFallback] controls what happens when a reading has no valid
  /// `createTime`. For the **live** stream the reading genuinely just
  /// arrived, so receive-time is a fair stamp. For the **history backfill**
  /// it would be wrong — stamping hundreds of historical readings with
  /// `now` collapses them onto one instant (the meshy-graph bug), so we
  /// drop timestamp-less historical readings instead.
  List<CgmReadingModel> _convertReadings(
    List<dynamic> raw, {
    required bool allowNowFallback,
  }) {
    final out = <CgmReadingModel>[];

    for (final r in raw) {
      if (r is! Map) continue;

      final m = Map<String, dynamic>.from(r);

      final processed = (m["processedBloodSugar"] as num?);

      if (processed == null) continue;

      final resolved = _resolveReadingTime((m["createTime"] as num?)?.toInt());

      final readingAt = resolved ?? (allowNowFallback ? DateTime.now() : null);

      // No usable timestamp for a historical reading → skip it.
      if (readingAt == null) continue;

      out.add(
        CgmReadingModel(
          glucoseValue: mmolToMgDl(processed),
          trend: _trendLabel((m["trend"] as num?)?.toInt()),
          readingAt: readingAt,
        ),
      );
    }

    return out;
  }

  /// The SDK reports `createTime` in **seconds** since the unix epoch
  /// (the Eaglenos app always multiplies it by 1000). Returns null when the
  /// value is missing or implausible so the caller can decide whether to
  /// fall back to receive-time (live) or drop the reading (history).
  DateTime? _resolveReadingTime(int? rawCreate) {
    if (rawCreate == null) return null;

    final int ms;
    if (rawCreate >= 1000000000000) {
      // Already milliseconds (defensive — shouldn't normally happen).
      ms = rawCreate;
    } else if (rawCreate >= 1000000000) {
      // Seconds → milliseconds.
      ms = rawCreate * 1000;
    } else {
      return null;
    }

    // Sanity window: after 2020-01-01 and not in the future.
    const min2020 = 1577836800000;
    final maxFuture = DateTime.now()
        .add(const Duration(days: 1))
        .millisecondsSinceEpoch;

    if (ms < min2020 || ms > maxFuture) {
      return null;
    }

    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  /// Refreshes the headline metrics from the newest reading.
  void _recomputeLatest() {
    if (readings.isEmpty) return;

    final latest = readings.last;

    glucose = latest.glucoseValue.round();

    trend = latest.trend;

    lastReadingAt = latest.readingAt;

    _updateAlerts();
  }

  String _keyOf(CgmReadingModel r) =>
      'ts:${r.readingAt.millisecondsSinceEpoch}_${r.glucoseValue.round()}';

  /// POSTs only readings the backend hasn't seen yet.
  Future<void> _persistNew(List<CgmReadingModel> incoming) async {
    for (final r in incoming) {
      final k = _keyOf(r);

      if (_syncedKeys.contains(k)) {
        continue;
      }

      _syncedKeys.add(k);

      await _repository.addReading(
        glucoseValue: r.glucoseValue,
        trend: r.trend,
        readingAt: r.readingAt,
      );
    }
  }

  void _mergeReadings(List<CgmReadingModel> incoming) {
    // Dedupe by backend id when present (each row in the DB is
    // distinct), and by `${ms}_${value}` for not-yet-persisted local
    // readings — this is precise enough to drop true duplicates while
    // preserving distinct readings that share a millisecond timestamp.
    final byKey = <String, CgmReadingModel>{};

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

    final merged = byKey.values.toList()
      ..sort((a, b) => a.readingAt.compareTo(b.readingAt));

    readings = _capToWindow(merged);
  }

  /// Removes "collapsed" readings — many distinct samples that share the
  /// same second because they were once stamped with receive-time. A real
  /// CGM reports roughly every few minutes, so more than 3 readings inside
  /// a single second is physically impossible and indicates the legacy
  /// timestamp bug; the whole offending second is dropped.
  List<CgmReadingModel> _dropCollapsedClusters(List<CgmReadingModel> all) {
    if (all.length < 8) return all;

    final perSecond = <int, int>{};
    for (final r in all) {
      final sec = r.readingAt.millisecondsSinceEpoch ~/ 1000;
      perSecond[sec] = (perSecond[sec] ?? 0) + 1;
    }

    final cleaned = all.where((r) {
      final sec = r.readingAt.millisecondsSinceEpoch ~/ 1000;
      return (perSecond[sec] ?? 0) <= 3;
    }).toList();

    final dropped = all.length - cleaned.length;
    if (dropped > 0) {
      debugPrint('Dropped $dropped collapsed-timestamp readings');
    }

    return cleaned;
  }

  /// Trims [all] to readings inside the last year, with a hard entry
  /// cap to bound memory. Older readings drop off so the
  /// dashboard's week strip + per-day chart stay accurate without
  /// growing the list forever.
  List<CgmReadingModel> _capToWindow(List<CgmReadingModel> input) {
    // Guard against legacy collapsed-timestamp pollution already stored on
    // the backend before the fix above.
    final all = _dropCollapsedClusters(input);

    if (all.isEmpty) return const [];

    final now = DateTime.now();
    final cutoff = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 364));

    final windowed = all.where((r) => !r.readingAt.isBefore(cutoff)).toList();

    // If the backend has only historical readings and none in the
    // last week (e.g. fresh-installed app + test data), fall back to
    // showing whatever we have so the screen isn't blank.
    final result = windowed.isEmpty ? all : windowed;

    // The 1-year window is the natural bound (~365×288≈105k for a real
    // sensor). Hard cap is just a runaway-data guardrail; when it
    // trips we downsample evenly across the list so the oldest days
    // don't get evicted.
    const hardCap = 50000;
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
      alertMessage = "Low glucose detected";
      alertColor = Colors.red;

      _maybeNotify(
        title: "Low Glucose Alert",
        body: "Your glucose is below safe range.",
      );
    } else if (glucose! > 180) {
      showAlert = true;
      alertMessage = "High glucose detected";
      alertColor = Colors.orange;

      _maybeNotify(
        title: "High Glucose Alert",
        body: "Your glucose is above safe range.",
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
        .where((r) => r.glucoseValue >= 70 && r.glucoseValue <= 180)
        .length;

    return ((inRange / readings.length) * 100).round();
  }

  int get averageGlucose {
    if (readings.isEmpty) return 0;

    final total = readings.map((r) => r.glucoseValue).reduce((a, b) => a + b);

    return (total / readings.length).round();
  }

  Future<void> _maybeNotify({
    required String title,
    required String body,
  }) async {
    final now = DateTime.now();

    if (lastNotificationTime != null &&
        now.difference(lastNotificationTime!).inSeconds < 30) {
      return;
    }

    lastNotificationTime = now;

    try {
      await NotificationService.showNotification(title: title, body: body);
    } catch (_) {}
  }

  Future<void> refresh() async {
    await _loadHistoryFromBackend();
  }

  /// Catch up on readings collected while the app was backgrounded.
  ///
  /// The sensor keeps buffering readings (the SDK heartbeat runs on an
  /// AlarmManager wake-up), but the live `glucoseData` stream only reaches us
  /// reliably while the app is foreground. Previously the sensor buffer was
  /// re-pulled only on a fresh connection, so users had to fully restart the
  /// app to see new readings. On resume we now (1) re-pull the sensor's buffer
  /// and (2) merge anything new from the backend — both silent (no spinner,
  /// merge-not-replace) so the visible readings never flicker or regress.
  Future<void> onAppResumed() async {
    final sn = _lastKnownSn;

    if (sn != null && sn.isNotEmpty) {
      // Allow a fresh backfill; getHistory is deduped by _syncedKeys, so
      // re-pulling the whole buffer is cheap and idempotent.
      _historySyncedForSn = null;
      await _syncHistoryFromSdk(sn);
    }

    await _mergeFromBackend();
  }

  /// Silently folds any backend rows we don't already have into [readings]
  /// (merge, not replace) so a refresh never drops not-yet-persisted live
  /// readings or flashes a loading state. Only recomputes metrics + rebuilds
  /// the UI when the merge actually changed something, so 15s polling doesn't
  /// churn rebuilds or re-fire alerts for an unchanged latest reading.
  Future<void> _mergeFromBackend() async {
    try {
      final fetched = await _repository.listReadings();

      if (fetched.isEmpty) return;

      final prevLen = readings.length;
      final prevLast =
          readings.isEmpty ? null : readings.last.readingAt;

      for (final r in fetched) {
        _syncedKeys.add(_keyOf(r));
      }

      _mergeReadings(fetched);

      final changed = readings.length != prevLen ||
          (readings.isNotEmpty && readings.last.readingAt != prevLast);

      if (changed) {
        _recomputeLatest();

        notifyListeners();
      }
    } catch (e) {
      debugPrint("CGM backend merge failed: $e");
    }
  }

  bool _loadingOlder = false;
  bool _historyExhausted = false;

  /// Lazy-load older history when the timeline chart scrolls near its oldest
  /// point. Prepends any genuinely-older readings (de-duped) without
  /// disturbing the existing ones, so the chart's absolute-time window keeps
  /// its scroll position. No-ops once the backend has no older data.
  Future<void> loadOlderReadings() async {
    if (_loadingOlder || _historyExhausted || isLoadingHistory) return;
    _loadingOlder = true;
    try {
      final oldest = readings.isEmpty ? null : readings.first.readingAt;
      final fetched = await _repository.listReadings();

      final existing = readings.map(_keyOf).toSet();
      final older =
          fetched
              .where(
                (r) =>
                    (oldest == null || r.readingAt.isBefore(oldest)) &&
                    !existing.contains(_keyOf(r)),
              )
              .toList()
            ..sort((a, b) => a.readingAt.compareTo(b.readingAt));

      if (older.isEmpty) {
        _historyExhausted = true;
      } else {
        for (final r in older) {
          _syncedKeys.add(_keyOf(r));
        }
        readings = _capToWindow([...older, ...readings]);
        notifyListeners();
      }
    } catch (_) {
      // Leave _historyExhausted false so a later scroll can retry.
    } finally {
      _loadingOlder = false;
    }
  }

  void stopUpdates() {
    _sdkSubscription?.cancel();

    _sdkSubscription = null;

    _pollTimer?.cancel();

    _pollTimer = null;
  }

  @override
  void dispose() {
    stopUpdates();

    super.dispose();
  }
}

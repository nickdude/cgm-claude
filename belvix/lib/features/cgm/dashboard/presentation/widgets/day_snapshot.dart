import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';

import '../../../data/models/cgm_reading_model.dart';

/// UI-layer aggregation of readings for a single calendar day.
///
/// All providers + business logic stay untouched — this helper just
/// slices the existing `readings` list and recomputes the same metrics
/// used elsewhere in the dashboard, scoped to a particular day.
class DaySnapshot {
  DaySnapshot._(this.day, this.readings);

  final DateTime day;

  /// Readings whose `readingAt` falls inside [day] (local time).
  final List<CgmReadingModel> readings;

  bool get hasReadings => readings.isNotEmpty;

  int? get glucose =>
      readings.isEmpty ? null : readings.last.glucoseValue.round();

  DateTime? get lastReadingAt =>
      readings.isEmpty ? null : readings.last.readingAt;

  /// Time-in-range percentage (70–180 mg/dL) for the day.
  int get timeInRangePercent {
    if (readings.isEmpty) return 0;

    final inRange = readings
        .where((r) => r.glucoseValue >= 70 && r.glucoseValue <= 180)
        .length;

    return ((inRange / readings.length) * 100).round();
  }

  /// Time-out-of-range percentage — the inverse of time-in-range.
  int get timeOutOfRangePercent =>
      readings.isEmpty ? 0 : 100 - timeInRangePercent;

  /// Distinct hyperglycemic excursions (>180 mg/dL) lasting ≥15 min.
  int get hyperEvents => _excursionCount((v) => v > 180);

  /// Distinct hypoglycemic excursions (<70 mg/dL) lasting ≥15 min.
  int get hypoEvents => _excursionCount((v) => v < 70);

  /// Counts maximal runs of readings matching [test] that last at least
  /// 15 minutes — one clinical "event" per sustained excursion. A gap of
  /// more than 30 min between readings ends the current run. [readings] is
  /// already sorted oldest→newest by [forDay].
  int _excursionCount(bool Function(double mgdl) test) {
    var events = 0;
    DateTime? runStart;
    DateTime? runEnd;
    DateTime? prev;

    void close() {
      if (runStart != null &&
          runEnd != null &&
          runEnd!.difference(runStart!).inMinutes >= 15) {
        events++;
      }
      runStart = null;
      runEnd = null;
    }

    for (final r in readings) {
      final brokeGap =
          prev != null && r.readingAt.difference(prev).inMinutes > 30;
      if (test(r.glucoseValue)) {
        if (brokeGap) close();
        runStart ??= r.readingAt;
        runEnd = r.readingAt;
      } else {
        close();
      }
      prev = r.readingAt;
    }
    close();
    return events;
  }

  int get averageGlucose {
    if (readings.isEmpty) return 0;

    final total = readings.fold<double>(0, (acc, r) => acc + r.glucoseValue);

    return (total / readings.length).round();
  }

  int get stdDev {
    if (readings.isEmpty) return 0;

    // Use the unrounded mean (not the rounded averageGlucose) for accuracy.
    final mean =
        readings.fold<double>(0, (acc, r) => acc + r.glucoseValue) /
        readings.length;

    final variance =
        readings.fold<double>(
          0,
          (acc, r) => acc + math.pow(r.glucoseValue - mean, 2).toDouble(),
        ) /
        readings.length;

    return math.sqrt(variance).round();
  }

  /// Typical gap between readings (median, ignoring large sensor gaps), used
  /// to size single-reading spikes. Falls back to 5 min.
  int get _intervalMinutes {
    if (readings.length < 2) return 5;
    final gaps = <int>[];
    for (var i = 1; i < readings.length; i++) {
      final g = readings[i].readingAt
          .difference(readings[i - 1].readingAt)
          .inMinutes;
      if (g > 0 && g <= 30) gaps.add(g);
    }
    if (gaps.isEmpty) return 5;
    gaps.sort();
    return gaps[gaps.length ~/ 2];
  }

  /// Contiguous runs of readings above 180 mg/dL — a gap > 30 min splits a
  /// run. Spike count + time are both derived from this so they stay in
  /// sync (a run that starts above 180 is still counted).
  List<List<CgmReadingModel>> get _spikeRuns {
    final runs = <List<CgmReadingModel>>[];
    List<CgmReadingModel>? current;
    DateTime? prev;

    for (final r in readings) {
      final brokeGap =
          prev != null && r.readingAt.difference(prev).inMinutes > 30;
      if (r.glucoseValue > 180) {
        if (current == null || brokeGap) {
          current = <CgmReadingModel>[];
          runs.add(current);
        }
        current.add(r);
      } else {
        current = null;
      }
      prev = r.readingAt;
    }
    return runs;
  }

  /// Number of distinct excursions above 180 mg/dL.
  int get spikeCount => _spikeRuns.length;

  /// Total time spent above 180 mg/dL, computed from real timestamps.
  String get spikeTime {
    final interval = _intervalMinutes;
    var totalMin = 0;

    for (var i = 0; i < readings.length; i++) {
      if (readings[i].glucoseValue <= 180) continue;
      if (i + 1 < readings.length) {
        final gap = readings[i + 1].readingAt
            .difference(readings[i].readingAt)
            .inMinutes;
        totalMin += (gap > 0 && gap <= 30) ? gap : interval;
      } else {
        totalMin += interval; // last reading still counts ~one interval
      }
    }

    final h = totalMin ~/ 60;
    final m = totalMin % 60;
    return h > 0 ? '${h}h ${m}m' : '${m}m';
  }

  /// Spline-ready chart spots (x = index, y = mg/dL).
  List<FlSpot> get glucoseSpots {
    if (readings.isEmpty) return const [];

    final out = <FlSpot>[];
    for (var i = 0; i < readings.length; i++) {
      out.add(FlSpot(i.toDouble(), readings[i].glucoseValue));
    }
    return out;
  }

  /// Quick trend classification for the gauge arrow.
  String get trend {
    if (readings.length < 3) return 'stable';

    final last = readings.last.glucoseValue;
    final prior = readings[readings.length - 3].glucoseValue;
    final delta = last - prior;

    if (delta > 8) return 'rising';
    if (delta < -8) return 'falling';
    return 'stable';
  }

  /// Build a snapshot for [day] by filtering [allReadings] (any order).
  static DaySnapshot forDay(DateTime day, List<CgmReadingModel> allReadings) {
    final dayStart = DateTime(day.year, day.month, day.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    final filtered =
        allReadings
            .where(
              (r) =>
                  !r.readingAt.isBefore(dayStart) &&
                  r.readingAt.isBefore(dayEnd),
            )
            .toList()
          ..sort((a, b) => a.readingAt.compareTo(b.readingAt));

    return DaySnapshot._(dayStart, filtered);
  }
}

/// Returns the 7 weekdays (Mon..Sun) of the week containing [reference].
List<DateTime> weekOf(DateTime reference) {
  final monday = DateTime(
    reference.year,
    reference.month,
    reference.day,
  ).subtract(Duration(days: reference.weekday - 1));

  return List<DateTime>.generate(7, (i) => monday.add(Duration(days: i)));
}

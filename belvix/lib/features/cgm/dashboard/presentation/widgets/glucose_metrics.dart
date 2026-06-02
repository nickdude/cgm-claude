import 'dart:math' as math;

import '../../../data/models/cgm_reading_model.dart';

/// Classification of an interpretation metric.
enum MetricStatus { optimal, moderate, outOfRange, collecting }

/// A single interpretation metric, fully resolved for the UI.
class Metric {
  const Metric({
    required this.title,
    required this.value,
    required this.unit,
    required this.status,
    required this.position,
    required this.higherIsBetter,
    required this.recommendation,
    this.detail,
    this.severe = false,
    this.tappable = false,
  });

  final String title;

  /// Display value (already formatted); '—' when collecting.
  final String value;
  final String unit;
  final MetricStatus status;

  /// Marker position on the meter, 0 (left) … 1 (right).
  final double position;

  /// When true the meter's green zone is on the RIGHT (e.g. Time-In-Range).
  final bool higherIsBetter;

  final String recommendation;

  /// Optional secondary line (events / levels / duration).
  final String? detail;

  /// Severe hypoglycemia present (<54 mg/dL) — triggers the priority banner.
  final bool severe;

  final bool tappable;
}

/// Result of building the day's interpretation.
class Interpretation {
  const Interpretation({required this.metrics, required this.severeHypo});

  /// Ordered TBR → TAR → TIR → Excursion → GMI → CV.
  final List<Metric> metrics;

  /// Any reading <54 mg/dL in the selected day → pin TBR + warning banner.
  final bool severeHypo;
}

class GlucoseMetrics {
  GlucoseMetrics._();

  /// Build interpretation metrics for [selectedDay] from real readings.
  ///
  /// Daily metrics (TBR/TAR/TIR/Excursion) use [dayReadings]; the 14-day
  /// metrics (GMI/CV) use [allReadings]. [dayMeals] supplies meal timestamps
  /// for the excursion calculation.
  static Interpretation build({
    required DateTime now,
    required List<CgmReadingModel> dayReadings,
    required List<CgmReadingModel> allReadings,
    required List<DateTime> dayMeals,
  }) {
    final interval = _medianInterval(
      dayReadings.isNotEmpty ? dayReadings : allReadings,
    );

    final bands = _bandMinutes(dayReadings, interval);
    final dayCoverage = bands.total / (24 * 60);
    final daySufficient = dayCoverage >= 0.7 && dayReadings.length >= 2;

    final tir = bands.total == 0 ? 0.0 : bands.inRange / bands.total * 100;
    final tar = bands.total == 0 ? 0.0 : bands.above / bands.total * 100;
    final tbr = bands.total == 0 ? 0.0 : bands.below / bands.total * 100;

    final hyperEvents = _runs(dayReadings, (v) => v > 180);
    final hypoEvents = _runs(dayReadings, (v) => v < 70);
    final l2Hyper = dayReadings.any((r) => r.glucoseValue > 250);
    final l2Low = dayReadings.any((r) => r.glucoseValue < 54);
    final l1Low = dayReadings.any(
      (r) => r.glucoseValue >= 54 && r.glucoseValue <= 69,
    );

    // ---- Time Below Range ----
    final tbrMetric = Metric(
      title: 'Time Below Range',
      value: daySufficient ? '${tbr.round()}' : '—',
      unit: '%',
      status: daySufficient ? _tbrStatus(tbr) : MetricStatus.collecting,
      position: _posLowerBetter(tbr, 1, 4, 10),
      higherIsBetter: false,
      severe: l2Low,
      detail: daySufficient
          ? _hypoDetail(hypoEvents, l1Low, l2Low, _fmtDur(bands.below.round()))
          : null,
      recommendation: !daySufficient
          ? _collecting
          : l2Low
          ? 'Severe low detected (<54 mg/dL). Treat immediately with '
                'fast-acting carbs and review your insulin/medication timing.'
          : _tbrStatus(tbr) == MetricStatus.optimal
          ? 'Lows are well controlled. Keep meal and insulin timing '
                'consistent to avoid drops.'
          : 'You spent time below range. Carry fast-acting carbs and '
                'review doses around meals and exercise.',
    );

    // ---- Time Above Range ----
    final tarMetric = Metric(
      title: 'Time Above Range',
      value: daySufficient ? '${tar.round()}' : '—',
      unit: '%',
      status: daySufficient ? _tarStatus(tar) : MetricStatus.collecting,
      position: _posLowerBetter(tar, 5, 25, 60),
      higherIsBetter: false,
      detail: daySufficient
          ? _hyperDetail(hyperEvents, l2Hyper, _fmtDur(bands.above.round()))
          : null,
      recommendation: !daySufficient
          ? _collecting
          : _tarStatus(tar) == MetricStatus.optimal
          ? 'Highs are minimal. Balanced meals and activity are keeping you '
                'in range.'
          : 'You spent time above range. Watch carb-heavy meals and consider '
                'a short walk after eating.',
    );

    // ---- Time In Range (higher is better) ----
    final tirMetric = Metric(
      title: 'Time In Range',
      value: daySufficient ? '${tir.round()}' : '—',
      unit: '%',
      status: daySufficient ? _tirStatus(tir) : MetricStatus.collecting,
      position: _posTir(tir),
      higherIsBetter: true,
      detail: daySufficient
          ? 'Target 70–180 mg/dL · ${_fmtDur(bands.inRange.round())} in range'
          : null,
      recommendation: !daySufficient
          ? _collecting
          : _tirStatus(tir) == MetricStatus.optimal
          ? 'Great control — most of your day was in target. Keep it up!'
          : 'Aim for more time in 70–180 mg/dL with steady meals, movement '
                'and consistent dosing.',
    );

    // ---- Glucose Excursion (meal spikes) ----
    final excursion = _maxExcursion(dayReadings, dayMeals);
    final excOk = daySufficient && excursion != null;
    final excMetric = Metric(
      title: 'Glucose Excursion',
      value: excOk ? '$excursion' : '—',
      unit: 'mg/dL',
      status: excOk ? _excStatus(excursion) : MetricStatus.collecting,
      position: excOk ? _posLowerBetter(excursion.toDouble(), 30, 50, 120) : 0,
      higherIsBetter: false,
      detail: excOk
          ? 'Largest post-meal rise (within 120 min)'
          : dayMeals.isEmpty
          ? 'Log meals to see post-meal spikes'
          : null,
      recommendation: !excOk
          ? (dayMeals.isEmpty
                ? 'Log your meals to measure post-meal glucose spikes.'
                : _collecting)
          : _excStatus(excursion) == MetricStatus.optimal
          ? 'Your meals caused only small glucose rises — nicely balanced.'
          : 'Large post-meal spikes. Try pairing carbs with protein, fat or '
                'fibre and a short walk afterwards.',
    );

    // ---- 14-day metrics: GMI & CV ----
    final start14 = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 13));
    final window14 = allReadings
        .where((r) => !r.readingAt.isBefore(start14))
        .toList();
    final distinctDays = window14
        .map((r) => _dayKey(r.readingAt))
        .toSet()
        .length;
    final wearMin = _bandMinutes(window14, _medianInterval(window14)).total;
    final wear14 = wearMin / (14 * 24 * 60);
    final has14 = distinctDays >= 14 && wear14 >= 0.7;

    final mean14 = window14.isEmpty
        ? 0.0
        : window14.map((r) => r.glucoseValue).reduce((a, b) => a + b) /
              window14.length;
    final sd14 = _stdDev(window14, mean14);
    final gmi = 3.31 + 0.02392 * mean14;
    final cv = mean14 == 0 ? 0.0 : sd14 / mean14 * 100;

    final gmiMetric = Metric(
      title: 'GMI',
      value: has14 ? gmi.toStringAsFixed(1) : '—',
      unit: '%',
      status: has14 ? _gmiStatus(gmi) : MetricStatus.collecting,
      position: has14 ? _posLowerBetter(gmi, 5.7, 6.5, 8.0) : 0,
      higherIsBetter: false,
      tappable: true,
      detail: has14
          ? 'Estimated A1C from 14-day mean glucose'
          : 'Needs 14 days of data ($distinctDays/14)',
      recommendation: !has14
          ? 'Collecting data — GMI needs at least 14 days with ≥70% sensor '
                'wear. ($distinctDays/14 days so far.)'
          : _gmiStatus(gmi) == MetricStatus.optimal
          ? 'Your estimated A1C is in a healthy range. Keep up your routine.'
          : 'Your estimated A1C is elevated. Work with your clinician on '
                'meals, activity and medication.',
    );

    final cvMetric = Metric(
      title: 'Glucose Oscillations',
      value: has14 ? '${cv.round()}' : '—',
      unit: '% CV',
      status: has14 ? _cvStatus(cv) : MetricStatus.collecting,
      position: has14 ? _posLowerBetter(cv, 25, 36, 60) : 0,
      higherIsBetter: false,
      detail: has14
          ? 'Glucose variability (lower is steadier)'
          : 'Needs 14 days of data ($distinctDays/14)',
      recommendation: !has14
          ? 'Collecting data — variability needs at least 14 days with ≥70% '
                'sensor wear. ($distinctDays/14 days so far.)'
          : _cvStatus(cv) == MetricStatus.optimal
          ? 'Your glucose is stable with low variability — excellent.'
          : 'Your glucose swings are high. Steady meals and dosing help '
                'reduce oscillations.',
    );

    return Interpretation(
      metrics: [
        tbrMetric, // 1 — highest priority (pinned)
        tarMetric, // 2
        tirMetric, // 3
        excMetric, // 4
        gmiMetric, // 5
        cvMetric, // 6
      ],
      severeHypo: l2Low,
    );
  }

  // --- status classifiers ---

  static MetricStatus _tbrStatus(double v) => v < 1
      ? MetricStatus.optimal
      : v <= 4
      ? MetricStatus.moderate
      : MetricStatus.outOfRange;

  static MetricStatus _tarStatus(double v) => v < 5
      ? MetricStatus.optimal
      : v <= 25
      ? MetricStatus.moderate
      : MetricStatus.outOfRange;

  static MetricStatus _tirStatus(double v) => v >= 70
      ? MetricStatus.optimal
      : v >= 50
      ? MetricStatus.moderate
      : MetricStatus.outOfRange;

  static MetricStatus _excStatus(int v) => v < 30
      ? MetricStatus.optimal
      : v <= 50
      ? MetricStatus.moderate
      : MetricStatus.outOfRange;

  static MetricStatus _gmiStatus(double v) => v < 5.7
      ? MetricStatus.optimal
      : v < 6.5
      ? MetricStatus.moderate
      : MetricStatus.outOfRange;

  static MetricStatus _cvStatus(double v) => v <= 25
      ? MetricStatus.optimal
      : v <= 36
      ? MetricStatus.moderate
      : MetricStatus.outOfRange;

  // --- marker positions (3 equal thirds aligned to thresholds) ---

  static double _posLowerBetter(double v, double t1, double t2, double vmax) {
    double p;
    if (v < t1) {
      p = (t1 == 0 ? 0 : v / t1).clamp(0.0, 1.0) * (1 / 3);
    } else if (v < t2) {
      p = 1 / 3 + ((v - t1) / (t2 - t1)).clamp(0.0, 1.0) * (1 / 3);
    } else {
      final span = (vmax - t2) == 0 ? 1 : (vmax - t2);
      p = 2 / 3 + ((v - t2) / span).clamp(0.0, 1.0) * (1 / 3);
    }
    return p.clamp(0.0, 1.0);
  }

  static double _posTir(double v) {
    double p;
    if (v < 50) {
      p = (v / 50).clamp(0.0, 1.0) * (1 / 3);
    } else if (v < 70) {
      p = 1 / 3 + ((v - 50) / 20) * (1 / 3);
    } else {
      p = 2 / 3 + ((v - 70) / 30).clamp(0.0, 1.0) * (1 / 3);
    }
    return p.clamp(0.0, 1.0);
  }

  // --- detail strings ---

  static String _hypoDetail(int events, bool l1, bool l2, String dur) {
    final parts = <String>['$events ${events == 1 ? 'event' : 'events'}'];
    if (l2) {
      parts.add('Level 2 (<54)');
    } else if (l1) {
      parts.add('Level 1 (54–69)');
    }
    parts.add('$dur below');
    return parts.join(' · ');
  }

  static String _hyperDetail(int events, bool l2, String dur) {
    final parts = <String>['$events ${events == 1 ? 'event' : 'events'}'];
    if (l2) parts.add('Level 2 (>250)');
    parts.add('$dur above');
    return parts.join(' · ');
  }

  static const _collecting =
      'Not enough sensor data for this day (needs ≥70% coverage).';

  // --- numeric helpers ---

  static String _dayKey(DateTime t) => '${t.year}-${t.month}-${t.day}';

  static int _medianInterval(List<CgmReadingModel> r) {
    if (r.length < 2) return 5;
    final gaps = <int>[];
    for (var i = 1; i < r.length; i++) {
      final g = r[i].readingAt.difference(r[i - 1].readingAt).inMinutes;
      if (g > 0 && g <= 30) gaps.add(g);
    }
    if (gaps.isEmpty) return 5;
    gaps.sort();
    return gaps[gaps.length ~/ 2];
  }

  static _Bands _bandMinutes(List<CgmReadingModel> r, int interval) {
    final b = _Bands();
    for (var i = 0; i < r.length; i++) {
      int mins;
      if (i + 1 < r.length) {
        final g = r[i + 1].readingAt.difference(r[i].readingAt).inMinutes;
        mins = (g > 0 && g <= 30) ? g : interval;
      } else {
        mins = interval;
      }
      final v = r[i].glucoseValue;
      b.total += mins;
      if (v < 70) {
        b.below += mins;
      } else if (v <= 180) {
        b.inRange += mins;
      } else {
        b.above += mins;
      }
    }
    return b;
  }

  static int _runs(List<CgmReadingModel> r, bool Function(double) test) {
    var runs = 0;
    var inRun = false;
    DateTime? prev;
    for (final x in r) {
      final brokeGap =
          prev != null && x.readingAt.difference(prev).inMinutes > 30;
      if (test(x.glucoseValue)) {
        if (!inRun || brokeGap) runs++;
        inRun = true;
      } else {
        inRun = false;
      }
      prev = x.readingAt;
    }
    return runs;
  }

  static int? _maxExcursion(List<CgmReadingModel> day, List<DateTime> meals) {
    if (day.length < 2 || meals.isEmpty) return null;
    double? best;
    for (final m in meals) {
      final baseline = _nearestValue(
        day,
        m.subtract(const Duration(minutes: 15)),
        windowMin: 25,
      );
      if (baseline == null) continue;
      double? peak;
      final end = m.add(const Duration(minutes: 120));
      for (final r in day) {
        if (!r.readingAt.isBefore(m) && r.readingAt.isBefore(end)) {
          peak = (peak == null || r.glucoseValue > peak)
              ? r.glucoseValue
              : peak;
        }
      }
      if (peak == null) continue;
      final ex = peak - baseline;
      if (best == null || ex > best) best = ex;
    }
    return best?.round();
  }

  static double? _nearestValue(
    List<CgmReadingModel> day,
    DateTime t, {
    required int windowMin,
  }) {
    double? best;
    var bestDiff = 1 << 30;
    for (final r in day) {
      final d = r.readingAt.difference(t).inMinutes.abs();
      if (d <= windowMin && d < bestDiff) {
        best = r.glucoseValue;
        bestDiff = d;
      }
    }
    return best;
  }

  static double _stdDev(List<CgmReadingModel> r, double mean) {
    if (r.isEmpty) return 0;
    final variance =
        r.fold<double>(
          0,
          (acc, x) => acc + math.pow(x.glucoseValue - mean, 2).toDouble(),
        ) /
        r.length;
    return math.sqrt(variance);
  }

  static String _fmtDur(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return h > 0 ? '${h}h ${m}m' : '${m}m';
  }
}

class _Bands {
  double total = 0;
  double inRange = 0;
  double above = 0;
  double below = 0;
}

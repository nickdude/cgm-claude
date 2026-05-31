import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../data/models/cgm_reading_model.dart';
import 'dashboard_theme.dart';

/// Interactive glucose trend chart matching the "Hub · Data" design.
///
/// Renders the day's readings as a smooth, range-coloured spline (green in
/// target, amber when borderline, red when high) over a dotted 70–110 mg/dL
/// target band labelled on the right edge.
///
/// Interactions (presentation only — no data/calc changes):
///   • smooth Catmull-Rom spline that still passes through every reading
///   • horizontal drag to scroll through history (Y-axis stays fixed)
///   • two-finger pinch to zoom the X-axis, anchored on the touch point
///   • culls off-screen segments so it stays smooth with thousands of points
///
/// Data source: [readings] are `DaySnapshot.readings` for the selected day —
/// the live SDK `glucoseData` stream plus backend `/cgm-reading/list`
/// history, filtered to that day. This widget never mutates them.
class GlucoseTrendChart extends StatefulWidget {
  const GlucoseTrendChart({super.key, required this.readings});

  final List<CgmReadingModel> readings;

  // Target band (mg/dL).
  static const double targetLow = 70;
  static const double targetHigh = 110;

  static const _green = DashboardTheme.accent;
  static const _amber = Color(0xFFE89240);
  static const _red = Color(0xFFE5484D);

  static Color zoneColor(double v) {
    if (v < targetLow) return _amber;
    if (v <= targetHigh) return _green;
    if (v <= 140) return _amber;
    return _red;
  }

  @override
  State<GlucoseTrendChart> createState() => _GlucoseTrendChartState();
}

class _GlucoseTrendChartState extends State<GlucoseTrendChart> {
  static const _rightPad = 34.0; // room for the 110 / 70 labels

  double _scale = 1.0;
  double _offsetX = 0.0; // horizontal scroll, in pixels of virtual content

  // Index of the reading whose tooltip is shown (null = none).
  int? _selectedIndex;

  // Gesture anchors.
  double _scaleStart = 1.0;
  double _offsetStart = 0.0;
  double _focalStart = 0.0;
  double _plotW = 0.0;

  // Y-domain — computed once per dataset (stays fixed while scrolling/
  // zooming horizontally) and made robust to outliers so a few garbage
  // spikes don't squash the real trend into a thin strip.
  double _yMin = 70;
  double _yMax = 180;

  @override
  void initState() {
    super.initState();
    _computeDomain();
  }

  void _computeDomain() {
    final values =
        widget.readings.map((r) => r.glucoseValue).toList(growable: false)
          ..sort();
    if (values.isEmpty) return;

    double pct(double p) =>
        values[(p * (values.length - 1)).round().clamp(0, values.length - 1)];

    // Hug the bulk of the data; rare extreme outliers clip off the top
    // rather than stretching the whole axis.
    _yMin = (pct(0.05) - 15).clamp(40.0, 75.0).toDouble();
    _yMax = (pct(0.92) + 25).clamp(170.0, 300.0).toDouble();
  }

  double get _maxScale {
    // Allow zooming until points are comfortably spaced (~14 visible).
    final n = widget.readings.length;
    if (n <= 14) return 1.0;
    return (n / 14).clamp(1.0, 12.0).toDouble();
  }

  double _maxOffset(double plotW) => math.max(0.0, plotW * _scale - plotW);

  @override
  void didUpdateWidget(covariant GlucoseTrendChart old) {
    super.didUpdateWidget(old);
    if (!identical(old.readings, widget.readings)) {
      _computeDomain();
      if (_selectedIndex != null && _selectedIndex! >= widget.readings.length) {
        _selectedIndex = null;
      }
    }
    // Keep zoom valid if the dataset shrank; clamp scroll back into range.
    _scale = _scale.clamp(1.0, _maxScale).toDouble();
    if (_plotW > 0) {
      _offsetX = _offsetX.clamp(0.0, _maxOffset(_plotW));
    }
  }

  void _onScaleStart(ScaleStartDetails d) {
    _scaleStart = _scale;
    _offsetStart = _offsetX;
    _focalStart = d.localFocalPoint.dx;
  }

  void _onScaleUpdate(ScaleUpdateDetails d) {
    final plotW = _plotW;
    if (plotW <= 0) return;

    // New zoom from the pinch factor (1.0 for single-finger pans).
    final newScale = (_scaleStart * d.scale).clamp(1.0, _maxScale).toDouble();

    // Virtual fraction that sat under the initial focal point; keep it
    // anchored under the (possibly moved) current focal point. This makes
    // the zoom focus on the touched area and folds panning in for free.
    final f = (_offsetStart + _focalStart) / (plotW * _scaleStart);
    final newOffset = f * (plotW * newScale) - d.localFocalPoint.dx;

    setState(() {
      _scale = newScale;
      _offsetX = newOffset.clamp(0.0, _maxOffset(plotW)).toDouble();
    });
  }

  /// Maps a local touch X to the nearest reading index, accounting for the
  /// current scroll/zoom. Returns null if there's nothing to select.
  int? _indexAt(double localX) {
    final n = widget.readings.length;
    if (n == 0 || _plotW <= 0) return null;

    final tMin = widget.readings.first.readingAt.millisecondsSinceEpoch
        .toDouble();
    final tMax = widget.readings.last.readingAt.millisecondsSinceEpoch
        .toDouble();
    final tSpan = (tMax - tMin) == 0 ? 1.0 : (tMax - tMin);

    final virtualW = _plotW * _scale;
    final frac = ((_offsetX + localX) / virtualW).clamp(0.0, 1.0);
    final targetT = tMin + frac * tSpan;

    // Binary search the sorted readings for the closest timestamp.
    var lo = 0, hi = n - 1;
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      if (widget.readings[mid].readingAt.millisecondsSinceEpoch < targetT) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    if (lo > 0) {
      final a = widget.readings[lo - 1].readingAt.millisecondsSinceEpoch
          .toDouble();
      final b = widget.readings[lo].readingAt.millisecondsSinceEpoch.toDouble();
      if ((targetT - a).abs() <= (b - targetT).abs()) return lo - 1;
    }
    return lo;
  }

  void _select(double localX) {
    final i = _indexAt(localX);
    if (i != _selectedIndex) setState(() => _selectedIndex = i);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.readings.length < 2) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, c) {
        _plotW = c.maxWidth - _rightPad;
        // Defensive clamp in case layout changed since the last gesture.
        _offsetX = _offsetX.clamp(0.0, _maxOffset(_plotW)).toDouble();

        return GestureDetector(
          onScaleStart: _onScaleStart,
          onScaleUpdate: _onScaleUpdate,
          onTapUp: (d) => _select(d.localPosition.dx),
          onLongPressStart: (d) => _select(d.localPosition.dx),
          onLongPressMoveUpdate: (d) => _select(d.localPosition.dx),
          child: CustomPaint(
            painter: _TrendPainter(
              readings: widget.readings,
              scale: _scale,
              offsetX: _offsetX,
              yMin: _yMin,
              yMax: _yMax,
              selectedIndex: _selectedIndex,
            ),
            child: const SizedBox.expand(),
          ),
        );
      },
    );
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter({
    required this.readings,
    required this.scale,
    required this.offsetX,
    required this.yMin,
    required this.yMax,
    required this.selectedIndex,
  });

  final List<CgmReadingModel> readings;
  final double scale;
  final double offsetX;
  final double yMin;
  final double yMax;
  final int? selectedIndex;

  static const _rightPad = 34.0;
  static const _bottomPad = 22.0;
  static const _topPad = 10.0;
  static const _smooth = 0.18; // spline tension; gentle, no over-smoothing

  @override
  void paint(Canvas canvas, Size size) {
    final plot = Rect.fromLTRB(
      0,
      _topPad,
      size.width - _rightPad,
      size.height - _bottomPad,
    );

    final values = readings.map((r) => r.glucoseValue).toList(growable: false);
    final times = readings
        .map((r) => r.readingAt.millisecondsSinceEpoch.toDouble())
        .toList(growable: false);

    final vMin = values.reduce(math.min);
    final vMax = values.reduce(math.max);

    final tMin = times.first;
    final tMax = times.last;
    final tSpan = (tMax - tMin) == 0 ? 1.0 : (tMax - tMin);

    final virtualW = plot.width * scale;

    double dx(int i) =>
        plot.left + virtualW * (times[i] - tMin) / tSpan - offsetX;
    // Clamp to the fixed Y-domain so outlier readings clip at the chart
    // edge instead of stretching the axis / drawing full-height verticals.
    double dy(double v) {
      final cv = v.clamp(yMin, yMax);
      return plot.bottom - plot.height * (cv - yMin) / (yMax - yMin);
    }

    double timeAt(double screenX) =>
        tMin + ((offsetX + (screenX - plot.left)) / virtualW) * tSpan;

    // Band + dotted target lines first (these span the visible plot and are
    // positioned purely by Y, so they never move while scrolling).
    _paintTargetBand(canvas, plot, dy);

    // Visible index window (times are sorted → cheap to find).
    final iStart = _firstVisible(dx, plot, values.length);
    final iEnd = _lastVisible(dx, plot, values.length);

    canvas.save();
    canvas.clipRect(plot);
    _paintAreaAndLine(canvas, plot, values, dx, dy, iStart, iEnd);
    canvas.restore();

    _paintBandLabels(canvas, plot, dy);
    _paintAxis(canvas, plot, timeAt);
    _paintSpike(canvas, plot, values, dx, dy, vMin, vMax, iStart, iEnd);
    _paintLatestDot(canvas, plot, values, dx, dy);
    _paintTooltip(canvas, plot, values, dx, dy);
  }

  // --- Tap / long-press tooltip ---

  void _paintTooltip(
    Canvas canvas,
    Rect plot,
    List<double> values,
    double Function(int) dx,
    double Function(double) dy,
  ) {
    final idx = selectedIndex;
    if (idx == null || idx < 0 || idx >= readings.length) return;

    final px = dx(idx);
    if (px < plot.left || px > plot.right) return;

    final r = readings[idx];
    final py = dy(r.glucoseValue);
    final color = GlucoseTrendChart.zoneColor(r.glucoseValue);

    // Vertical guide + highlighted point.
    _dashedLine(
      canvas,
      Offset(px, plot.top),
      Offset(px, plot.bottom),
      const Color(0xFFB7BEC7),
    );
    canvas.drawCircle(
      Offset(px, py),
      7,
      Paint()..color = color.withValues(alpha: 0.18),
    );
    canvas.drawCircle(Offset(px, py), 5.5, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(px, py), 4, Paint()..color = color);

    // Tooltip text lines. readingAt is UTC; show device-local time.
    final timeStr = DateFormat('h:mm a').format(r.readingAt.toLocal());

    final l1 = _ttText(
      '${r.glucoseValue.round()} mg/dL',
      Colors.white,
      FontWeight.w800,
      14,
    );
    final l2 = _ttText(timeStr, const Color(0xFFC7CDD6), FontWeight.w500, 12);
    final l3 = _ttText(r.trend, color, FontWeight.w700, 12);

    const padH = 12.0, padV = 10.0, gap = 3.0;
    final boxW = [l1.width, l2.width, l3.width].reduce(math.max) + padH * 2;
    final boxH = l1.height + l2.height + l3.height + gap * 2 + padV * 2;

    var bx = px - boxW / 2;
    bx = bx.clamp(plot.left, plot.right - boxW);
    var by = py - boxH - 14;
    if (by < plot.top) by = py + 14; // flip below if no room above

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(bx, by, boxW, boxH),
      const Radius.circular(10),
    );
    canvas.drawRRect(rect, Paint()..color = const Color(0xF21B1F23));

    var ty = by + padV;
    l1.paint(canvas, Offset(bx + padH, ty));
    ty += l1.height + gap;
    l2.paint(canvas, Offset(bx + padH, ty));
    ty += l2.height + gap;
    l3.paint(canvas, Offset(bx + padH, ty));
  }

  TextPainter _ttText(String s, Color c, FontWeight w, double size) {
    return TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(color: c, fontWeight: w, fontSize: size),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  // --- Visibility culling (binary-ish scan over sorted points) ---

  int _firstVisible(double Function(int) dx, Rect plot, int n) {
    for (var i = 0; i < n; i++) {
      if (dx(i) >= plot.left - 4) return math.max(0, i - 1);
    }
    return 0;
  }

  int _lastVisible(double Function(int) dx, Rect plot, int n) {
    for (var i = n - 1; i >= 0; i--) {
      if (dx(i) <= plot.right + 4) return math.min(n - 1, i + 1);
    }
    return n - 1;
  }

  // --- Target band ---

  void _paintTargetBand(Canvas canvas, Rect plot, double Function(double) dy) {
    canvas.drawRect(
      Rect.fromLTRB(
        plot.left,
        dy(GlucoseTrendChart.targetHigh),
        plot.right,
        dy(GlucoseTrendChart.targetLow),
      ),
      Paint()..color = const Color(0x0A16A34A),
    );
    for (final level in [
      GlucoseTrendChart.targetHigh,
      GlucoseTrendChart.targetLow,
    ]) {
      final y = dy(level);
      _dashedLine(
        canvas,
        Offset(plot.left, y),
        Offset(plot.right, y),
        const Color(0xFFD7DCE2),
      );
    }
  }

  void _paintBandLabels(Canvas canvas, Rect plot, double Function(double) dy) {
    for (final entry in {
      GlucoseTrendChart.targetHigh: '110',
      GlucoseTrendChart.targetLow: '70',
    }.entries) {
      final y = dy(entry.key);
      final tp = _text(entry.value, DashboardTheme.textMuted, FontWeight.w600);
      tp.paint(canvas, Offset(plot.right + 8, y - tp.height / 2));
    }
  }

  // --- Smooth, range-coloured line + area fill ---

  void _paintAreaAndLine(
    Canvas canvas,
    Rect plot,
    List<double> values,
    double Function(int) dx,
    double Function(double) dy,
    int iStart,
    int iEnd,
  ) {
    Offset pt(int j) {
      final c = j.clamp(0, values.length - 1);
      return Offset(dx(c), dy(values[c]));
    }

    // Area fill under the smooth curve (single soft-green gradient).
    final area = Path()..moveTo(pt(iStart).dx, plot.bottom);
    area.lineTo(pt(iStart).dx, pt(iStart).dy);
    for (var i = iStart; i < iEnd; i++) {
      final p1 = pt(i);
      final p2 = pt(i + 1);
      final c1 = p1 + (pt(i + 1) - pt(i - 1)) * _smooth;
      final c2 = p2 - (pt(i + 2) - pt(i)) * _smooth;
      area.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
    }
    area.lineTo(pt(iEnd).dx, plot.bottom);
    area.close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x2616A34A), Color(0x0016A34A)],
        ).createShader(plot),
    );

    // Range-coloured spline: one cubic per segment, coloured by the zone of
    // its midpoint value so the line shifts green → amber → red.
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (var i = iStart; i < iEnd; i++) {
      final p1 = pt(i);
      final p2 = pt(i + 1);
      final c1 = p1 + (pt(i + 1) - pt(i - 1)) * _smooth;
      final c2 = p2 - (pt(i + 2) - pt(i)) * _smooth;

      line.color = GlucoseTrendChart.zoneColor((values[i] + values[i + 1]) / 2);
      final seg = Path()
        ..moveTo(p1.dx, p1.dy)
        ..cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
      canvas.drawPath(seg, line);
    }
  }

  // --- Axis (reflects the currently visible time window) ---

  void _paintAxis(Canvas canvas, Rect plot, double Function(double) timeAt) {
    const count = 4;
    for (var i = 0; i < count; i++) {
      final f = i / (count - 1);
      final screenX = plot.left + plot.width * f;
      final t = DateTime.fromMillisecondsSinceEpoch(timeAt(screenX).round());
      final label = DateFormat('h a').format(t).toLowerCase();

      final tp = _text(label, DashboardTheme.textMuted, FontWeight.w500);
      var x = screenX - tp.width / 2;
      x = x.clamp(plot.left, plot.right - tp.width);
      tp.paint(canvas, Offset(x, plot.bottom + 6));
    }
  }

  // --- Spike "+N" marker on the day's peak (if visible) ---

  void _paintSpike(
    Canvas canvas,
    Rect plot,
    List<double> values,
    double Function(int) dx,
    double Function(double) dy,
    double vMin,
    double vMax,
    int iStart,
    int iEnd,
  ) {
    // Only annotate a peak that actually fits the (robust) axis — an
    // off-axis outlier spike would just be misleading noise.
    if (vMax <= GlucoseTrendChart.targetHigh || vMax > yMax) return;

    var peak = iStart;
    for (var i = iStart; i <= iEnd; i++) {
      if (values[i] > values[peak]) peak = i;
    }
    if (values[peak] <= GlucoseTrendChart.targetHigh) return;

    final px = dx(peak);
    if (px < plot.left || px > plot.right) return;

    final py = dy(values[peak]);
    final rise = (values[peak] - vMin).round();

    final tp = _text(
      '+$rise',
      const Color(0xFFE5484D),
      FontWeight.w800,
      size: 12,
    );
    tp.paint(canvas, Offset(px - tp.width / 2, py - tp.height - 8));

    final tri = Path()
      ..moveTo(px - 4, py - 6)
      ..lineTo(px + 4, py - 6)
      ..lineTo(px, py - 1)
      ..close();
    canvas.drawPath(tri, Paint()..color = const Color(0xFFE5484D));
  }

  void _paintLatestDot(
    Canvas canvas,
    Rect plot,
    List<double> values,
    double Function(int) dx,
    double Function(double) dy,
  ) {
    final x = dx(values.length - 1);
    if (x < plot.left || x > plot.right) return;
    final y = dy(values.last);
    canvas.drawCircle(Offset(x, y), 5.5, Paint()..color = Colors.white);
    canvas.drawCircle(
      Offset(x, y),
      4,
      Paint()..color = GlucoseTrendChart.zoneColor(values.last),
    );
  }

  // --- helpers ---

  TextPainter _text(
    String s,
    Color color,
    FontWeight weight, {
    double size = 11,
  }) {
    return TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(color: color, fontSize: size, fontWeight: weight),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  void _dashedLine(Canvas canvas, Offset a, Offset b, Color color) {
    const dash = 5.0, gap = 4.0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    final total = (b - a).distance;
    final dir = (b - a) / total;
    var d = 0.0;
    while (d < total) {
      canvas.drawLine(a + dir * d, a + dir * math.min(d + dash, total), paint);
      d += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _TrendPainter old) =>
      old.readings != readings ||
      old.scale != scale ||
      old.offsetX != offsetX ||
      old.selectedIndex != selectedIndex ||
      old.yMin != yMin ||
      old.yMax != yMax;
}

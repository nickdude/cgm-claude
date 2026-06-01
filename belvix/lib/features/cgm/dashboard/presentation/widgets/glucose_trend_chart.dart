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
  const GlucoseTrendChart({
    super.key,
    required this.readings,
    this.onAddAtTime,
  });

  final List<CgmReadingModel> readings;

  /// Called when the user taps the "+" on a reading's tooltip — lets the
  /// host add food/insulin/exercise/finger-blood at that exact instant.
  final void Function(DateTime time)? onAddAtTime;

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

  // Absolute instant (UTC) at the tapped X — the time "where you clicked",
  // used for the tooltip label and the add action.
  DateTime? _selectedTime;

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
    final ms = _msAtX(localX);
    setState(() {
      _selectedIndex = i;
      _selectedTime = ms == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(ms.round(), isUtc: true);
    });
  }

  /// Absolute epoch-ms at a local touch X (the X-axis time you clicked).
  double? _msAtX(double localX) {
    if (widget.readings.length < 2 || _plotW <= 0) return null;
    final tMin = widget.readings.first.readingAt.millisecondsSinceEpoch
        .toDouble();
    final tMax = widget.readings.last.readingAt.millisecondsSinceEpoch
        .toDouble();
    final tSpan = (tMax - tMin) == 0 ? 1.0 : (tMax - tMin);
    final virtualW = _plotW * _scale;
    final frac = ((_offsetX + localX) / virtualW).clamp(0.0, 1.0);
    return tMin + frac * tSpan;
  }

  // Screen position of a reading — mirrors the painter's dx/dy so the
  // overlaid tooltip widget lines up with the painted guide + dot.
  double _xForIndex(int i) {
    final tMin = widget.readings.first.readingAt.millisecondsSinceEpoch
        .toDouble();
    final tMax = widget.readings.last.readingAt.millisecondsSinceEpoch
        .toDouble();
    final tSpan = (tMax - tMin) == 0 ? 1.0 : (tMax - tMin);
    final virtualW = _plotW * _scale;
    final t = widget.readings[i].readingAt.millisecondsSinceEpoch.toDouble();
    return virtualW * (t - tMin) / tSpan - _offsetX;
  }

  double _yForValue(double v, double height) {
    const topPad = 10.0, bottomPad = 22.0;
    final bottom = height - bottomPad;
    final cv = v.clamp(_yMin, _yMax);
    return bottom - (bottom - topPad) * (cv - _yMin) / (_yMax - _yMin);
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

        return Stack(
          clipBehavior: Clip.none,
          children: [
            GestureDetector(
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
            ),
            ..._buildTooltip(c.maxHeight),
          ],
        );
      },
    );
  }

  /// Tappable tooltip widget (value + time + "+" button) overlaid above
  /// the selected reading. Empty when nothing is selected / off-screen.
  List<Widget> _buildTooltip(double height) {
    final idx = _selectedIndex;
    if (idx == null || idx < 0 || idx >= widget.readings.length)
      return const [];

    final px = _xForIndex(idx);
    if (px < 0 || px > _plotW) return const [];

    final r = widget.readings[idx];
    final py = _yForValue(r.glucoseValue, height);
    final above = py > 76;

    // Keep the centred pill mostly on-screen at the edges.
    final tx = px.clamp(86.0, math.max(86.0, _plotW - 86.0)).toDouble();

    final time = _selectedTime ?? r.readingAt;

    return [
      Positioned(
        left: tx,
        top: above ? py - 12 : py + 12,
        child: FractionalTranslation(
          translation: Offset(-0.5, above ? -1.0 : 0.0),
          child: _AddTooltip(
            valueText: '${r.glucoseValue.round()} mg/dL',
            timeText: DateFormat('h:mm a').format(time.toLocal()),
            onAdd: () => widget.onAddAtTime?.call(time),
          ),
        ),
      ),
    ];
  }
}

/// Dark pill tooltip showing the reading + a green "+" button. The dark
/// surface is painted by [Material] (a reliable paint path) — a plain
/// BoxDecoration fill renders transparent on some devices.
class _AddTooltip extends StatelessWidget {
  const _AddTooltip({
    required this.valueText,
    required this.timeText,
    required this.onAdd,
  });

  final String valueText;
  final String timeText;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xF21B1F23),
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 7, 7, 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  valueText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  timeText,
                  style: const TextStyle(
                    color: Color(0xFFC7CDD6),
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Material(
              color: DashboardTheme.accent,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onAdd,
                child: const SizedBox(
                  width: 34,
                  height: 34,
                  child: Icon(Icons.add, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
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

    // Drop points that don't advance at least ~1px in X. Time-clustered
    // readings (sync/live bursts) would otherwise stack into a vertical
    // "comb" of oscillations; zooming in separates them and restores detail.
    final idx = _decimateVisible(dx, iStart, iEnd);

    canvas.save();
    canvas.clipRect(plot);
    _paintAreaAndLine(canvas, plot, values, dx, dy, idx);
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
    // The text box + "+" button are drawn as a Flutter widget overlay
    // (see _AddTooltip) so the button is tappable.
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

  /// Visible indices thinned so no two consecutive points are closer than
  /// ~1px in X — collapses time-clustered bursts that cause oscillation.
  List<int> _decimateVisible(double Function(int) dx, int iStart, int iEnd) {
    if (iEnd <= iStart) return [iStart, iEnd];
    const minDx = 1.0;
    final out = <int>[iStart];
    var lastX = dx(iStart);
    for (var i = iStart + 1; i < iEnd; i++) {
      final x = dx(i);
      if (x - lastX >= minDx) {
        out.add(i);
        lastX = x;
      }
    }
    out.add(iEnd);
    return out;
  }

  void _paintAreaAndLine(
    Canvas canvas,
    Rect plot,
    List<double> values,
    double Function(int) dx,
    double Function(double) dy,
    List<int> idx,
  ) {
    if (idx.length < 2) return;

    int rawAt(int k) => idx[k.clamp(0, idx.length - 1)].clamp(
      0,
      values.length - 1,
    );
    Offset pt(int k) {
      final j = rawAt(k);
      return Offset(dx(j), dy(values[j]));
    }

    double valAt(int k) => values[rawAt(k)];

    final n = idx.length;

    // Area fill under the smooth curve (single soft-green gradient).
    final area = Path()..moveTo(pt(0).dx, plot.bottom);
    area.lineTo(pt(0).dx, pt(0).dy);
    for (var k = 0; k < n - 1; k++) {
      final p1 = pt(k);
      final p2 = pt(k + 1);
      final c1 = p1 + (pt(k + 1) - pt(k - 1)) * _smooth;
      final c2 = p2 - (pt(k + 2) - pt(k)) * _smooth;
      area.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
    }
    area.lineTo(pt(n - 1).dx, plot.bottom);
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

    for (var k = 0; k < n - 1; k++) {
      final p1 = pt(k);
      final p2 = pt(k + 1);
      final c1 = p1 + (pt(k + 1) - pt(k - 1)) * _smooth;
      final c2 = p2 - (pt(k + 2) - pt(k)) * _smooth;

      line.color = GlucoseTrendChart.zoneColor((valAt(k) + valAt(k + 1)) / 2);
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

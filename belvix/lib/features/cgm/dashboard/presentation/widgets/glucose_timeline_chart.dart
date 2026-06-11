import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../data/models/cgm_reading_model.dart';
import '../../../timeline/data/models/timeline_event.dart';
import 'dashboard_theme.dart';

/// The chart's time axis is built from each reading's **wall-clock fields**
/// (the IST values the cards display) pinned to a fixed UTC basis, rather than
/// the absolute instant. This keeps the axis identical to the cards and free of
/// any device/browser-timezone conversion — reconstruct with `isUtc: true` and
/// format without `toLocal()` to read the same IST wall-clock back out. It also
/// normalises away the mixed live (local) / backend (UTC) instant conventions
/// so points sit in consistent positions.
double _wallMs(DateTime t) => DateTime.utc(
  t.year,
  t.month,
  t.day,
  t.hour,
  t.minute,
  t.second,
  t.millisecond,
).millisecondsSinceEpoch.toDouble();

/// Continuous, timestamp-based glucose timeline.
///
/// Unlike a per-day chart, this renders the *whole* loaded reading set on a
/// single absolute-time axis and shows a sliding **window** of it. Panning
/// scrolls through time across day boundaries; pinch zooms the window. Only
/// the visible slice is drawn (binary-search window + 1px decimation), so it
/// stays smooth with thousands of points. When the window nears the oldest
/// loaded reading it asks the host to load older history; because the window
/// is expressed in absolute time, prepended data never shifts the view.
class GlucoseTimelineChart extends StatefulWidget {
  const GlucoseTimelineChart({
    super.key,
    required this.readings,
    this.events = const [],
    this.onAddAtTime,
    this.onLoadOlder,
    this.onVisibleRangeChanged,
    this.onCenterChanged,
    this.onEventTap,
    this.initialWindow = const Duration(hours: 12),
  });

  /// All loaded readings (any order — sorted internally).
  final List<CgmReadingModel> readings;

  /// Health events rendered as tappable badges in the lane below the curve,
  /// positioned by their timestamp using the chart's own time→pixel mapping.
  final List<TimelineEvent> events;

  /// Tapped "+" on a reading's tooltip → add an entry at that instant.
  final void Function(DateTime time)? onAddAtTime;

  /// Called when the window approaches the oldest loaded reading so the host
  /// can fetch + prepend more history. Should be idempotent / de-duped.
  final VoidCallback? onLoadOlder;

  /// Fired (debounced) with the currently-visible [from, to] time range so the
  /// host can lazily load timeline events for what's on screen. Providing this
  /// also enables the event lane. `from`/`to` are wall-clock instants.
  final void Function(DateTime from, DateTime to)? onVisibleRangeChanged;

  /// Fired (live, per scroll frame) with the date at the **centre** of the
  /// visible window so the host can drive its own date header. When provided,
  /// the chart suppresses its built-in painted header to avoid duplication.
  final void Function(DateTime center)? onCenterChanged;

  /// Tapped an event badge in the lane → host shows its detail sheet.
  final void Function(TimelineEvent event)? onEventTap;

  final Duration initialWindow;

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
  State<GlucoseTimelineChart> createState() => _GlucoseTimelineChartState();
}

class _GlucoseTimelineChartState extends State<GlucoseTimelineChart> {
  static const _rightPad = 34.0; // 110 / 70 labels
  static const _minSpanMs = 30 * 60 * 1000.0; // 30 min
  static const _maxSpanMs = 14 * 24 * 60 * 60 * 1000.0; // 14 days

  // Sorted (oldest→newest) copy + its epoch-ms for fast lookups.
  late List<CgmReadingModel> _sorted;
  late List<double> _timesMs;

  // Fixed, robust Y-domain over ALL data so the axis doesn't jump on scroll.
  double _yMin = 70;
  double _yMax = 180;

  // Visible window, in absolute epoch-ms.
  double _winEnd = 0;
  double _winSpan = 0;

  double _plotW = 0;

  // Gesture anchors.
  double _spanStart = 0;
  double _focalTimeMs = 0;

  int? _selectedIndex;
  DateTime? _selectedTime;

  bool _olderRequested = false;
  double? _oldestLoadedMs;

  // --- Event markers (on the glucose line) ---
  static const double _laneMarker = 24;
  static const double _clusterGap = 20; // px below which events are a cluster
  static const double _stackStepPx = 24; // vertical lift per stacked marker
  static const int _maxStack = 3;

  late List<TimelineEvent> _sortedEvents;
  late List<double> _eventsMs;

  bool get _laneEnabled => widget.onVisibleRangeChanged != null;

  // Debounced visible-range reporting for lazy loading.
  Timer? _rangeDebounce;
  String? _lastRangeKey;
  bool _initReported = false;

  @override
  void initState() {
    super.initState();
    _ingest(initial: true);
    _ingestEvents();
  }

  @override
  void didUpdateWidget(covariant GlucoseTimelineChart old) {
    super.didUpdateWidget(old);
    if (!identical(old.readings, widget.readings)) {
      _ingest(initial: false);
    }
    if (!identical(old.events, widget.events)) {
      _ingestEvents();
    }
  }

  @override
  void dispose() {
    _rangeDebounce?.cancel();
    super.dispose();
  }

  void _ingestEvents() {
    _sortedEvents = List<TimelineEvent>.of(widget.events)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    _eventsMs =
        _sortedEvents.map((e) => _wallMs(e.timestamp)).toList(growable: false);
  }

  // --- visible-range reporting (drives lazy loading) ---

  void _scheduleReportRange() {
    if (!_laneEnabled) return;
    _rangeDebounce?.cancel();
    _rangeDebounce = Timer(
      const Duration(milliseconds: 280),
      _reportRangeNow,
    );
  }

  void _reportRangeNow() {
    if (!_laneEnabled || _winSpan <= 0 || _plotW <= 0) return;
    final fromMs = _winEnd - _winSpan;
    final toMs = _winEnd;
    // Round to the minute so trivial sub-pixel scrolls don't re-fire.
    final key = '${(fromMs / 60000).round()}_${(toMs / 60000).round()}';
    if (key == _lastRangeKey) return;
    _lastRangeKey = key;
    widget.onVisibleRangeChanged!(
      DateTime.fromMillisecondsSinceEpoch(fromMs.round(), isUtc: true),
      DateTime.fromMillisecondsSinceEpoch(toMs.round(), isUtc: true),
    );
  }

  /// Live (un-debounced) centre-date report so the host's date header tracks
  /// the scroll smoothly.
  void _reportCenter() {
    if (widget.onCenterChanged == null || _winSpan <= 0) return;
    final centerMs = _winEnd - _winSpan / 2;
    widget.onCenterChanged!(
      DateTime.fromMillisecondsSinceEpoch(centerMs.round(), isUtc: true),
    );
  }

  void _ingest({required bool initial}) {
    _sorted = List<CgmReadingModel>.of(widget.readings)
      ..sort((a, b) => a.readingAt.compareTo(b.readingAt));
    _timesMs = _sorted
        .map((r) => _wallMs(r.readingAt))
        .toList(growable: false);

    _computeDomain();

    if (_sorted.isEmpty) return;

    if (initial || _winSpan == 0) {
      // Open on the most recent `initialWindow` of data.
      _winSpan = widget.initialWindow.inMilliseconds.toDouble();
      _winEnd = _timesMs.last + _winSpan * 0.04;
    }

    // Only re-arm the load-older request if older data was actually
    // prepended — otherwise an idempotent fetch would loop forever.
    final newOldest = _timesMs.first;
    if (initial || _oldestLoadedMs == null || newOldest < _oldestLoadedMs!) {
      _olderRequested = false;
    }
    _oldestLoadedMs = newOldest;

    // Window stays put (absolute time) — prepended data never shifts the view.
    if (_plotW > 0) _winEnd = _clampEnd(_winEnd, _winSpan);

    if (_selectedIndex != null && _selectedIndex! >= _sorted.length) {
      _selectedIndex = null;
    }
  }

  void _computeDomain() {
    if (_sorted.isEmpty) return;
    final values = _sorted.map((r) => r.glucoseValue).toList()..sort();
    double pct(double p) =>
        values[(p * (values.length - 1)).round().clamp(0, values.length - 1)];
    _yMin = (pct(0.05) - 15).clamp(40.0, 75.0).toDouble();
    _yMax = (pct(0.92) + 25).clamp(170.0, 300.0).toDouble();
  }

  // --- window math ---

  double get _dataMin => _timesMs.first;
  double get _dataMax => _timesMs.last;

  /// Clamp the window's right edge so it stays over the data (with a small
  /// right margin), pinning to the newest when the window is wider than the
  /// whole dataset.
  double _clampEnd(double end, double span) {
    final rightMargin = span * 0.06;
    final maxEnd = _dataMax + rightMargin;
    final minEnd = _dataMin + span; // winStart can't go past the oldest
    final lo = math.min(minEnd, maxEnd);
    return end.clamp(lo, maxEnd).toDouble();
  }

  double _xForMs(double ms) {
    final start = _winEnd - _winSpan;
    return (ms - start) / _winSpan * _plotW;
  }

  double _msForX(double x) => (_winEnd - _winSpan) + (x / _plotW) * _winSpan;

  double _yForValue(double v, double height) {
    const topPad = 10.0, bottomPad = 22.0;
    final bottom = height - bottomPad;
    final cv = v.clamp(_yMin, _yMax);
    return bottom - (bottom - topPad) * (cv - _yMin) / (_yMax - _yMin);
  }

  void _maybeLoadOlder() {
    if (_olderRequested || widget.onLoadOlder == null || _sorted.isEmpty) {
      return;
    }
    final start = _winEnd - _winSpan;
    if (start <= _dataMin + _winSpan * 0.3) {
      _olderRequested = true;
      widget.onLoadOlder!();
    }
  }

  // --- gestures (custom recognizer yields vertical drags to the page) ---

  void _onScaleStart(ScaleStartDetails d) {
    _spanStart = _winSpan;
    _focalTimeMs = _msForX(d.localFocalPoint.dx);
  }

  void _onScaleUpdate(ScaleUpdateDetails d) {
    if (_plotW <= 0) return;
    final newSpan = (_spanStart / d.scale).clamp(_minSpanMs, _maxSpanMs);
    // Keep the time that was under the focal point pinned there (folds pan in).
    final start = _focalTimeMs - (d.localFocalPoint.dx / _plotW) * newSpan;
    setState(() {
      _winSpan = newSpan;
      _winEnd = _clampEnd(start + newSpan, newSpan);
    });
    _maybeLoadOlder();
    _scheduleReportRange();
    _reportCenter();
  }

  int? _indexAtX(double x) {
    if (_sorted.isEmpty) return null;
    final targetMs = _msForX(x);
    var lo = 0, hi = _timesMs.length - 1;
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      if (_timesMs[mid] < targetMs) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    if (lo > 0 &&
        (targetMs - _timesMs[lo - 1]).abs() <=
            (_timesMs[lo] - targetMs).abs()) {
      return lo - 1;
    }
    return lo;
  }

  void _select(double x) {
    final i = _indexAtX(x);
    setState(() {
      _selectedIndex = i;
      _selectedTime = DateTime.fromMillisecondsSinceEpoch(
        _msForX(x).round(),
        isUtc: true,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_sorted.length < 2) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, c) {
        _plotW = c.maxWidth - _rightPad;
        _winEnd = _clampEnd(_winEnd, _winSpan);

        // Report the initial visible range + centre once the window + width
        // are known (so lazy loading + the date header start correct).
        if (!_initReported && _winSpan > 0 && _plotW > 0) {
          _initReported = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _reportRangeNow();
            _reportCenter();
          });
        }

        return Stack(
          clipBehavior: Clip.none,
          children: [
            RawGestureDetector(
              gestures: {
                _TimelineScaleRecognizer:
                    GestureRecognizerFactoryWithHandlers<
                      _TimelineScaleRecognizer
                    >(
                      () => _TimelineScaleRecognizer(),
                      (r) {
                        r.onStart = _onScaleStart;
                        r.onUpdate = _onScaleUpdate;
                      },
                    ),
                TapGestureRecognizer:
                    GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
                      () => TapGestureRecognizer(),
                      (r) => r.onTapUp = (d) => _select(d.localPosition.dx),
                    ),
                LongPressGestureRecognizer:
                    GestureRecognizerFactoryWithHandlers<
                      LongPressGestureRecognizer
                    >(
                      () => LongPressGestureRecognizer(),
                      (r) {
                        r.onLongPressStart = (d) =>
                            _select(d.localPosition.dx);
                        r.onLongPressMoveUpdate = (d) =>
                            _select(d.localPosition.dx);
                      },
                    ),
              },
              child: CustomPaint(
                painter: _TimelinePainter(
                  sorted: _sorted,
                  timesMs: _timesMs,
                  winEnd: _winEnd,
                  winSpan: _winSpan,
                  yMin: _yMin,
                  yMax: _yMax,
                  selectedIndex: _selectedIndex,
                  showHeader: widget.onCenterChanged == null,
                ),
                child: const SizedBox.expand(),
              ),
            ),
            ..._buildTooltip(c.maxHeight),
            ..._buildEventLane(c.maxHeight),
          ],
        );
      },
    );
  }

  // Plot insets — mirror [_TimelinePainter] so markers land exactly on the
  // painted curve.
  static const double _curveTopPad = 26;
  static const double _curveBottomPad = 22;

  /// Maps a glucose value to the same y the painter draws the curve at.
  double _curveY(double v, double height) {
    final top = _curveTopPad;
    final bottom = height - _curveBottomPad;
    final cv = v.clamp(_yMin, _yMax);
    return bottom - (bottom - top) * (cv - _yMin) / (_yMax - _yMin);
  }

  /// Glucose value at an arbitrary instant, linearly interpolated between the
  /// two nearest readings (clamped to the ends), so a marker can sit on the
  /// line even between sample points.
  double _valueAtMs(double ms) {
    if (_sorted.isEmpty) return _yMin;
    if (ms <= _timesMs.first) return _sorted.first.glucoseValue;
    if (ms >= _timesMs.last) return _sorted.last.glucoseValue;

    var lo = 0, hi = _timesMs.length - 1;
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      if (_timesMs[mid] < ms) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    final i1 = lo, i0 = lo - 1;
    final t0 = _timesMs[i0], t1 = _timesMs[i1];
    final v0 = _sorted[i0].glucoseValue, v1 = _sorted[i1].glucoseValue;
    final f = (t1 == t0) ? 0.0 : (ms - t0) / (t1 - t0);
    return v0 + (v1 - v0) * f;
  }

  /// Event badges placed **on the glucose line** at each event's exact (x, y):
  /// x from the shared time→pixel mapping, y from the glucose value at that
  /// instant. Overlapping events stack straight up so the x stays exact.
  List<Widget> _buildEventLane(double height) {
    if (!_laneEnabled || _sortedEvents.isEmpty || _plotW <= 0) {
      return const [];
    }

    final m = _laneMarker;
    final half = m / 2;
    final topLimit = _curveTopPad + half;
    final bottomLimit = height - _curveBottomPad - half;

    final out = <Widget>[];

    // Events are sorted by time → x is monotonic; cluster by running gap and
    // stack each cluster vertically (x stays exact).
    double? clusterStartX;
    var level = 0;

    for (var i = 0; i < _sortedEvents.length; i++) {
      final x = _xForMs(_eventsMs[i]);
      if (x < -m || x > _plotW + m) {
        clusterStartX = null;
        level = 0;
        continue;
      }

      if (clusterStartX != null && (x - clusterStartX) < _clusterGap) {
        level = (level + 1).clamp(0, _maxStack);
      } else {
        clusterStartX = x;
        level = 0;
      }

      final event = _sortedEvents[i];
      final curveY = _curveY(_valueAtMs(_eventsMs[i]), height);
      final y = (curveY - level * _stackStepPx)
          .clamp(topLimit, bottomLimit)
          .toDouble();

      out.add(
        Positioned(
          left: x - half,
          top: y - half,
          child: _LaneMarker(
            event: event,
            size: m,
            onTap: () => widget.onEventTap?.call(event),
          ),
        ),
      );
    }
    return out;
  }

  List<Widget> _buildTooltip(double height) {
    final idx = _selectedIndex;
    if (idx == null || idx < 0 || idx >= _sorted.length) return const [];

    final px = _xForMs(_timesMs[idx]);
    if (px < 0 || px > _plotW) return const [];

    final r = _sorted[idx];
    final py = _yForValue(r.glucoseValue, height);
    final above = py > 76;
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
            // Format the IST wall-clock directly (no toLocal) so the tooltip
            // matches the cards and the axis.
            timeText: DateFormat('MMM d • h:mm a').format(time),
            // Log against the selected reading's actual time.
            onAdd: () => widget.onAddAtTime?.call(r.readingAt),
          ),
        ),
      ),
    ];
  }
}

class _TimelinePainter extends CustomPainter {
  _TimelinePainter({
    required this.sorted,
    required this.timesMs,
    required this.winEnd,
    required this.winSpan,
    required this.yMin,
    required this.yMax,
    required this.selectedIndex,
    this.showHeader = true,
  });

  final List<CgmReadingModel> sorted;
  final List<double> timesMs;
  final double winEnd;
  final double winSpan;
  final double yMin;
  final double yMax;
  final int? selectedIndex;

  /// Paint the built-in centre-date header. Suppressed when the host renders
  /// its own date label (driven by `onCenterChanged`).
  final bool showHeader;

  static const _rightPad = 34.0;
  static const _bottomPad = 22.0;
  static const _topPad = 26.0; // room for the dynamic date header
  static const _smooth = 0.18;

  double get _winStart => winEnd - winSpan;

  @override
  void paint(Canvas canvas, Size size) {
    final plot = Rect.fromLTRB(
      0,
      _topPad,
      size.width - _rightPad,
      size.height - _bottomPad,
    );

    double dx(int i) => plot.left + (timesMs[i] - _winStart) / winSpan * plot.width;
    double dy(double v) {
      final cv = v.clamp(yMin, yMax);
      return plot.bottom - plot.height * (cv - yMin) / (yMax - yMin);
    }

    double timeAt(double sx) => _winStart + (sx - plot.left) / plot.width * winSpan;

    _paintBand(canvas, plot, dy);

    // Visible index window (one beyond each edge so the line reaches off-screen).
    final iStart = _lowerBound(_winStart) - 1;
    final iEnd = _lowerBound(winEnd) + 1;
    final s = iStart.clamp(0, sorted.length - 1);
    final e = iEnd.clamp(0, sorted.length - 1);

    final idx = _decimate(dx, s, e);

    canvas.save();
    canvas.clipRect(plot);
    _paintAreaAndLine(canvas, plot, dx, dy, idx);
    canvas.restore();

    _paintBandLabels(canvas, plot, dy);
    _paintAxis(canvas, plot, timeAt);
    if (showHeader) _paintRangeHeader(canvas, plot, timeAt);
    _paintTooltipGuide(canvas, plot, dx, dy);
  }

  int _lowerBound(double ms) {
    var lo = 0, hi = timesMs.length;
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      if (timesMs[mid] < ms) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    return lo;
  }

  List<int> _decimate(double Function(int) dx, int s, int e) {
    if (e <= s) return [s, e];
    const minDx = 1.0;
    final out = <int>[s];
    var lastX = dx(s);
    for (var i = s + 1; i < e; i++) {
      final x = dx(i);
      if (x - lastX >= minDx) {
        out.add(i);
        lastX = x;
      }
    }
    out.add(e);
    return out;
  }

  void _paintBand(Canvas canvas, Rect plot, double Function(double) dy) {
    canvas.drawRect(
      Rect.fromLTRB(
        plot.left,
        dy(GlucoseTimelineChart.targetHigh),
        plot.right,
        dy(GlucoseTimelineChart.targetLow),
      ),
      Paint()..color = const Color(0x0A16A34A),
    );
    for (final level in [
      GlucoseTimelineChart.targetHigh,
      GlucoseTimelineChart.targetLow,
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
      GlucoseTimelineChart.targetHigh: '110',
      GlucoseTimelineChart.targetLow: '70',
    }.entries) {
      final y = dy(entry.key);
      final tp = _text(entry.value, DashboardTheme.textMuted, FontWeight.w600);
      tp.paint(canvas, Offset(plot.right + 8, y - tp.height / 2));
    }
  }

  void _paintAreaAndLine(
    Canvas canvas,
    Rect plot,
    double Function(int) dx,
    double Function(double) dy,
    List<int> idx,
  ) {
    if (idx.length < 2) return;

    int raw(int k) => idx[k.clamp(0, idx.length - 1)];
    Offset pt(int k) {
      final j = raw(k);
      return Offset(dx(j), dy(sorted[j].glucoseValue));
    }

    double valAt(int k) => sorted[raw(k)].glucoseValue;
    final n = idx.length;

    final area = Path()
      ..moveTo(pt(0).dx, plot.bottom)
      ..lineTo(pt(0).dx, pt(0).dy);
    for (var k = 0; k < n - 1; k++) {
      final p1 = pt(k), p2 = pt(k + 1);
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

    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (var k = 0; k < n - 1; k++) {
      final p1 = pt(k), p2 = pt(k + 1);
      final c1 = p1 + (pt(k + 1) - pt(k - 1)) * _smooth;
      final c2 = p2 - (pt(k + 2) - pt(k)) * _smooth;
      line.color = GlucoseTimelineChart.zoneColor((valAt(k) + valAt(k + 1)) / 2);
      canvas.drawPath(
        Path()
          ..moveTo(p1.dx, p1.dy)
          ..cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy),
        line,
      );
    }
  }

  /// Bottom time axis — labels adapt to the window span (times within a day,
  /// dates when zoomed out across days).
  void _paintAxis(Canvas canvas, Rect plot, double Function(double) timeAt) {
    final multiDay = winSpan > 36 * 60 * 60 * 1000.0;
    final fmt = DateFormat(multiDay ? 'MMM d' : 'h a');
    const count = 4;
    for (var i = 0; i < count; i++) {
      final f = i / (count - 1);
      final sx = plot.left + plot.width * f;
      final t = DateTime.fromMillisecondsSinceEpoch(
        timeAt(sx).round(),
        isUtc: true,
      );
      final label = fmt.format(t).toLowerCase();
      final tp = _text(label, DashboardTheme.textMuted, FontWeight.w500);
      var x = sx - tp.width / 2;
      x = x.clamp(plot.left, plot.right - tp.width);
      tp.paint(canvas, Offset(x, plot.bottom + 6));
    }
  }

  /// Date header driven by the **centre** of the visible window, so it shows
  /// the date the user is currently looking at and updates as they scroll.
  void _paintRangeHeader(Canvas canvas, Rect plot, double Function(double) timeAt) {
    final center = DateTime.fromMillisecondsSinceEpoch(
      timeAt(plot.center.dx).round(),
      isUtc: true,
    );
    final label = DateFormat('EEE, d MMM yyyy').format(center);
    final tp = _text(label, DashboardTheme.textSecondary, FontWeight.w700, size: 12.5);
    tp.paint(canvas, Offset(plot.left, 4));
  }

  void _paintTooltipGuide(
    Canvas canvas,
    Rect plot,
    double Function(int) dx,
    double Function(double) dy,
  ) {
    final idx = selectedIndex;
    if (idx == null || idx < 0 || idx >= sorted.length) return;
    final px = dx(idx);
    if (px < plot.left || px > plot.right) return;
    final r = sorted[idx];
    final py = dy(r.glucoseValue);
    final color = GlucoseTimelineChart.zoneColor(r.glucoseValue);
    _dashedLine(
      canvas,
      Offset(px, plot.top),
      Offset(px, plot.bottom),
      const Color(0xFFB7BEC7),
    );
    canvas.drawCircle(Offset(px, py), 7, Paint()..color = color.withValues(alpha: 0.18));
    canvas.drawCircle(Offset(px, py), 5.5, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(px, py), 4, Paint()..color = color);
  }

  TextPainter _text(String s, Color c, FontWeight w, {double size = 11}) {
    return TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(color: c, fontSize: size, fontWeight: w),
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
    if (total == 0) return;
    final dir = (b - a) / total;
    var d = 0.0;
    while (d < total) {
      canvas.drawLine(a + dir * d, a + dir * math.min(d + dash, total), paint);
      d += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _TimelinePainter old) =>
      old.winEnd != winEnd ||
      old.winSpan != winSpan ||
      old.selectedIndex != selectedIndex ||
      old.yMin != yMin ||
      old.yMax != yMax ||
      old.showHeader != showHeader ||
      !identical(old.sorted, sorted);
}

/// A single SVG event badge on the curve. White-circle SVG (carries its own
/// ring + glyph) with a soft circular shadow for elevation; fully tappable.
class _LaneMarker extends StatelessWidget {
  const _LaneMarker({
    required this.event,
    required this.size,
    required this.onTap,
  });

  final TimelineEvent event;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF101418).withValues(alpha: 0.16),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: SvgPicture.asset(
          event.asset,
          width: size,
          height: size,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

/// ScaleGestureRecognizer that yields single-finger VERTICAL drags to the
/// enclosing scroll view (so the page still scrolls) while keeping horizontal
/// pan + pinch zoom.
class _TimelineScaleRecognizer extends ScaleGestureRecognizer {
  final Map<int, Offset> _downAt = {};
  bool _decided = false;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    _downAt[event.pointer] = event.position;
    if (_downAt.length >= 2) _decided = true;
    super.addAllowedPointer(event);
  }

  @override
  void handleEvent(PointerEvent event) {
    if (!_decided && _downAt.length == 1 && event is PointerMoveEvent) {
      final start = _downAt[event.pointer];
      if (start != null) {
        final delta = event.position - start;
        if (delta.distance >= kTouchSlop) {
          if (delta.dy.abs() > delta.dx.abs()) {
            _decided = true;
            resolve(GestureDisposition.rejected);
            super.handleEvent(event);
            return;
          }
          _decided = true;
        }
      }
    }
    super.handleEvent(event);
  }

  @override
  void didStopTrackingLastPointer(int pointer) {
    _downAt.clear();
    _decided = false;
    super.didStopTrackingLastPointer(pointer);
  }
}

/// Dark pill tooltip with a green "+" button (Material-painted so it renders
/// reliably).
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

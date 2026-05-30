import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../app/theme/app_colors.dart';

class GlucoseChart extends StatefulWidget {
  const GlucoseChart({
    super.key,
    required this.spots,
    this.timestamps = const [],
    this.onZoomChanged,
  });

  final List<FlSpot> spots;
  final List<DateTime> timestamps;
  final ValueChanged<double>? onZoomChanged;

  @override
  State<GlucoseChart> createState() => _GlucoseChartState();
}

class _GlucoseChartState extends State<GlucoseChart> {
  static const double _minZoom = 1.0;
  static const double _maxZoom = 4.0;
  static const double _basePointSpacing = 52.0;

  double _timeZoom = 1.0;
  double _scaleStart = 1.0;

  @override
  Widget build(BuildContext context) {
    if (widget.spots.isEmpty) {
      return const SizedBox.shrink();
    }

    final values = widget.spots.map((spot) => spot.y).toList(growable: false);
    final minValue = values.reduce(math.min);
    final maxValue = values.reduce(math.max);
    final minX = 0.0;
    final maxX = (widget.spots.length - 1).toDouble();
    final xSpanCount = math.max(widget.spots.length - 1, 1).toDouble();
    // Dynamic y-axis — the visible range hugs the actual readings so
    // extreme spikes (≥240 mg/dL) and severe lows (<60) aren't clipped.
    // The clamp floors/ceilings only guard against zero-height domains
    // when all readings sit close together.
    final rawSpan = (maxValue - minValue).abs();
    final pad = (rawSpan * 0.12).clamp(12.0, 40.0).toDouble();
    final yMin = (minValue - pad).clamp(20.0, 180.0).toDouble();
    final yMax = (maxValue + pad).clamp(140.0, 600.0).toDouble();
    // Compute a nice round interval so ~5 labels show regardless of
    // how tall the visible range is.
    final ySpan = yMax - yMin;
    final yInterval = _niceInterval(ySpan / 5);
    final chartWidth = math.max(
      widget.spots.length * _basePointSpacing * _timeZoom,
      360.0,
    );
    final horizontalInterval = math.max(
      1.0,
      (xSpanCount / (5 * _timeZoom)).roundToDouble(),
    );

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFAFBFC),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 0),
            child: Align(
              alignment: Alignment.centerRight,
              child: _ZoomChip(
                label: '${(_timeZoom * 100).round()}%',
                icon: Icons.schedule_rounded,
              ),
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onScaleStart: (_) {
                    _scaleStart = _timeZoom;
                  },
                  onScaleUpdate: (details) {
                    if (details.pointerCount < 2) return;

                    final nextZoom = (_scaleStart * details.scale)
                        .clamp(_minZoom, _maxZoom)
                        .toDouble();
                    if ((nextZoom - _timeZoom).abs() < 0.01) return;

                    setState(() {
                      _timeZoom = nextZoom;
                    });
                    widget.onZoomChanged?.call(_timeZoom);
                  },
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      tween: Tween<double>(end: chartWidth),
                      builder: (context, animatedWidth, _) {
                        return SizedBox(
                          width: animatedWidth,
                          height: constraints.maxHeight,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(12, 6, 18, 8),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 220),
                              switchInCurve: Curves.easeOut,
                              switchOutCurve: Curves.easeIn,
                              child: LineChart(
                                key: ValueKey(
                                  '${widget.spots.length}-${_timeZoom.toStringAsFixed(2)}',
                                ),
                                LineChartData(
                                  minX: minX,
                                  maxX: maxX == minX ? minX + 1 : maxX,
                                  minY: yMin,
                                  maxY: yMax,
                                  clipData: const FlClipData.all(),
                                  lineTouchData: LineTouchData(
                                    enabled: true,
                                    handleBuiltInTouches: true,
                                    touchSpotThreshold: 18,
                                    getTouchedSpotIndicator:
                                        (barData, indexes) {
                                      return indexes.map((i) {
                                        return TouchedSpotIndicatorData(
                                          FlLine(
                                            color: const Color(0xFF1F8B4C)
                                                .withValues(alpha: 0.35),
                                            strokeWidth: 1.4,
                                            dashArray: [4, 4],
                                          ),
                                          FlDotData(
                                            getDotPainter:
                                                (spot, percent, bar, idx) {
                                              return FlDotCirclePainter(
                                                radius: 6,
                                                color: Colors.white,
                                                strokeWidth: 3,
                                                strokeColor:
                                                    const Color(0xFF1F8B4C),
                                              );
                                            },
                                          ),
                                        );
                                      }).toList();
                                    },
                                    touchTooltipData: LineTouchTooltipData(
                                      tooltipRoundedRadius: 999,
                                      tooltipPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 10,
                                      ),
                                      tooltipMargin: 12,
                                      getTooltipColor: (_) =>
                                          const Color(0xFF1B1F23),
                                      getTooltipItems: (touchedSpots) {
                                        return touchedSpots.map((spot) {
                                          final index = spot.x.round();
                                          final timestamp =
                                              _timestampForIndex(index);
                                          final formattedTime = DateFormat(
                                            'h:mm a',
                                          ).format(timestamp);

                                          return LineTooltipItem(
                                            '${spot.y.toStringAsFixed(0)} mg/dL',
                                            const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 13,
                                            ),
                                            children: [
                                              TextSpan(
                                                text: '  ·  $formattedTime',
                                                style: TextStyle(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.7),
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 11.5,
                                                ),
                                              ),
                                            ],
                                          );
                                        }).toList();
                                      },
                                    ),
                                  ),
                                  gridData: FlGridData(
                                    show: true,
                                    drawVerticalLine: false,
                                    horizontalInterval:
                                        yInterval,
                                    getDrawingHorizontalLine: (value) {
                                      return const FlLine(
                                        color: Color(0xFFE6E8EC),
                                        strokeWidth: 0.8,
                                        dashArray: [4, 6],
                                      );
                                    },
                                  ),
                                  borderData: FlBorderData(show: false),
                                  extraLinesData: ExtraLinesData(
                                    horizontalLines: [
                                      HorizontalLine(
                                        y: 70,
                                        color: const Color(0xFF1F8B4C)
                                            .withValues(alpha: 0.35),
                                        strokeWidth: 1.2,
                                        dashArray: [4, 6],
                                      ),
                                      HorizontalLine(
                                        y: 110,
                                        color: const Color(0xFFA0A6AE),
                                        strokeWidth: 0.8,
                                        dashArray: [4, 6],
                                      ),
                                      HorizontalLine(
                                        y: 180,
                                        color: const Color(0xFFE89E2A)
                                            .withValues(alpha: 0.45),
                                        strokeWidth: 1.2,
                                        dashArray: [4, 6],
                                      ),
                                    ],
                                  ),
                                  titlesData: FlTitlesData(
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 42,
                                        interval:
                                            ((yMax - yMin) / 4).clamp(
                                          20,
                                          40,
                                        ),
                                        getTitlesWidget: (value, meta) {
                                          if (value == yMin ||
                                              value == yMax) {
                                            return const SizedBox.shrink();
                                          }

                                          return Padding(
                                            padding: const EdgeInsets.only(
                                              right: 8,
                                            ),
                                            child: Text(
                                              value.toInt().toString(),
                                              style: const TextStyle(
                                                color: Color(0xFF8190A5),
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 34,
                                        interval: horizontalInterval,
                                        getTitlesWidget: (value, meta) {
                                          if (value < minX || value > maxX) {
                                            return const SizedBox.shrink();
                                          }

                                          final label = _timeLabelForBottom(value);
                                          if (label == null) {
                                            return const SizedBox.shrink();
                                          }

                                          return Padding(
                                            padding: const EdgeInsets.only(
                                              top: 6,
                                            ),
                                            child: Text(
                                              label,
                                              style: const TextStyle(
                                                color: Color(0xFF7B8794),
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    topTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 28,
                                        interval: horizontalInterval,
                                        getTitlesWidget: (value, meta) {
                                          if (value < minX || value > maxX) {
                                            return const SizedBox.shrink();
                                          }

                                          final label = _timeLabelForTop(value);
                                          if (label == null) {
                                            return const SizedBox.shrink();
                                          }

                                          return Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 4,
                                            ),
                                            child: Text(
                                              label,
                                              style: const TextStyle(
                                                color: Color(0xFF64748B),
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    rightTitles: const AxisTitles(
                                      sideTitles:
                                          SideTitles(showTitles: false),
                                    ),
                                  ),
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: widget.spots,
                                      isCurved: true,
                                      curveSmoothness: 0.32,
                                      preventCurveOverShooting: true,
                                      isStrokeCapRound: true,
                                      barWidth: 2.6,
                                      color: const Color(0xFF1F8B4C),
                                      belowBarData: BarAreaData(
                                        show: true,
                                        gradient: LinearGradient(
                                          colors: [
                                            const Color(0xFF1F8B4C)
                                                .withValues(alpha: 0.22),
                                            const Color(0xFF1F8B4C)
                                                .withValues(alpha: 0.0),
                                          ],
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                        ),
                                      ),
                                      dotData: const FlDotData(show: false),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  DateTime _timestampForIndex(int index) {
    if (widget.timestamps.isNotEmpty && index < widget.timestamps.length) {
      return widget.timestamps[index];
    }

    return DateTime.now().add(Duration(minutes: index));
  }

  String? _timeLabelForBottom(double xValue) {
    if (xValue.isNaN || xValue.isInfinite) {
      return null;
    }

    final timestamp = _timestampForIndex(xValue.round());
    return DateFormat('h:mm a').format(timestamp);
  }

  String? _timeLabelForTop(double xValue) {
    if (xValue.isNaN || xValue.isInfinite) {
      return null;
    }

    final timestamp = _timestampForIndex(xValue.round());
    return DateFormat('MMM d').format(timestamp);
  }

  /// Rounds [raw] up to the next "nice" axis step (10, 20, 25, 50, 100…)
  /// so the y-axis grid lands on multiples a clinician would expect to
  /// read at a glance, regardless of how tall the dynamic range is.
  static double _niceInterval(double raw) {
    if (raw <= 0 || raw.isNaN || raw.isInfinite) return 20;

    const steps = [10, 20, 25, 50, 100, 150, 200];
    for (final s in steps) {
      if (raw <= s) return s.toDouble();
    }
    return 250;
  }
}

class _ZoomChip extends StatelessWidget {
  const _ZoomChip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE3EAF4)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 15, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

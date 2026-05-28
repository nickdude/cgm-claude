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
    final yMin = (minValue - 18).clamp(50.0, 220.0).toDouble();
    final yMax = (maxValue + 24).clamp(90.0, 280.0).toDouble();
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
        gradient: const LinearGradient(
          colors: [Color(0xFFF8FBFF), Color(0xFFF4F7FC)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE2EAF4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Glucose trend',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Pinch with two fingers to zoom the time axis',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
                _ZoomChip(
                  label: '${(_timeZoom * 100).round()}%',
                  icon: Icons.schedule_rounded,
                ),
              ],
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
                                    touchTooltipData: LineTouchTooltipData(
                                      tooltipRoundedRadius: 14,
                                      tooltipPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      getTooltipColor: (_) =>
                                          const Color(0xFF101828),
                                      getTooltipItems: (touchedSpots) {
                                        return touchedSpots.map((spot) {
                                          final index = spot.x.round();
                                          final timestamp = _timestampForIndex(index);
                                          final formattedTime = DateFormat(
                                            'MMM d, h:mm a',
                                          ).format(timestamp);

                                          return LineTooltipItem(
                                            '$formattedTime\n${spot.y.toStringAsFixed(0)} mg/dL',
                                            const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 12,
                                            ),
                                          );
                                        }).toList();
                                      },
                                    ),
                                  ),
                                  gridData: FlGridData(
                                    show: true,
                                    drawVerticalLine: false,
                                    horizontalInterval:
                                        ((yMax - yMin) / 4).clamp(
                                      20,
                                      40,
                                    ),
                                    getDrawingHorizontalLine: (value) {
                                      return FlLine(
                                        color: const Color(0xFFD8E1ED),
                                        strokeWidth: 1,
                                        dashArray: [6, 6],
                                      );
                                    },
                                  ),
                                  borderData: FlBorderData(
                                    show: true,
                                    border: const Border(
                                      left: BorderSide(
                                        color: Color(0xFFCBD5E1),
                                        width: 1.2,
                                      ),
                                      bottom: BorderSide(
                                        color: Color(0xFFCBD5E1),
                                        width: 1.2,
                                      ),
                                    ),
                                  ),
                                  extraLinesData: ExtraLinesData(
                                    horizontalLines: [
                                      HorizontalLine(
                                        y: 70,
                                        color: AppColors.success.withValues(
                                          alpha: 0.4,
                                        ),
                                        strokeWidth: 1.4,
                                        dashArray: [6, 6],
                                      ),
                                      HorizontalLine(
                                        y: 180,
                                        color: AppColors.warning.withValues(
                                          alpha: 0.4,
                                        ),
                                        strokeWidth: 1.4,
                                        dashArray: [6, 6],
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
                                      barWidth: 4.5,
                                      color: const Color(0xFF2F80ED),
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF5CA4FF),
                                          Color(0xFF2F80ED),
                                        ],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      ),
                                      belowBarData: BarAreaData(
                                        show: true,
                                        gradient: LinearGradient(
                                          colors: [
                                            const Color(
                                              0xFF2F80ED,
                                            ).withValues(alpha: 0.26),
                                            const Color(
                                              0xFF2F80ED,
                                            ).withValues(alpha: 0.02),
                                          ],
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                        ),
                                      ),
                                      dotData: FlDotData(
                                        show: true,
                                        getDotPainter: (spot, percent, barData, index) {
                                          return FlDotCirclePainter(
                                            radius: 3.2,
                                            color: Colors.white,
                                            strokeWidth: 2,
                                            strokeColor: const Color(0xFF2F80ED),
                                          );
                                        },
                                      ),
                                      shadow: const Shadow(
                                        color: Color(0x552F80ED),
                                        blurRadius: 16,
                                        offset: Offset(0, 6),
                                      ),
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

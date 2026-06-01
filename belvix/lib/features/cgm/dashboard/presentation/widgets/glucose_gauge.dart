import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../../app/constants/app_assets.dart';
import 'dashboard_theme.dart';

/// Big circular tick gauge — the dashboard hero.
///
/// A full ring of short ticks; the active portion is drawn green when the
/// reading is in range (70–180 mg/dL) and in the alert colour otherwise.
/// Centre shows label / value / unit / a working toggle that flips the
/// readout between the live glucose value and time-in-range.
class GlucoseGauge extends StatefulWidget {
  const GlucoseGauge({
    super.key,
    required this.value,
    required this.fillFraction,
    this.trend = GaugeTrend.stable,
    this.timeInRange,
    this.label = 'Glucose',
    this.unit = 'mg/dL',
    this.size = 260,
  });

  /// Value displayed in the centre; null shows "--".
  final int? value;

  /// 0.0–1.0 — proportion of the ring painted accent.
  final double fillFraction;

  final GaugeTrend trend;

  /// Time-in-range percentage (0–100) shown when the toggle is on.
  final int? timeInRange;

  final String label;
  final String unit;
  final double size;

  @override
  State<GlucoseGauge> createState() => _GlucoseGaugeState();
}

class _GlucoseGaugeState extends State<GlucoseGauge> {
  bool _showTimeInRange = false;

  /// Green when the reading sits in 70–180 mg/dL, alert colour otherwise.
  Color get _statusColor {
    final v = widget.value;
    if (v == null) return DashboardTheme.track;
    return (v >= 70 && v <= 180)
        ? DashboardTheme.accent
        : DashboardTheme.danger;
  }

  @override
  Widget build(BuildContext context) {
    final tir = widget.timeInRange ?? 0;

    // Active colour + fill depend on the mode.
    final activeColor = _showTimeInRange
        ? DashboardTheme.accent
        : _statusColor;

    final fill = _showTimeInRange
        ? (tir / 100.0)
        : widget.fillFraction;

    final label = _showTimeInRange ? 'Time in Range' : widget.label;

    final valueText = _showTimeInRange
        ? '$tir%'
        : (widget.value?.toString() ?? '--');

    final unitText = _showTimeInRange ? 'in range (70–180)' : widget.unit;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: CustomPaint(
        painter: _GaugePainter(
          fill: fill.clamp(0, 1),
          color: activeColor,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: DashboardTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    valueText,
                    style: DashboardTheme.display.copyWith(fontSize: 52),
                  ),
                  if (!_showTimeInRange) ...[
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      // Arrow points by trend (↗ rising / → stable /
                      // ↘ falling) and is tinted by the in-range status.
                      child: Transform.rotate(
                        angle: _trendAngle(),
                        child: SvgPicture.asset(
                          AppAssets.trendArrow,
                          width: 20,
                          height: 20,
                          colorFilter: ColorFilter.mode(
                            activeColor,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Text(
                unitText,
                style: const TextStyle(
                  fontSize: 14,
                  color: DashboardTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 14),
              _UnitToggle(
                value: _showTimeInRange,
                onChanged: (next) =>
                    setState(() => _showTimeInRange = next),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The arrow asset points up-right (↗) by default. Rotate it clockwise
  /// to represent the trend: rising stays ↗, stable points → (+45°),
  /// falling points ↘ (+90°).
  double _trendAngle() {
    switch (widget.trend) {
      case GaugeTrend.up:
        return 0;
      case GaugeTrend.stable:
        return math.pi / 4;
      case GaugeTrend.down:
        return math.pi / 2;
    }
  }
}

enum GaugeTrend { up, down, stable }

class _GaugePainter extends CustomPainter {
  _GaugePainter({required this.fill, required this.color});

  final double fill;
  final Color color;

  /// Full ring, starting at the top (12 o'clock) and sweeping clockwise.
  static const _startAngle = -math.pi / 2;
  static const _sweep = math.pi * 2;

  /// Number of individual tick marks around the ring.
  static const _tickCount = 64;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = size.center(Offset.zero);
    final outerR = size.width / 2 - 4;
    final innerR = outerR - 18;

    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3;

    final activeTo = (fill * _tickCount).round();

    for (var i = 0; i < _tickCount; i++) {
      // Evenly spaced around the full circle (no -1 so the last tick
      // doesn't overlap the first).
      final t = i / _tickCount;
      final angle = _startAngle + (_sweep * t);

      paint.color = i < activeTo ? color : DashboardTheme.track;

      final inner = Offset(
        centre.dx + innerR * math.cos(angle),
        centre.dy + innerR * math.sin(angle),
      );
      final outer = Offset(
        centre.dx + outerR * math.cos(angle),
        centre.dy + outerR * math.sin(angle),
      );

      canvas.drawLine(inner, outer, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) =>
      old.fill != fill || old.color != color;
}

/// iOS-style pill toggle with a label. Off → dark track, on → accent
/// track; both read clearly against the light gauge background.
class _UnitToggle extends StatelessWidget {
  const _UnitToggle({
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    // Native Switch — renders via its own paint path, so it stays
    // visible where custom BoxDecoration pills went transparent.
    return SizedBox(
      height: 30,
      child: FittedBox(
        fit: BoxFit.contain,
        child: Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: Colors.white,
          activeTrackColor: DashboardTheme.accent,
          inactiveThumbColor: Colors.white,
          inactiveTrackColor: DashboardTheme.textPrimary,
          materialTapTargetSize:
              MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }
}

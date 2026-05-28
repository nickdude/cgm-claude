import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'dashboard_theme.dart';

/// Big circular tick gauge — the dashboard hero.
///
/// Matches `figma-screenshot/dashboard/gauge.png` — a thin ring of
/// short ticks that's open at the bottom, with the active portion
/// drawn in the accent green. Center shows label / value / unit / a
/// pill toggle.
class GlucoseGauge extends StatelessWidget {
  const GlucoseGauge({
    super.key,
    required this.value,
    required this.fillFraction,
    this.trend = GaugeTrend.stable,
    this.label = 'Glucose',
    this.unit = 'mg/dL',
    this.size = 260,
  });

  /// Value displayed in the centre; null shows "--".
  final int? value;

  /// 0.0–1.0 — proportion of the ring painted accent.
  final double fillFraction;

  final GaugeTrend trend;

  final String label;
  final String unit;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GaugePainter(fill: fillFraction.clamp(0, 1)),
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
                    value?.toString() ?? '--',
                    style: DashboardTheme.display.copyWith(fontSize: 52),
                  ),
                  const SizedBox(width: 6),
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Icon(
                      _trendIcon(),
                      size: 22,
                      color: DashboardTheme.accent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                unit,
                style: const TextStyle(
                  fontSize: 14,
                  color: DashboardTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 14),
              const _UnitToggle(),
            ],
          ),
        ),
      ),
    );
  }

  IconData _trendIcon() {
    switch (trend) {
      case GaugeTrend.up:
        return Icons.north_east_rounded;
      case GaugeTrend.down:
        return Icons.south_east_rounded;
      case GaugeTrend.stable:
        return Icons.trending_flat_rounded;
    }
  }
}

enum GaugeTrend { up, down, stable }

class _GaugePainter extends CustomPainter {
  _GaugePainter({required this.fill});

  final double fill;

  /// Ring is open at the bottom. Sweeps from 135° → 45° going clockwise
  /// (i.e. through left/top/right).
  static const _startAngle = math.pi * 0.75;
  static const _sweep = math.pi * 1.5;

  /// Number of individual tick marks around the ring.
  static const _tickCount = 80;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = size.center(Offset.zero);
    final outerR = size.width / 2 - 4;
    final innerR = outerR - 18;

    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.6;

    final activeTo = (fill * _tickCount).round();

    for (var i = 0; i < _tickCount; i++) {
      final t = i / (_tickCount - 1);
      final angle = _startAngle + (_sweep * t);

      paint.color = i < activeTo
          ? DashboardTheme.accent
          : DashboardTheme.track;

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
  bool shouldRepaint(covariant _GaugePainter old) => old.fill != fill;
}

class _UnitToggle extends StatelessWidget {
  const _UnitToggle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 22,
      decoration: BoxDecoration(
        color: DashboardTheme.track,
        borderRadius: BorderRadius.circular(DashboardTheme.radiusPill),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          width: 18,
          height: 18,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: const BoxDecoration(
            color: DashboardTheme.textPrimary,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

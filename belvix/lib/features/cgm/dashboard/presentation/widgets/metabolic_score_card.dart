import 'package:flutter/material.dart';

import '../../../../../core/widgets/app_surface.dart';
import 'dashboard_theme.dart';

/// "Metabolic Score" card sitting under the gauge.
///
/// Layout matches the figma:
///   - large coloured score with up/down arrow
///   - centred "Metabolic Score" caption
///   - horizontal scale with a coloured dot marking the current
///     reading; current value + timestamp shown to the right of the dot
class MetabolicScoreCard extends StatelessWidget {
  const MetabolicScoreCard({
    super.key,
    required this.score,
    required this.trendUp,
    required this.currentMgDl,
    required this.timestamp,
    required this.scalePosition,
  });

  final int score;
  final bool trendUp;
  final int currentMgDl;
  final String timestamp;

  /// 0.0–1.0 — where the dot sits on the horizontal scale.
  final double scalePosition;

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      padding: const EdgeInsets.symmetric(
        horizontal: DashboardTheme.space20,
        vertical: DashboardTheme.space16,
      ),
      radius: DashboardTheme.radiusLg,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$score',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: DashboardTheme.accent,
                  height: 1,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Icon(
                  trendUp
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  size: 18,
                  color: DashboardTheme.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Metabolic Score',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: DashboardTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          _ScaleRow(
            position: scalePosition.clamp(0, 1),
            current: currentMgDl,
            timestamp: timestamp,
          ),
        ],
      ),
    );
  }
}

class _ScaleRow extends StatelessWidget {
  const _ScaleRow({
    required this.position,
    required this.current,
    required this.timestamp,
  });

  final double position;
  final int current;
  final String timestamp;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 22,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final scaleWidth = constraints.maxWidth * 0.32;
          final dotX = (scaleWidth - 16) * position;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: scaleWidth,
                height: 16,
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Container(
                      height: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            DashboardTheme.accent,
                            DashboardTheme.warn,
                            DashboardTheme.danger,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Positioned(
                      left: dotX,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: DashboardTheme.accent,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Row(
                  children: [
                    Text(
                      '$current mg/dL',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: DashboardTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '· $timestamp',
                      style: const TextStyle(
                        fontSize: 13,
                        color: DashboardTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';

import 'dashboard_stats_row.dart';
import 'dashboard_theme.dart';

/// Glucose chart container matching the figma reference.
///
/// Wraps the passed-in chart widget and pins decorative overlays on top:
/// a floating "spike detected" pill, the timestamp + value of the most
/// recent reading, and the four-stat summary row underneath.
class GlucoseChartCard extends StatelessWidget {
  const GlucoseChartCard({
    super.key,
    required this.chart,
    required this.showSpikeTag,
    required this.lastReadingLabel,
    required this.lastReadingValue,
    required this.avgGlucose,
    required this.stdDev,
    required this.spikeTime,
    required this.spikeCount,
  });

  /// The chart widget to render (kept external so the container stays
  /// agnostic to the chart implementation).
  final Widget chart;

  /// Whether to show the floating black "Hyperglycemic event" tooltip.
  final bool showSpikeTag;

  /// E.g. "8:54".
  final String lastReadingLabel;

  /// E.g. "112 mg/dL".
  final String lastReadingValue;

  final int avgGlucose;
  final int stdDev;
  final String spikeTime;
  final int spikeCount;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Full-bleed chart: break out of the list's horizontal padding
        // so the graph spans the entire screen width (no card).
        SizedBox(
          height: 260,
          child: OverflowBox(
            minWidth: screenWidth,
            maxWidth: screenWidth,
            alignment: Alignment.center,
            child: SizedBox(
              width: screenWidth,
              height: 260,
              child: Stack(
                children: [
                  Positioned.fill(child: chart),

                  // Pinned floating callout pill showing the latest
                  // sample (sits on top of the chart, near the centre).
                  Positioned(
                    top: 4,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: _ReadingPill(
                        time: lastReadingLabel,
                        value: lastReadingValue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: DashboardTheme.space16),

        // Bottom toggle pill from the figma — purely decorative
        // (matches the static figma element).
        Center(
          child: Container(
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
          ),
        ),

        const SizedBox(height: DashboardTheme.space16),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: DashboardStatsRow(
            avgGlucose: avgGlucose,
            stdDev: stdDev,
            spikeTime: spikeTime,
            spikeCount: spikeCount,
          ),
        ),
      ],
    );
  }
}

/// White rounded pill showing "08:54 / 112 mg/dL".
class _ReadingPill extends StatelessWidget {
  const _ReadingPill({required this.time, required this.value});

  final String time;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: DashboardTheme.surface,
        borderRadius: BorderRadius.circular(DashboardTheme.radiusSm),
        border: Border.all(color: DashboardTheme.track),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            time,
            style: const TextStyle(
              fontSize: 11,
              color: DashboardTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: DashboardTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

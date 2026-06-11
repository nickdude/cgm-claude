import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
    required this.avgGlucose,
    required this.stdDev,
    required this.spikeTime,
    required this.spikeCount,
    this.visibleDate,
  });

  /// The chart widget to render (kept external so the container stays
  /// agnostic to the chart implementation).
  final Widget chart;

  /// Date at the centre of the chart's visible window. When provided, a date
  /// label is shown above the chart that updates live as the user scrolls.
  /// Only the label rebuilds (not the chart) when this changes.
  final ValueListenable<DateTime?>? visibleDate;

  /// Whether to show the floating black "Hyperglycemic event" tooltip.
  final bool showSpikeTag;

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
        // Date label driven by the chart's visible-window centre — updates
        // live as the user scrolls across days.
        if (visibleDate != null)
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: ValueListenableBuilder<DateTime?>(
              valueListenable: visibleDate!,
              builder: (context, date, _) {
                return Text(
                  date == null
                      ? ''
                      : DateFormat('EEE, d MMM yyyy').format(date),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: DashboardTheme.textPrimary,
                  ),
                );
              },
            ),
          ),

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
              child: chart,
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

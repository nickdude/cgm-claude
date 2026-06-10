import 'package:flutter/material.dart';

import 'dashboard_theme.dart';

/// Four-stat strip directly under the chart.
///
/// Each cell is a small two-line column — value (with unit) on top,
/// caption underneath. The two "spike" cells render in danger red.
class DashboardStatsRow extends StatelessWidget {
  const DashboardStatsRow({
    super.key,
    required this.avgGlucose,
    required this.stdDev,
    required this.spikeTime,
    required this.spikeCount,
  });

  final int avgGlucose;
  final int stdDev;
  final String spikeTime;
  final int spikeCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _StatCell(
            value: '$avgGlucose',
            unit: 'mg/dL',
            label: 'Avg Glucose',
          ),
        ),
        Expanded(
          child: _StatCell(value: '$stdDev', unit: 'mg/dL', label: 'Std. Dev'),
        ),
        Expanded(
          child: _StatCell(value: spikeTime, label: 'Spike Time', alert: true),
        ),
        Expanded(
          child: _StatCell(value: '$spikeCount', label: 'Spike', alert: true),
        ),
      ],
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.value,
    required this.label,
    this.unit,
    this.alert = false,
  });

  final String value;
  final String? unit;
  final String label;
  final bool alert;

  @override
  Widget build(BuildContext context) {
    final color = alert ? DashboardTheme.danger : DashboardTheme.textPrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Scale the value down to fit the cell width instead of clipping it,
        // so long values (e.g. a multi-part "Spike Time") stay fully visible.
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: color,
                  height: 1.1,
                ),
              ),
              if (unit != null) ...[
                const SizedBox(width: 2),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    unit!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: DashboardTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            color: DashboardTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}

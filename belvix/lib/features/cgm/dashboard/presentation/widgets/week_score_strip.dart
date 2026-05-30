import 'package:flutter/material.dart';

import 'dashboard_theme.dart';

/// One day worth of data shown in the week strip.
class WeekDayScore {
  const WeekDayScore({
    required this.label,
    this.score,
    this.severity = ScoreSeverity.good,
    this.enabled = true,
  });

  /// Single-letter weekday label, e.g. "W".
  final String label;

  /// Null when no score is recorded yet for the day.
  final int? score;

  /// Drives the pill colour.
  final ScoreSeverity severity;

  /// Future days (or days the user can't select) are disabled.
  final bool enabled;
}

enum ScoreSeverity { good, warn, bad }

/// Top row of the dashboard — 7 day chips with score pills.
///
/// Consecutive days with scores share a single oblong "joined" pill,
/// matching `figma-screenshot/dashboard/date selector with avgglucose score.png`.
/// The selected chip gets the filled dark capsule on the label row.
class WeekScoreStrip extends StatelessWidget {
  const WeekScoreStrip({
    super.key,
    required this.days,
    required this.selectedIndex,
    this.onDayTap,
  }) : assert(days.length == 7);

  final List<WeekDayScore> days;

  /// 0..6 — the currently highlighted day (typically defaults to today).
  final int selectedIndex;

  /// Invoked when the user taps a day chip. Disabled chips are no-ops.
  final ValueChanged<int>? onDayTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cellWidth = constraints.maxWidth / 7;

          return Stack(
            children: [
              // First pass: render the score pills (and joined groups)
              // so they sit *behind* the chip labels.
              ..._buildScorePills(cellWidth),

              // Second pass: render the day labels + selected indicator.
              Row(
                children: [
                  for (var i = 0; i < 7; i++)
                    SizedBox(
                      width: cellWidth,
                      child: _DayCell(
                        label: days[i].label,
                        isSelected: i == selectedIndex,
                        enabled: days[i].enabled,
                        onTap: days[i].enabled && onDayTap != null
                            ? () => onDayTap!(i)
                            : null,
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildScorePills(double cellWidth) {
    final widgets = <Widget>[];
    var i = 0;
    while (i < 7) {
      final day = days[i];

      if (day.score == null) {
        widgets.add(_EmptyChip(cellWidth: cellWidth, leftIndex: i));
        i += 1;
        continue;
      }

      // Group consecutive scored days with the same severity into a
      // single joined pill (matches figma's "81  90" capsule).
      var j = i;
      while (j + 1 < 7 &&
          days[j + 1].score != null &&
          days[j + 1].severity == day.severity) {
        j += 1;
      }

      widgets.add(
        _JoinedPill(
          cellWidth: cellWidth,
          leftIndex: i,
          rightIndex: j,
          days: days.sublist(i, j + 1),
        ),
      );

      i = j + 1;
    }

    return widgets;
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.label,
    required this.isSelected,
    required this.enabled,
    this.onTap,
  });

  final String label;
  final bool isSelected;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final labelColor = enabled
        ? (isSelected
            ? Colors.white
            : DashboardTheme.textSecondary)
        : DashboardTheme.textMuted;

    return InkResponse(
      onTap: onTap,
      radius: 38,
      containedInkWell: false,
      highlightShape: BoxShape.circle,
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: isSelected
              ? Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: DashboardTheme.textPrimary,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              : SizedBox(
                  width: 28,
                  height: 28,
                  child: Center(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: labelColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class _EmptyChip extends StatelessWidget {
  const _EmptyChip({required this.cellWidth, required this.leftIndex});

  final double cellWidth;
  final int leftIndex;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: leftIndex * cellWidth + (cellWidth - 38) / 2,
      bottom: 6,
      child: IgnorePointer(
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: DashboardTheme.track, width: 1.2),
          ),
        ),
      ),
    );
  }
}

class _JoinedPill extends StatelessWidget {
  const _JoinedPill({
    required this.cellWidth,
    required this.leftIndex,
    required this.rightIndex,
    required this.days,
  });

  final double cellWidth;
  final int leftIndex;
  final int rightIndex;
  final List<WeekDayScore> days;

  @override
  Widget build(BuildContext context) {
    final isMulti = leftIndex != rightIndex;

    final bg = switch (days.first.severity) {
      ScoreSeverity.good => DashboardTheme.accentSoft,
      ScoreSeverity.warn => DashboardTheme.warnSoft,
      ScoreSeverity.bad => DashboardTheme.dangerSoft,
    };

    final fg = switch (days.first.severity) {
      ScoreSeverity.good => DashboardTheme.accent,
      ScoreSeverity.warn => DashboardTheme.warn,
      ScoreSeverity.bad => DashboardTheme.danger,
    };

    final left = leftIndex * cellWidth + (cellWidth - 38) / 2;
    final right = rightIndex * cellWidth + (cellWidth + 38) / 2;

    return Positioned(
      left: left,
      bottom: 6,
      width: right - left,
      height: 38,
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(DashboardTheme.radiusPill),
          ),
          child: isMulti
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    for (final d in days)
                      Text(
                        '${d.score}',
                        style: TextStyle(
                          color: fg,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                )
              : Center(
                  child: Text(
                    '${days.first.score}',
                    style: TextStyle(
                      color: fg,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

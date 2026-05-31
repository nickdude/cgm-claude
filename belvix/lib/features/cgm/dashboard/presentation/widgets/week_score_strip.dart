import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'dashboard_theme.dart';

/// One day worth of data shown in the week strip.
class WeekDayScore {
  const WeekDayScore({
    required this.date,
    required this.label,
    this.score,
    this.severity = ScoreSeverity.good,
    this.enabled = true,
  });

  /// The calendar day this chip represents.
  final DateTime date;

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

/// Horizontally scrollable date selector. Shows the selected day's full
/// date on top (tap it to open a calendar and jump to any date / month),
/// then a scrollable row of day chips (weekday + date number + average-
/// glucose pill). Tapping a chip selects that day; the strip auto-scrolls
/// to keep the selected day in view.
///
/// Surfaces render via [Material] (not `Container`+`BoxDecoration`) so the
/// selected-day fill and score pills paint correctly on Impeller Android
/// GPUs that drop BoxDecoration fills.
class WeekScoreStrip extends StatefulWidget {
  const WeekScoreStrip({
    super.key,
    required this.days,
    required this.selectedIndex,
    this.onDayTap,
    this.onPickDate,
  });

  final List<WeekDayScore> days;

  /// Index into [days] of the currently highlighted day.
  final int selectedIndex;

  /// Invoked when the user taps a day chip. Disabled chips are no-ops.
  final ValueChanged<int>? onDayTap;

  /// Invoked when the user taps the date header (to open a date picker).
  final VoidCallback? onPickDate;

  @override
  State<WeekScoreStrip> createState() => _WeekScoreStripState();
}

class _WeekScoreStripState extends State<WeekScoreStrip> {
  static const double _chipWidth = 52;

  final ScrollController _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _scrollToSelected(animate: false),
    );
  }

  @override
  void didUpdateWidget(WeekScoreStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _scrollToSelected(animate: true);
    }
  }

  void _scrollToSelected({required bool animate}) {
    if (!_controller.hasClients) return;

    final viewport = _controller.position.viewportDimension;
    final target =
        (widget.selectedIndex * _chipWidth) - (viewport / 2) + (_chipWidth / 2);
    final clamped = target.clamp(0.0, _controller.position.maxScrollExtent);

    if (animate) {
      _controller.animateTo(
        clamped,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    } else {
      _controller.jumpTo(clamped);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.days.isEmpty) return const SizedBox.shrink();

    final selected =
        widget.days[widget.selectedIndex.clamp(0, widget.days.length - 1)];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onPickDate,
          child: Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat('EEEE, d MMMM').format(selected.date),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: DashboardTheme.textPrimary,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.expand_more,
                  size: 20,
                  color: DashboardTheme.textSecondary,
                ),
              ],
            ),
          ),
        ),
        SizedBox(
          height: 92,
          child: ListView.builder(
            controller: _controller,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: widget.days.length,
            itemBuilder: (context, i) => SizedBox(
              width: _chipWidth,
              child: _DayChip(
                day: widget.days[i],
                isSelected: i == widget.selectedIndex,
                onTap: widget.days[i].enabled && widget.onDayTap != null
                    ? () => widget.onDayTap!(i)
                    : null,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.day,
    required this.isSelected,
    this.onTap,
  });

  final WeekDayScore day;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final hasScore = day.score != null;

    final pillFg = switch (day.severity) {
      ScoreSeverity.good => DashboardTheme.accent,
      ScoreSeverity.warn => DashboardTheme.warn,
      ScoreSeverity.bad => DashboardTheme.danger,
    };
    final pillBg = switch (day.severity) {
      ScoreSeverity.good => DashboardTheme.accentSoft,
      ScoreSeverity.warn => DashboardTheme.warnSoft,
      ScoreSeverity.bad => DashboardTheme.dangerSoft,
    };

    final dateColor = !day.enabled
        ? DashboardTheme.textMuted
        : (isSelected ? Colors.white : DashboardTheme.textPrimary);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            day.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: day.enabled
                  ? DashboardTheme.textSecondary
                  : DashboardTheme.textMuted,
            ),
          ),
          const SizedBox(height: 6),
          // Date bubble — Material so the selected fill paints on Impeller.
          Material(
            color: isSelected
                ? DashboardTheme.textPrimary
                : Colors.transparent,
            shape: const CircleBorder(),
            child: SizedBox(
              width: 34,
              height: 34,
              child: Center(
                child: Text(
                  '${day.date.day}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: dateColor,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Average-glucose pill.
          Material(
            color: hasScore ? pillBg : Colors.transparent,
            shape: hasScore
                ? const StadiumBorder()
                : const StadiumBorder(
                    side: BorderSide(color: DashboardTheme.track, width: 1),
                  ),
            child: SizedBox(
              width: 38,
              height: 20,
              child: Center(
                child: Text(
                  hasScore ? '${day.score}' : '–',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: hasScore ? pillFg : DashboardTheme.textMuted,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Compact two-line date + time stamp used on the right of event/history rows.
///
/// Stacks the date over the time (right-aligned) so it stays on a single
/// column and never overflows horizontally on narrow devices. Pass the time
/// already in the form you want shown (e.g. `loggedAt.toLocal()`).
class EventTimeLabel extends StatelessWidget {
  const EventTimeLabel(
    this.time, {
    super.key,
    this.dateColor = const Color(0xFF9AA0A6),
    this.timeColor = const Color(0xFF6B7280),
  });

  final DateTime time;
  final Color dateColor;
  final Color timeColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          DateFormat('d MMM').format(time),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: dateColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          DateFormat('h:mm a').format(time),
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: timeColor,
          ),
        ),
      ],
    );
  }
}

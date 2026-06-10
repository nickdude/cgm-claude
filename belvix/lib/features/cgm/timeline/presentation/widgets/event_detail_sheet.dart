import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

import '../../data/models/timeline_event.dart';

/// Opens the detail bottom sheet for a tapped timeline event.
Future<void> showEventDetailSheet(
  BuildContext context,
  TimelineEvent event,
) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => _EventDetailSheet(event: event),
  );
}

class _EventDetailSheet extends StatelessWidget {
  const _EventDetailSheet({required this.event});

  final TimelineEvent event;

  static const _ink = Color(0xFF101418);
  static const _muted = Color(0xFF6B7280);
  static const _border = Color(0xFFE6E8EC);

  /// Label/value rows for this event type, in display order.
  List<List<String>> _rows() {
    final time = DateFormat('EEE, d MMM • h:mm a').format(event.timestamp);
    switch (event.type) {
      case TimelineEventType.food:
        return [
          ['Meal', event.title.isNotEmpty ? event.title : 'Food'],
          ['Calories', '${event.meta('calories')} cal'],
          ['Carbs', '${event.meta('carbs')} g'],
          ['Time', time],
        ];
      case TimelineEventType.insulin:
        final type = event.meta('insulinType');
        return [
          if (type.isNotEmpty) ['Type', type],
          ['Dosage', '${event.meta('dosage')} units'],
          ['Time', time],
        ];
      case TimelineEventType.fingerBlood:
        final notes = event.meta('notes');
        return [
          ['Glucose', '${event.meta('glucoseValue')} mg/dL'],
          if (notes.isNotEmpty) ['Notes', notes],
          ['Time', time],
        ];
      case TimelineEventType.exercise:
        final activity = event.meta('activity');
        return [
          ['Activity', activity.isNotEmpty ? activity : event.title],
          ['Duration', '${event.meta('duration')} min'],
          ['Calories Burned', '${event.meta('caloriesBurned')} cal'],
          ['Time', time],
        ];
      case TimelineEventType.unknown:
        return [
          ['Detail', event.subtitle],
          ['Time', time],
        ];
    }
  }

  String get _heading {
    switch (event.type) {
      case TimelineEventType.food:
        return 'Food';
      case TimelineEventType.insulin:
        return 'Insulin';
      case TimelineEventType.fingerBlood:
        return 'Finger Blood';
      case TimelineEventType.exercise:
        return 'Exercise';
      case TimelineEventType.unknown:
        return 'Event';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: _border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF6F7F9),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(8),
                  child: SvgPicture.asset(event.asset),
                ),
                const SizedBox(width: 14),
                Text(
                  _heading,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: _ink,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            for (final row in _rows()) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(
                        row[0],
                        style: const TextStyle(
                          fontSize: 14,
                          color: _muted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        row[1],
                        style: const TextStyle(
                          fontSize: 15,
                          color: _ink,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (row != _rows().last)
                const Divider(height: 1, color: _border),
            ],
          ],
        ),
      ),
    );
  }
}

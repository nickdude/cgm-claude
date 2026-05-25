import 'package:flutter/material.dart';

class GlucoseCard
    extends StatelessWidget {
  final int? glucose;

  final String trend;

  final DateTime? lastReadingAt;

  const GlucoseCard({
    super.key,
    required this.glucose,
    required this.trend,
    this.lastReadingAt,
  });

  IconData _trendIcon() {
    switch (trend.toLowerCase()) {
      case "rising":
      case "rising fast":
        return Icons.trending_up;
      case "falling":
      case "falling fast":
        return Icons.trending_down;
      default:
        return Icons.trending_flat;
    }
  }

  String _ago() {
    if (lastReadingAt == null) {
      return "Waiting for sensor";
    }

    final diff = DateTime.now()
        .difference(lastReadingAt!);

    // Anything older than a week is almost certainly bad clock
    // data from the sensor; don't render it.
    if (diff.inDays > 7 ||
        diff.isNegative) {
      return "Just now";
    }

    if (diff.inSeconds < 30) {
      return "Just now";
    }

    if (diff.inMinutes < 1) {
      return "${diff.inSeconds}s ago";
    }

    if (diff.inMinutes < 60) {
      return "${diff.inMinutes} min ago";
    }

    if (diff.inHours < 24) {
      return "${diff.inHours}h ago";
    }

    return "${diff.inDays}d ago";
  }

  @override
  Widget build(BuildContext context) {
    final display = glucose
            ?.toString() ??
        "--";

    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade400,
            Colors.blue.shade600,
          ],
        ),
        borderRadius:
            BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          const Text(
            "Current Glucose",
            style: TextStyle(
              color: Colors.white70,
            ),
          ),

          const SizedBox(height: 16),

          Text(
            display,
            style: const TextStyle(
              fontSize: 72,
              fontWeight:
                  FontWeight.bold,
              color: Colors.white,
              height: 1.0,
            ),
          ),

          const SizedBox(height: 4),

          const Text(
            "mg/dL",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets
                .symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius:
                  BorderRadius
                      .circular(30),
            ),
            child: Row(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                Icon(
                  _trendIcon(),
                  color: Colors.white,
                ),
                const SizedBox(
                  width: 8,
                ),
                Text(
                  trend,
                  style:
                      const TextStyle(
                    color:
                        Colors.white,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Text(
            _ago(),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

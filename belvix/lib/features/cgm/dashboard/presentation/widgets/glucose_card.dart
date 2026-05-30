import 'package:flutter/material.dart';

class GlucoseCard extends StatelessWidget {
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

    final diff = DateTime.now().difference(lastReadingAt!);

    // Anything older than a week is almost certainly bad clock
    // data from the sensor; don't render it.
    if (diff.inDays > 7 || diff.isNegative) {
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
    final display = glucose?.toString() ?? "--";

    final trendColor = _trendColor();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: Color(0x260F172A),
            blurRadius: 24,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.16),
                  ),
                ),
                child: const Text(
                  "Live reading",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: trendColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  children: [
                    Icon(_trendIcon(), color: trendColor, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      trend,
                      style: TextStyle(
                        color: trendColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Text(
            "Current Glucose",
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),

          const SizedBox(height: 10),

          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                display,
                style: const TextStyle(
                  fontSize: 72,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.0,
                  letterSpacing: -2.0,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  "mg/dL",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.schedule_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  _ago(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          Text(
            "Tap the chart below to inspect trends across the day.",
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Color _trendColor() {
    switch (trend.toLowerCase()) {
      case "rising":
      case "rising fast":
        return const Color(0xFFFFC857);
      case "falling":
      case "falling fast":
        return const Color(0xFFFB7185);
      default:
        return const Color(0xFF86EFAC);
    }
  }
}

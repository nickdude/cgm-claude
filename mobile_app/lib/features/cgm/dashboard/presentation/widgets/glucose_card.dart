import 'package:flutter/material.dart';

class GlucoseCard
    extends StatelessWidget {
  final int glucose;

  final String trend;

  const GlucoseCard({
    super.key,
    required this.glucose,
    required this.trend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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

          const SizedBox(height: 20),

          Text(
            "$glucose",

            style: const TextStyle(
              fontSize: 72,

              fontWeight:
                  FontWeight.bold,

              color: Colors.white,
            ),
          ),

          const SizedBox(height: 10),

          Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),

            decoration: BoxDecoration(
              color: Colors.white24,

              borderRadius:
                  BorderRadius.circular(
                30,
              ),
            ),

            child: Row(
              mainAxisSize:
                  MainAxisSize.min,

              children: [
                const Icon(
                  Icons.trending_up,

                  color: Colors.white,
                ),

                const SizedBox(width: 8),

                Text(
                  trend,

                  style:
                      const TextStyle(
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
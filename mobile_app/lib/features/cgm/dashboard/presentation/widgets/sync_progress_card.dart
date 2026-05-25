import 'package:flutter/material.dart';

class SyncProgressCard
    extends StatelessWidget {
  final double progress;

  final String status;

  final Color color;

  const SyncProgressCard({
    super.key,
    required this.progress,
    required this.status,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(
          24,
        ),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              Container(
                height: 14,
                width: 14,

                decoration: BoxDecoration(
                  color: color,

                  shape: BoxShape.circle,
                ),
              ),

              const SizedBox(width: 10),

              Text(
                status,

                style: const TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          LinearProgressIndicator(
            value: progress,

            minHeight: 10,

            borderRadius:
                BorderRadius.circular(
              20,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            "${(progress * 100).toInt()}% synced",
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';

class GlucoseAlertCard
    extends StatelessWidget {
  final String message;

  final Color color;

  const GlucoseAlertCard({
    super.key,
    required this.message,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,

      padding:
          const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: color.withOpacity(
          0.12,
        ),

        borderRadius:
            BorderRadius.circular(
          20,
        ),

        border: Border.all(
          color: color,
        ),
      ),

      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,

            color: color,

            size: 30,
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Text(
              message,

              style: TextStyle(
                color: color,

                fontWeight:
                    FontWeight.bold,

                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';

import '../../../../../core/widgets/app_surface.dart';

class SyncProgressCard extends StatelessWidget {
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
    return AppSurface(
      padding: const EdgeInsets.all(18),
      radius: 24,
      borderColor: const Color(0xFFE7EEF7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Material(
                color: color,
                shape: const CircleBorder(),
                child: const SizedBox(height: 12, width: 12),
              ),
              const SizedBox(width: 10),
              Text(
                status,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(end: progress.clamp(0.0, 1.0)),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              builder: (context, animatedProgress, _) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      height: 110,
                      width: 110,
                      child: CircularProgressIndicator(
                        value: animatedProgress,
                        strokeWidth: 10,
                        backgroundColor: const Color(0xFFE7EEF7),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${(animatedProgress * 100).round()}%',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Syncing',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 18),
          Text(
            progress >= 1
                ? 'Sync complete. The graph is ready.'
                : 'We are pulling readings into the chart area.',
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

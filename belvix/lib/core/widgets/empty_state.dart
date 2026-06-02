import 'package:flutter/material.dart';

/// Friendly empty-state placeholder shown when a list has no entries yet.
///
/// The icon badge is painted with [Material] (not a BoxDecoration) so it
/// renders reliably across platforms.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
  });

  final IconData icon;
  final String title;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 24, 32, 90),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Material(
              color: const Color(0xFFEFF1F4),
              shape: const CircleBorder(),
              child: SizedBox(
                width: 88,
                height: 88,
                child: Center(
                  child: Icon(icon, size: 40, color: const Color(0xFF9AA1AB)),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1F2937),
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';

import 'dashboard_theme.dart';

/// Bottom "nudge" card shown only while the sensor is warming up.
///
/// Counts down to [warmupEndsAt] in real time (derived from the sensor's
/// activation timestamp) and calls [onFinished] when the warm-up elapses.
class SensorWarmupNudge extends StatefulWidget {
  const SensorWarmupNudge({
    super.key,
    required this.warmupEndsAt,
    this.onFinished,
  });

  /// Exact instant the warm-up completes.
  final DateTime warmupEndsAt;

  /// Called once the countdown reaches zero.
  final VoidCallback? onFinished;

  @override
  State<SensorWarmupNudge> createState() => _SensorWarmupNudgeState();
}

class _SensorWarmupNudgeState extends State<SensorWarmupNudge> {
  static const _total = Duration(minutes: 60);

  Timer? _timer;
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _remaining = _compute();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final next = _compute();
      if (!mounted) return;
      setState(() => _remaining = next);
      if (next == Duration.zero) {
        _timer?.cancel();
        widget.onFinished?.call();
      }
    });
  }

  @override
  void didUpdateWidget(covariant SensorWarmupNudge old) {
    super.didUpdateWidget(old);
    if (old.warmupEndsAt != widget.warmupEndsAt) {
      _remaining = _compute();
    }
  }

  Duration _compute() {
    final d = widget.warmupEndsAt.difference(DateTime.now());
    return d.isNegative ? Duration.zero : d;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _countdown {
    final m = _remaining.inMinutes;
    final s = _remaining.inSeconds % 60;
    return '${m}m ${s.toString().padLeft(2, '0')}s';
  }

  @override
  Widget build(BuildContext context) {
    final progress = (1 - _remaining.inSeconds / _total.inSeconds).clamp(
      0.0,
      1.0,
    );
    final height = MediaQuery.of(context).size.height * 0.8;

    // Material paints the fill reliably (a plain BoxDecoration can render
    // transparent on some devices).
    return Material(
      color: Colors.white,
      elevation: 18,
      shadowColor: const Color(0x33000000),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Grabber.
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: DashboardTheme.track,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 28),
                Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                    color: DashboardTheme.warnSoft,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.hourglass_bottom_rounded,
                    color: DashboardTheme.warn,
                    size: 26,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Sensor warming up',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: DashboardTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your new sensor is calibrating before it can show '
                  'live glucose.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: DashboardTheme.textSecondary,
                  ),
                ),
                const Spacer(),
                // Circular progress with the live countdown in the centre.
                SizedBox(
                  width: 220,
                  height: 220,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox.expand(
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 14,
                          strokeCap: StrokeCap.round,
                          backgroundColor: DashboardTheme.warnSoft,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            DashboardTheme.warn,
                          ),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _countdown,
                            style: const TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                              color: DashboardTheme.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'remaining',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: DashboardTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                const Text(
                  'Keep your phone nearby — readings will start '
                  'automatically once warm-up finishes.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: DashboardTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

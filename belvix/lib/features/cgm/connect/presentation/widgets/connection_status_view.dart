import 'package:flutter/material.dart';

import '../../../../../app/theme/app_colors.dart';
import 'connection_progress.dart';

/// Presentational, provider-free view of the connection progress: the animated
/// status badge, headline + detail copy, and the step checklist. The connecting
/// screen wraps this with the connect controller + footer actions; keeping it
/// standalone makes it easy to preview/golden-test every state.
class ConnectionStatusView
    extends StatelessWidget {
  final CgmConnectionProgress
      progress;

  const ConnectionStatusView({
    super.key,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize:
          MainAxisSize.min,
      children: [
        _StatusBadge(
          progress: progress,
        ),
        const SizedBox(height: 28),
        Text(
          progress.headline,
          textAlign:
              TextAlign.center,
          style: const TextStyle(
            fontSize: 24,
            fontWeight:
                FontWeight.bold,
            color: AppColors
                .textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          progress.detail,
          textAlign:
              TextAlign.center,
          style: const TextStyle(
            fontSize: 15,
            height: 1.4,
            color: AppColors
                .textSecondary,
          ),
        ),
        const SizedBox(height: 36),
        _ChecklistCard(
          steps: progress.steps,
        ),
      ],
    );
  }
}

/// The round status mark — animated ring while working, a green check on
/// success, a red glyph on a hard stop.
class _StatusBadge
    extends StatelessWidget {
  final CgmConnectionProgress
      progress;

  const _StatusBadge({
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final Color ring;
    final Color fg;
    final IconData icon;

    if (progress.isComplete) {
      ring = AppColors.success;
      fg = AppColors.success;
      icon = Icons.check_rounded;
    } else if (progress.isFatal) {
      ring = AppColors.danger;
      fg = AppColors.danger;
      icon =
          Icons.error_outline_rounded;
    } else {
      ring = AppColors.primary;
      fg = AppColors.primary;
      icon = progress.isSearching
          ? Icons
              .bluetooth_searching_rounded
          : Icons.sensors_rounded;
    }

    final working =
        !progress.isComplete &&
            !progress.isFatal;

    return SizedBox(
      width: 104,
      height: 104,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Faint full-circle track so the spinner reads as a ring even in a
          // still frame, instead of a stray arc.
          if (working)
            Container(
              width: 104,
              height: 104,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color:
                      ring.withOpacity(
                    0.15,
                  ),
                  width: 4,
                ),
              ),
            ),
          if (working)
            SizedBox(
              width: 104,
              height: 104,
              child:
                  CircularProgressIndicator(
                strokeWidth: 4,
                valueColor:
                    AlwaysStoppedAnimation(
                  ring,
                ),
              ),
            ),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: ring.withOpacity(
                0.10,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: fg,
              size: 38,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChecklistCard
    extends StatelessWidget {
  final List<CgmConnectStep> steps;

  const _ChecklistCard({
    required this.steps,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        children: [
          for (final step in steps)
            _StepRow(step: step),
        ],
      ),
    );
  }
}

class _StepRow
    extends StatelessWidget {
  final CgmConnectStep step;

  const _StepRow({
    required this.step,
  });

  @override
  Widget build(BuildContext context) {
    final isPending = step.state ==
        CgmStepState.pending;

    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 12,
      ),
      child: Row(
        children: [
          _StepLeading(
            state: step.state,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              step.label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isPending
                    ? FontWeight.w400
                    : FontWeight.w600,
                color: isPending
                    ? AppColors
                        .textSecondary
                    : AppColors
                        .textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepLeading
    extends StatelessWidget {
  final CgmStepState state;

  const _StepLeading({
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case CgmStepState.done:
        return const Icon(
          Icons.check_circle_rounded,
          size: 26,
          color: AppColors.success,
        );
      case CgmStepState.failed:
        return const Icon(
          Icons.cancel_rounded,
          size: 26,
          color: AppColors.danger,
        );
      case CgmStepState.active:
        return const SizedBox(
          width: 26,
          height: 26,
          child: Padding(
            padding:
                EdgeInsets.all(2),
            child:
                CircularProgressIndicator(
              strokeWidth: 2.6,
              valueColor:
                  AlwaysStoppedAnimation(
                AppColors.primary,
              ),
            ),
          ),
        );
      case CgmStepState.pending:
        return const Icon(
          Icons
              .radio_button_unchecked,
          size: 26,
          color: Color(0xFFCBD5E1),
        );
    }
  }
}

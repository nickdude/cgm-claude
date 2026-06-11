import 'dart:async';

import 'package:flutter/material.dart';

import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../../../../app/router/app_router.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../../../../core/storage/storage_service.dart';
import '../../../../../core/widgets/primary_button.dart';

import '../../../../auth/presentation/providers/auth_provider.dart';

import '../providers/cgm_provider.dart';
import '../widgets/connection_progress.dart';
import '../widgets/connection_status_view.dart';

class CGMConnectingScreen
    extends StatefulWidget {
  final String serialNumber;
  final String deviceName;
  final String manufacturer;

  const CGMConnectingScreen({
    super.key,
    required this.serialNumber,
    required this.deviceName,
    required this.manufacturer,
  });

  @override
  State<CGMConnectingScreen>
      createState() =>
          _CGMConnectingScreenState();
}

class _CGMConnectingScreenState
    extends State<CGMConnectingScreen> {
  bool _advanced = false;

  /// Drives the "still searching…" copy escalation; purely cosmetic.
  final DateTime _startedAt =
      DateTime.now();
  Duration _elapsed = Duration.zero;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();

    _ticker = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (!mounted) return;
        setState(() {
          _elapsed = DateTime.now()
              .difference(_startedAt);
        });
      },
    );

    WidgetsBinding.instance
        .addPostFrameCallback((_) {
      _startConnect();
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _startConnect() async {
    final cgm =
        context.read<CGMProvider>();

    await cgm.connectDevice(
      serialNumber: widget.serialNumber,
      deviceName: widget.deviceName,
      manufacturer:
          widget.manufacturer,
    );
  }

  Future<void> _maybeAdvance(
    CgmConnectionProgress progress,
  ) async {
    if (_advanced) return;
    if (!progress.isComplete) return;

    _advanced = true;

    _ticker?.cancel();

    final auth =
        context.read<AuthProvider>();

    await auth.markCgmConnected();

    if (!mounted) return;

    final token = await StorageService
        .getToken();

    if (!mounted) return;

    await AppRouter.goToHome(
      context,
      token: token,
      user: auth.currentUser,
    );
  }

  Future<void> _cancel(
    CGMProvider cgm,
  ) async {
    await cgm.disconnect();
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          AppColors.background,
      appBar: AppBar(
        backgroundColor:
            Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading:
            false,
      ),
      body: SafeArea(
        child:
            Consumer<CGMProvider>(
          builder:
              (context, cgm, _) {
            final progress =
                CgmConnectionProgress
                    .from(
              status: cgm
                  .connectionStatus,
              bindStep:
                  cgm.lastBindStep,
              elapsed: _elapsed,
            );

            WidgetsBinding.instance
                .addPostFrameCallback(
              (_) => _maybeAdvance(
                progress,
              ),
            );

            return Padding(
              padding:
                  const EdgeInsets
                      .symmetric(
                horizontal: 24,
              ),
              child: Column(
                children: [
                  const Spacer(
                    flex: 2,
                  ),
                  ConnectionStatusView(
                    progress:
                        progress,
                  ),
                  const Spacer(
                    flex: 3,
                  ),
                  _Footer(
                    progress:
                        progress,
                    cgm: cgm,
                    onCancel: () =>
                        _cancel(cgm),
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Context-appropriate actions: a calm Cancel while working, recovery actions
/// on a hard stop, nothing on success (we auto-advance).
class _Footer extends StatelessWidget {
  final CgmConnectionProgress
      progress;
  final CGMProvider cgm;
  final Future<void> Function()
      onCancel;

  const _Footer({
    required this.progress,
    required this.cgm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    if (progress.isComplete) {
      return const SizedBox.shrink();
    }

    if (progress.isFatal) {
      return _FatalActions(
        status:
            cgm.connectionStatus,
        cgm: cgm,
      );
    }

    // Working / searching — let the user back out.
    return TextButton(
      onPressed: () => onCancel(),
      child: const Text(
        "Cancel",
        style: TextStyle(
          color: AppColors
              .textSecondary,
          fontWeight:
              FontWeight.w600,
        ),
      ),
    );
  }
}

class _FatalActions
    extends StatelessWidget {
  final CGMConnectionStatus status;
  final CGMProvider cgm;

  const _FatalActions({
    required this.status,
    required this.cgm,
  });

  @override
  Widget build(BuildContext context) {
    final canRetry = status ==
            CGMConnectionStatus
                .failed ||
        status ==
            CGMConnectionStatus
                .authFailed ||
        status ==
            CGMConnectionStatus
                .bluetoothOff;

    // Primary action. expired / malfunction have nothing to retry, so the
    // single "Go back" is the whole footer.
    final Widget primary;
    if (status ==
        CGMConnectionStatus
            .permissionsDenied) {
      primary = PrimaryButton(
        title: "Open Settings",
        onTap: () async {
          await openAppSettings();
        },
      );
    } else if (canRetry) {
      primary = PrimaryButton(
        title: "Try again",
        onTap: () async {
          await cgm.retryReconnect();
        },
      );
    } else {
      primary = PrimaryButton(
        title: "Go back",
        onTap: () {
          Navigator.of(context)
              .pop();
        },
      );
    }

    final secondaryGoBack =
        canRetry ||
            status ==
                CGMConnectionStatus
                    .permissionsDenied;

    return Column(
      children: [
        primary,
        if (secondaryGoBack) ...[
          const SizedBox(height: 4),
          TextButton(
            onPressed: () {
              Navigator.of(context)
                  .pop();
            },
            child: const Text(
              "Go back",
              style: TextStyle(
                color: AppColors
                    .textSecondary,
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

import 'package:flutter/material.dart';

import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../../../../app/router/app_router.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../../../../core/storage/storage_service.dart';
import '../../../../../core/widgets/primary_button.dart';

import '../../../../auth/presentation/providers/auth_provider.dart';

import '../providers/cgm_provider.dart';

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

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance
        .addPostFrameCallback((_) {
      _startConnect();
    });
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

    // After connectDevice returns we listen to the provider for
    // terminal state transitions in build() to decide whether
    // to advance to the dashboard.
  }

  Future<void> _maybeAdvance(
    BuildContext context,
    CGMProvider cgm,
  ) async {
    if (_advanced) return;

    final terminalGood =
        cgm.connectionStatus ==
                CGMConnectionStatus
                    .active ||
            cgm.connectionStatus ==
                CGMConnectionStatus
                    .syncing;

    if (!terminalGood) return;

    _advanced = true;

    final auth = context.read<
        AuthProvider>();

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Padding(
          padding:
              const EdgeInsets.all(24),
          child:
              Consumer<CGMProvider>(
            builder:
                (context, cgm, _) {
              // Schedule post-frame so we don't navigate during build.
              WidgetsBinding.instance
                  .addPostFrameCallback(
                (_) =>
                    _maybeAdvance(
                  context,
                  cgm,
                ),
              );

              final isFatal = cgm
                          .connectionStatus ==
                      CGMConnectionStatus
                          .failed ||
                  cgm.connectionStatus ==
                      CGMConnectionStatus
                          .authFailed ||
                  cgm.connectionStatus ==
                      CGMConnectionStatus
                          .permissionsDenied ||
                  cgm.connectionStatus ==
                      CGMConnectionStatus
                          .expired;

              return Column(
                mainAxisAlignment:
                    MainAxisAlignment
                        .center,
                children: [
                  SizedBox(
                    height: 150,
                    width: 150,
                    child: Stack(
                      alignment:
                          Alignment
                              .center,
                      children: [
                        if (!isFatal)
                          const CircularProgressIndicator(
                            strokeWidth:
                                6,
                          ),
                        Icon(
                          isFatal
                              ? Icons
                                  .error_outline
                              : Icons
                                  .sensors,
                          color: cgm
                              .statusColor,
                          size: 56,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(
                    height: 40,
                  ),

                  Text(
                    cgm.connectionText,
                    textAlign:
                        TextAlign
                            .center,
                    style:
                        const TextStyle(
                      fontSize: 28,
                      fontWeight:
                          FontWeight
                              .bold,
                    ),
                  ),

                  const SizedBox(
                    height: 16,
                  ),

                  Text(
                    cgm.lastError ??
                        "Hang tight while we set up your sensor.",
                    textAlign:
                        TextAlign
                            .center,
                    style:
                        const TextStyle(
                      color: AppColors
                          .textSecondary,
                    ),
                  ),

                  const SizedBox(
                    height: 40,
                  ),

                  if (!isFatal) ...[
                    LinearProgressIndicator(
                      value: cgm
                          .syncProgress,
                      minHeight: 8,
                      borderRadius:
                          BorderRadius
                              .circular(
                        16,
                      ),
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    Text(
                      "${(cgm.syncProgress * 100).toInt()}% complete",
                    ),
                  ],

                  if (cgm
                          .connectionStatus ==
                      CGMConnectionStatus
                          .permissionsDenied) ...[
                    const SizedBox(
                      height: 24,
                    ),
                    PrimaryButton(
                      title:
                          "Open Settings",
                      onTap: () async {
                        await openAppSettings();
                      },
                    ),
                  ],

                  if (isFatal &&
                      cgm.connectionStatus !=
                          CGMConnectionStatus
                              .permissionsDenied) ...[
                    const SizedBox(
                      height: 24,
                    ),
                    PrimaryButton(
                      title: "Back",
                      onTap: () {
                        Navigator.pop(
                          context,
                        );
                      },
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

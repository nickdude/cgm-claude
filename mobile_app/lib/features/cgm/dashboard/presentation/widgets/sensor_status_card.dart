import 'package:flutter/material.dart';

import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../../../../app/theme/app_colors.dart';

import '../../../connect/presentation/providers/cgm_provider.dart';

import '../../../connect/presentation/screens/cgm_scan_screen.dart';

class SensorStatusCard
    extends StatelessWidget {
  const SensorStatusCard({super.key});

  String _subtitleFor(
    CGMProvider provider,
  ) {
    final device =
        provider.activeDevice;

    if (device == null) {
      return "No device paired";
    }

    return "${device.deviceName} • ${device.serialNumber}";
  }

  Widget _trailingFor(
    CGMProvider provider,
  ) {
    if (provider.isReconnecting) {
      return SizedBox(
        height: 18,
        width: 18,
        child:
            CircularProgressIndicator(
          strokeWidth: 2.5,
          color:
              provider.statusColor,
        ),
      );
    }

    return Container(
      height: 12,
      width: 12,
      decoration: BoxDecoration(
        color: provider.statusColor,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _actionFor(
    BuildContext context,
    CGMProvider provider,
  ) {
    switch (
        provider.connectionStatus) {
      case CGMConnectionStatus
            .bluetoothOff:
        return _ActionRow(
          message: provider
                  .lastError ??
              "Turn on Bluetooth to reconnect.",
          buttonLabel:
              "Open Bluetooth Settings",
          onTap: () async {
            // permission_handler can open the system app settings;
            // the user toggles BT from there. Direct BT-enable
            // requires a deprecated permission on Android 13+.
            await openAppSettings();
          },
        );
      case CGMConnectionStatus
            .permissionsDenied:
        return _ActionRow(
          message:
              "Bluetooth & nearby-device permissions are required.",
          buttonLabel:
              "Open Settings",
          onTap: () =>
              openAppSettings(),
        );
      case CGMConnectionStatus
            .outOfRange:
        return _ActionRow(
          message:
              "Sensor is out of range. We'll keep trying.",
          buttonLabel:
              "Retry now",
          onTap: () => provider
              .retryReconnect(),
        );
      case CGMConnectionStatus
            .failed:
      case CGMConnectionStatus
            .authFailed:
        return _ActionRow(
          message: provider
                  .lastError ??
              "Something went wrong.",
          buttonLabel:
              "Retry",
          onTap: () => provider
              .retryReconnect(),
        );
      case CGMConnectionStatus
            .disconnected:
        if (provider
                .activeDevice ==
            null) {
          return _ActionRow(
            message:
                "Pair your CGM sensor to start monitoring.",
            buttonLabel:
                "Pair sensor",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) =>
                          const CGMScanScreen(),
                ),
              );
            },
          );
        }

        return const SizedBox
            .shrink();
      default:
        return const SizedBox
            .shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CGMProvider>(
      builder:
          (context, provider, _) {
        final device =
            provider.activeDevice;

        final daysLeft =
            device == null
                ? null
                : device.expiresAt
                    .difference(
                      DateTime.now(),
                    )
                    .inDays;

        return Container(
          padding:
              const EdgeInsets.all(
            20,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius
                    .circular(24),
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment
                    .start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets
                            .all(14),
                    decoration:
                        BoxDecoration(
                      color: provider
                          .statusColor
                          .withOpacity(
                        0.1,
                      ),
                      shape:
                          BoxShape
                              .circle,
                    ),
                    child: Icon(
                      Icons.sensors,
                      color: provider
                          .statusColor,
                    ),
                  ),
                  const SizedBox(
                    width: 16,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Text(
                          provider
                              .connectionText,
                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight
                                    .bold,
                          ),
                        ),
                        const SizedBox(
                          height: 4,
                        ),
                        Text(
                          _subtitleFor(
                            provider,
                          ),
                          style:
                              const TextStyle(
                            color: AppColors
                                .textSecondary,
                            fontSize:
                                12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _trailingFor(
                    provider,
                  ),
                ],
              ),

              if (device !=
                  null) ...[
                const SizedBox(
                  height: 16,
                ),
                const Divider(
                  height: 1,
                ),
                const SizedBox(
                  height: 12,
                ),
                _metaRow(
                  label:
                      "Manufacturer",
                  value: device
                      .manufacturer,
                ),
                _metaRow(
                  label:
                      "Expires in",
                  value: daysLeft ==
                          null
                      ? "--"
                      : daysLeft <= 0
                          ? "Expired"
                          : "$daysLeft days",
                ),
              ],

              _actionFor(
                context,
                provider,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _metaRow({
    required String label,
    required String value,
  }) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 4,
      ),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment
                .spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors
                  .textSecondary,
              fontSize: 13,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight:
                  FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionRow
    extends StatelessWidget {
  final String message;
  final String buttonLabel;
  final VoidCallback onTap;

  const _ActionRow({
    required this.message,
    required this.buttonLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.only(
        top: 12,
      ),
      child: Container(
        padding:
            const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.primary
              .withOpacity(0.05),
          borderRadius:
              BorderRadius.circular(
            14,
          ),
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment
                  .start,
          children: [
            Text(
              message,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors
                    .textSecondary,
              ),
            ),
            const SizedBox(
              height: 8,
            ),
            Align(
              alignment: Alignment
                  .centerLeft,
              child: TextButton(
                onPressed: onTap,
                style: TextButton
                    .styleFrom(
                  padding:
                      EdgeInsets
                          .zero,
                  minimumSize:
                      Size.zero,
                  tapTargetSize:
                      MaterialTapTargetSize
                          .shrinkWrap,
                ),
                child: Text(
                  buttonLabel,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

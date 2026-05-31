import 'package:flutter/material.dart';

import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../../../../app/theme/app_colors.dart';

import '../../../connect/presentation/providers/cgm_provider.dart';

import '../../../connect/presentation/screens/cgm_scan_screen.dart';

class SensorStatusCard extends StatelessWidget {
  const SensorStatusCard({super.key});

  String _subtitleFor(CGMProvider provider) {
    final device = provider.activeDevice;

    if (device == null) {
      return "No device paired";
    }

    return "${device.deviceName} • ${device.serialNumber}";
  }

  // While a sensor is already paired, the session manager keeps
  // auto-retrying after a transient drop/failure. Surfacing "Connection
  // Failed" in that window is a false signal, so on the dashboard card we
  // present it as "Reconnecting" instead.
  bool _isFalseFailure(CGMProvider provider) =>
      provider.connectionStatus == CGMConnectionStatus.failed &&
      provider.activeDevice != null;

  String _titleFor(CGMProvider provider) =>
      _isFalseFailure(provider) ? "Reconnecting" : provider.connectionText;

  Color _colorFor(CGMProvider provider) =>
      _isFalseFailure(provider) ? Colors.blue : provider.statusColor;

  bool _showSpinner(CGMProvider provider) =>
      provider.isReconnecting || _isFalseFailure(provider);

  Widget _trailingFor(CGMProvider provider) {
    if (_showSpinner(provider)) {
      return SizedBox(
        height: 18,
        width: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: _colorFor(provider),
        ),
      );
    }

    return Container(
      height: 12,
      width: 12,
      decoration: BoxDecoration(
        color: _colorFor(provider),
        shape: BoxShape.circle,
      ),
    );
  }

  // Only called when the sensor is not connected (see build). Renders the
  // contextual failed/retry/pair action for the current disconnected state.
  Widget _actionFor(BuildContext context, CGMProvider provider) {
    switch (provider.connectionStatus) {
      case CGMConnectionStatus.bluetoothOff:
        return _ActionRow(
          message: provider.lastError ?? "Turn on Bluetooth to reconnect.",
          buttonLabel: "Open Bluetooth Settings",
          onTap: () async {
            // permission_handler can open the system app settings;
            // the user toggles BT from there. Direct BT-enable
            // requires a deprecated permission on Android 13+.
            await openAppSettings();
          },
        );
      case CGMConnectionStatus.permissionsDenied:
        return _ActionRow(
          message: "Bluetooth & nearby-device permissions are required.",
          buttonLabel: "Open Settings",
          onTap: () => openAppSettings(),
        );
      case CGMConnectionStatus.outOfRange:
        return _ActionRow(
          message: "Sensor is out of range. We'll keep trying.",
          buttonLabel: "Retry now",
          onTap: () => provider.retryReconnect(),
        );
      case CGMConnectionStatus.failed:
      // case CGMConnectionStatus.authFailed:
      //   return _ActionRow(
      //     message: provider.lastError ?? "Something went wrong.",
      //     buttonLabel: "Retry",
      //     onTap: () => provider.retryReconnect(),
      //   );
      case CGMConnectionStatus.disconnected:
        if (provider.activeDevice == null) {
          return _ActionRow(
            message: "Pair your CGM sensor to start monitoring.",
            buttonLabel: "Pair sensor",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CGMScanScreen()),
              );
            },
          );
        }

        return const SizedBox.shrink();
      default:
        return const SizedBox.shrink();
    }
  }

  bool _isConnected(CGMProvider provider) {
    switch (provider.connectionStatus) {
      case CGMConnectionStatus.active:
      case CGMConnectionStatus.syncing:
      case CGMConnectionStatus.warmup:
        return true;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CGMProvider>(
      builder: (context, provider, _) {
        final device = provider.activeDevice;

        final daysLeft = device?.expiresAt.difference(DateTime.now()).inDays;

        final connected = _isConnected(provider);

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFFFFF), Color(0xFFF8FBFF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE6EEF8)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D0F172A),
                blurRadius: 18,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _colorFor(provider).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.sensors, color: _colorFor(provider)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _titleFor(provider),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _subtitleFor(provider),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _trailingFor(provider),
                ],
              ),

              if (device != null) ...[
                const SizedBox(height: 16),
                Container(height: 1, color: const Color(0xFFE9EEF6)),
                const SizedBox(height: 14),
                _metaRow(label: "Manufacturer", value: device.manufacturer),
                _metaRow(
                  label: "Expires in",
                  value: daysLeft == null
                      ? "--"
                      : daysLeft <= 0
                      ? "Expired"
                      : "$daysLeft days",
                ),
                _metaRow(label: "Serial", value: device.serialNumber),
              ],

              if (!connected) ...[
                const SizedBox(height: 16),
                _actionFor(context, provider),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _metaRow({required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
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
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: onTap,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 0,
                    vertical: 0,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  buttonLabel,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

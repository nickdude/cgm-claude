import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../../app/theme/app_colors.dart';

import '../../../../auth/presentation/widgets/auth_primary_button.dart';
import '../../../../auth/presentation/widgets/auth_text_field.dart';

import 'cgm_connecting_screen.dart';

class CGMScanScreen extends StatefulWidget {
  const CGMScanScreen({super.key});
  @override
  State<CGMScanScreen> createState() => _CGMScanScreenState();
}

class _CGMScanScreenState extends State<CGMScanScreen> {
  static const String manufacturer = "Eaglenos";

  static const String deviceName = "Eaglenos CGM";

  final serialController = TextEditingController();

  final scannerController = MobileScannerController();

  bool _connecting = false;

  bool _handledQr = false;

  bool _processingScan = false;

  bool _torchOn = false;

  bool _usingFrontCamera = false;

  @override
  void dispose() {
    scannerController.dispose();

    serialController.dispose();

    super.dispose();
  }

  Future<void> _connect({bool triggeredByQr = false}) async {
    if (_connecting) return;

    final sn = serialController.text.trim();

    if (sn.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter the sensor's serial number")),
      );

      return;
    }

    setState(() {
      _connecting = true;
    });

    if (triggeredByQr) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("QR found. Connecting to sensor $sn...")),
      );
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CGMConnectingScreen(
          serialNumber: sn,
          deviceName: deviceName,
          manufacturer: manufacturer,
        ),
      ),
    );

    if (!mounted) return;

    setState(() {
      _connecting = false;
    });
  }

  String? _extractSerialFromQr(String raw) {
    final trimmed = raw.trim();

    if (trimmed.isEmpty) {
      return null;
    }

    final uri = Uri.tryParse(trimmed);

    final fromQuery = uri?.queryParameters["ble_code"]?.trim();

    if (fromQuery != null && fromQuery.isNotEmpty) {
      return fromQuery;
    }

    return null;
  }

  Future<void> _openQrScanner() async {
    _handledQr = false;

    _processingScan = false;

    _torchOn = false;

    _usingFrontCamera = false;

    String qrHint = "Scan QR with ble_code";

    Color qrHintBg = Colors.black.withValues(alpha: 0.62);

    await scannerController.start();

    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (context, setBottomSheetState) {
            return SafeArea(
              child: SizedBox(
                height: MediaQuery.of(bottomSheetContext).size.height * 0.72,
                child: Stack(
                  children: [
                    MobileScanner(
                      controller: scannerController,
                      onDetect: (capture) async {
                        if (_handledQr || _processingScan) {
                          return;
                        }

                        final barcodes = capture.barcodes;

                        if (barcodes.isEmpty) {
                          return;
                        }

                        _processingScan = true;

                        final rawValue = barcodes.first.rawValue ?? "";

                        final serial = _extractSerialFromQr(rawValue);

                        if (serial == null) {
                          setBottomSheetState(() {
                            qrHint =
                                "Invalid QR. Expect link with ble_code, e.g. ?ble_code=50101990";
                            qrHintBg = const Color(0xFFB3261E);
                          });

                          _processingScan = false;
                          return;
                        }

                        _handledQr = true;

                        serialController.text = serial;

                        if (bottomSheetContext.mounted) {
                          Navigator.of(bottomSheetContext).pop();
                        }

                        await scannerController.stop();

                        if (!mounted) return;

                        await _connect(triggeredByQr: true);
                      },
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton(
                        onPressed: () {
                          Navigator.pop(bottomSheetContext);
                        },
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Row(
                        children: [
                          _ScannerActionButton(
                            icon: _torchOn ? Icons.flash_on : Icons.flash_off,
                            onTap: () async {
                              await scannerController.toggleTorch();

                              setBottomSheetState(() {
                                _torchOn = !_torchOn;
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          _ScannerActionButton(
                            icon: _usingFrontCamera
                                ? Icons.camera_front
                                : Icons.camera_rear,
                            onTap: () async {
                              await scannerController.switchCamera();

                              setBottomSheetState(() {
                                _usingFrontCamera = !_usingFrontCamera;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 18,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: qrHintBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          qrHint,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    await scannerController.stop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Connect Sensor",
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            const Text(
              "Add your sensor details",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              "Scan your Eaglenos QR code or enter serial manually.",
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 24),

            AuthPrimaryButton(
              label: "Scan QR",
              isLoading: _connecting,
              onTap: _openQrScanner,
            ),

            const SizedBox(height: 16),

            Container(height: 1, color: AppColors.border),

            const SizedBox(height: 16),

            const Text(
              "Sensor serial number",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 12),

            AuthTextField(
              controller: serialController,
              label: "SN",
              hint: "Enter serial number (e.g. 50101990)",
              prefixIcon: Icons.qr_code_2,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _connect(),
            ),

            const SizedBox(height: 20),

            _buildStaticInfoTile(
              title: "Manufacturer",
              value: manufacturer,
              icon: Icons.apartment,
            ),

            const SizedBox(height: 12),

            _buildStaticInfoTile(
              title: "Device name",
              value: deviceName,
              icon: Icons.sensors,
            ),

            const SizedBox(height: 40),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF2FF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.primary),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Make sure sensor is within 1m and Bluetooth + Location are enabled.",
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            AuthPrimaryButton(
              label: "Connect",
              isLoading: _connecting,
              onTap: _connect,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStaticInfoTile({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScannerActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ScannerActionButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.5),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

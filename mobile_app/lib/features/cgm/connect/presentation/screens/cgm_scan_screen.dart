import 'package:flutter/material.dart';

import '../../../../../app/theme/app_colors.dart';

import '../../../../../core/widgets/custom_textfield.dart';

import '../../../../../core/widgets/primary_button.dart';

import 'cgm_connecting_screen.dart';

class CGMScanScreen
    extends StatefulWidget {
  const CGMScanScreen({super.key});

  @override
  State<CGMScanScreen> createState() =>
      _CGMScanScreenState();
}

class _CGMScanScreenState
    extends State<CGMScanScreen> {
  final serialController =
      TextEditingController();

  String manufacturer = "Eaglenos";

  String deviceName = "Eaglenos CGM";

  @override
  void dispose() {
    serialController.dispose();

    super.dispose();
  }

  void _connect() {
    final sn = serialController.text
        .trim();

    if (sn.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            "Enter the sensor's serial number",
          ),
        ),
      );

      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            CGMConnectingScreen(
          serialNumber: sn,
          deviceName: deviceName,
          manufacturer: manufacturer,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Connect Sensor",
        ),
      ),

      body: SingleChildScrollView(
        padding:
            const EdgeInsets.all(24),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            const Text(
              "Sensor Serial Number",
              style: TextStyle(
                fontSize: 16,
                fontWeight:
                    FontWeight.w600,
              ),
            ),

            const SizedBox(height: 12),

            CustomTextField(
              controller:
                  serialController,
              hint:
                  "Enter serial number (e.g. 50101990)",
            ),

            const SizedBox(height: 20),

            const Text(
              "Manufacturer",
              style: TextStyle(
                fontSize: 16,
                fontWeight:
                    FontWeight.w600,
              ),
            ),

            const SizedBox(height: 12),

            DropdownButtonFormField<
                String>(
              value: manufacturer,
              items: const [
                DropdownMenuItem(
                  value: "Eaglenos",
                  child: Text(
                    "Eaglenos",
                  ),
                ),
                DropdownMenuItem(
                  value: "Abbott",
                  child: Text(
                    "Abbott",
                  ),
                ),
                DropdownMenuItem(
                  value: "Dexcom",
                  child: Text(
                    "Dexcom",
                  ),
                ),
                DropdownMenuItem(
                  value:
                      "Medtronic",
                  child: Text(
                    "Medtronic",
                  ),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    manufacturer =
                        value;
                  });
                }
              },
            ),

            const SizedBox(height: 20),

            const Text(
              "Device Name",
              style: TextStyle(
                fontSize: 16,
                fontWeight:
                    FontWeight.w600,
              ),
            ),

            const SizedBox(height: 12),

            DropdownButtonFormField<
                String>(
              value: deviceName,
              items: const [
                DropdownMenuItem(
                  value:
                      "Eaglenos CGM",
                  child: Text(
                    "Eaglenos CGM",
                  ),
                ),
                DropdownMenuItem(
                  value:
                      "Libre Sensor",
                  child: Text(
                    "Libre Sensor",
                  ),
                ),
                DropdownMenuItem(
                  value:
                      "Dexcom G7",
                  child: Text(
                    "Dexcom G7",
                  ),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    deviceName =
                        value;
                  });
                }
              },
            ),

            const SizedBox(height: 40),

            Container(
              padding:
                  const EdgeInsets.all(
                16,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary
                    .withOpacity(0.06),
                borderRadius:
                    BorderRadius
                        .circular(16),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors
                        .primary,
                  ),
                  SizedBox(
                    width: 12,
                  ),
                  Expanded(
                    child: Text(
                      "Make sure the sensor is within 1m and Bluetooth + Location are enabled.",
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            PrimaryButton(
              title: "Connect",
              onTap: _connect,
            ),
          ],
        ),
      ),
    );
  }
}

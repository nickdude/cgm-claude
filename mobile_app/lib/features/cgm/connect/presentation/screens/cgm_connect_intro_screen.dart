import 'package:flutter/material.dart';

import '../../../../../../core/widgets/primary_button.dart';

class CGMConnectIntroScreen
    extends StatelessWidget {
  const CGMConnectIntroScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding:
              const EdgeInsets.all(24),

          child: Column(
            children: [
              const Spacer(),

              Container(
                height: 220,
                width: 220,

                decoration: BoxDecoration(
                  color:
                      Colors.blue.shade50,

                  shape: BoxShape.circle,
                ),

                child: const Icon(
                  Icons.bluetooth_searching,

                  size: 100,

                  color: Colors.blue,
                ),
              ),

              const SizedBox(height: 40),

              const Text(
                "Connect Your CGM",

                textAlign: TextAlign.center,

                style: TextStyle(
                  fontSize: 34,

                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                "Pair your CGM device to start monitoring glucose in real-time.",

                textAlign: TextAlign.center,

                style: TextStyle(
                  fontSize: 16,
                ),
              ),

              const Spacer(),

              PrimaryButton(
                title: "Start Connecting",

                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const Scaffold(
                            body: Center(
                              child: Text(
                                "SDK Scan Screen Coming",
                              ),
                            ),
                          ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
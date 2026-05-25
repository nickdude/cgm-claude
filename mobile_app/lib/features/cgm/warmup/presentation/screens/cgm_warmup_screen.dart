import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../dashboard/presentation/screens/main_navigation_screen.dart';

class CGMWarmupScreen
    extends StatefulWidget {
  const CGMWarmupScreen({
    super.key,
  });

  @override
  State<CGMWarmupScreen>
      createState() =>
          _CGMWarmupScreenState();
}

class _CGMWarmupScreenState
    extends State<CGMWarmupScreen> {
  int secondsLeft = 15;

  Timer? timer;

  @override
  void initState() {
    super.initState();

    startTimer();
  }

  void startTimer() {
    timer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (secondsLeft == 0) {
          timer.cancel();

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  const MainNavigationScreen(),
            ),
          );
        } else {
          setState(() {
            secondsLeft--;
          });
        }
      },
    );
  }

  @override
  void dispose() {
    timer?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding:
            const EdgeInsets.all(24),

        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [
            const CircularProgressIndicator(
              strokeWidth: 8,
            ),

            const SizedBox(height: 40),

            const Text(
              "Sensor Warmup",

              style: TextStyle(
                fontSize: 32,

                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            Text(
              "$secondsLeft sec remaining",

              style: const TextStyle(
                fontSize: 20,
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              "Your CGM is preparing glucose readings.",
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

import '../../../../core/storage/storage_service.dart';

import '../../../auth/presentation/screens/login_screen.dart';

import '../../../profile/presentation/screens/profile_setup_screen.dart';

import '../../../onboarding/presentation/screens/onboarding_screen.dart';

import '../../../cgm/connect/presentation/screens/cgm_connect_intro_screen.dart';

import '../../../dashboard/presentation/screens/main_navigation_screen.dart';

class SplashScreen
    extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() =>
      _SplashScreenState();
}

class _SplashScreenState
    extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    init();
  }

  Future<void> init() async {
    await Future.delayed(
      const Duration(seconds: 2),
    );

    final token =
        await StorageService.getToken();

    if (!mounted) return;

    if (token == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const LoginScreen(),
        ),
      );

      return;
    }

    // TEMP MOCK FLOW

    final isProfileCompleted =
        false;

    final isOnboardingCompleted =
        false;

    final isCgmConnected = false;

    if (!isProfileCompleted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const ProfileSetupScreen(),
        ),
      );

      return;
    }

    if (!isOnboardingCompleted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const OnboardingScreen(),
        ),
      );

      return;
    }

    if (!isCgmConnected) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const CGMConnectIntroScreen(),
        ),
      );

      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const MainNavigationScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,

        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary,
              AppColors.secondary,
            ],

            begin: Alignment.topLeft,

            end: Alignment.bottomRight,
          ),
        ),

        child: const Column(
          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [
            Icon(
              Icons.monitor_heart,
              color: Colors.white,
              size: 100,
            ),

            SizedBox(height: 24),

            Text(
              "CGM Platform",

              style: TextStyle(
                color: Colors.white,

                fontSize: 34,

                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
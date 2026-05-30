import 'package:flutter/material.dart';

import '../../features/auth/data/models/user_model.dart';

import '../../features/cgm/connect/presentation/screens/cgm_connect_intro_screen.dart';

import '../../features/dashboard/presentation/screens/main_navigation_screen.dart';

import '../../features/onboarding/presentation/screens/onboarding_screen.dart';

import '../../features/profile/presentation/screens/profile_setup_screen.dart';

import '../../features/welcome/presentation/screens/welcome_screen.dart';

class AppRouter {
  static Widget resolveHome({
    required String? token,
    required UserModel? user,
  }) {
    if (token == null ||
        token.isEmpty) {
      return const WelcomeScreen();
    }

    if (user == null) {
      return const WelcomeScreen();
    }

    if (!user.isProfileCompleted) {
      return const ProfileSetupScreen();
    }

    if (!user
        .isOnboardingCompleted) {
      return const OnboardingScreen();
    }

    if (!user.isCgmConnected) {
      return const CGMConnectIntroScreen();
    }

    return const MainNavigationScreen();
  }

  static Future<void> goToHome(
    BuildContext context, {
    required String? token,
    required UserModel? user,
  }) async {
    final next = resolveHome(
      token: token,
      user: user,
    );

    await Navigator
        .pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => next,
      ),
      (route) => false,
    );
  }
}

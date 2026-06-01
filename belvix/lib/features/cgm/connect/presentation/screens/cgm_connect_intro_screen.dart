import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../../../../../app/router/app_router.dart';

import '../../../../../app/theme/app_colors.dart';

import '../../../../../core/storage/storage_service.dart';

import '../../../../../core/widgets/primary_button.dart';

import '../../../../auth/presentation/providers/auth_provider.dart';

import 'cgm_scan_screen.dart';

class CGMConnectIntroScreen
    extends StatelessWidget {
  const CGMConnectIntroScreen({
    super.key,
  });

  Future<void> _skip(
    BuildContext context,
  ) async {
    final auth =
        context.read<AuthProvider>();

    await auth.markCgmConnected();

    if (!context.mounted) return;

    final token = await StorageService
        .getToken();

    if (!context.mounted) return;

    await AppRouter.goToHome(
      context,
      token: token,
      user: auth.currentUser,
    );
  }

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
                decoration:
                    BoxDecoration(
                  color: AppColors
                      .primary
                      .withOpacity(
                    0.08,
                  ),
                  shape:
                      BoxShape.circle,
                ),
                child: const Icon(
                  Icons
                      .bluetooth_searching,
                  size: 100,
                  color: AppColors
                      .primary,
                ),
              ),

              const SizedBox(
                height: 40,
              ),

              const Text(
                "Connect Your CGM",
                textAlign:
                    TextAlign.center,
                style: TextStyle(
                  fontSize: 34,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              const Text(
                "Pair your CGM device to start monitoring glucose in real-time.",
                textAlign:
                    TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors
                      .textSecondary,
                ),
              ),

              const Spacer(),

              PrimaryButton(
                title:
                    "Start Connecting",
                backgroundColor:
                    AppColors
                        .textPrimary,
                foregroundColor:
                    Colors.white,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const CGMScanScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(
                height: 16,
              ),

              TextButton(
                onPressed: () =>
                    _skip(context),
                style: TextButton
                    .styleFrom(
                  foregroundColor:
                      AppColors
                          .textPrimary,
                ),
                child: const Text(
                  "Skip for now",
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

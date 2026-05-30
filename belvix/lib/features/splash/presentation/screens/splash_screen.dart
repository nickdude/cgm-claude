import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../../../../app/constants/app_assets.dart';

import '../../../../app/router/app_router.dart';

import '../../../../app/theme/app_colors.dart';

import '../../../../core/storage/storage_service.dart';

import '../../../auth/presentation/providers/auth_provider.dart';

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

    _init();
  }

  Future<void> _init() async {
    final start = DateTime.now();

    final auth =
        context.read<AuthProvider>();

    await auth.loadCachedSession();

    final token = await StorageService
        .getToken();

    final elapsed = DateTime.now()
        .difference(start);

    const minSplash = Duration(
      milliseconds: 1200,
    );

    if (elapsed < minSplash) {
      await Future.delayed(
        minSplash - elapsed,
      );
    }

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
      body: Container(
        width: double.infinity,

        decoration:
            const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary,
              AppColors.secondary,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),

        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [
            // Brand mark sits on a soft white plate so the multi-colour
            // logo reads cleanly against the gradient background.
            Container(
              width: 132,
              height: 132,
              padding: const EdgeInsets
                  .all(18),
              decoration:
                  const BoxDecoration(
                color: Colors.white,
                shape: BoxShape
                    .circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(
                      0x33000000,
                    ),
                    blurRadius: 24,
                    offset: Offset(
                      0,
                      8,
                    ),
                  ),
                ],
              ),
              child: Image.asset(
                AppAssets.appLogo,
                fit: BoxFit.contain,
              ),
            ),

            const SizedBox(
              height: 24,
            ),

            const Text(
              "CGM Platform",
              style: TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 16,
            ),

            const SizedBox(
              height: 24,
              width: 24,
              child:
                  CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

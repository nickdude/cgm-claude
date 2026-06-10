import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'app/theme/app_theme.dart';

import 'core/constants/app_globals.dart';

import 'core/services/notification_service.dart';

import 'features/auth/presentation/providers/auth_provider.dart';

import 'features/cgm/connect/presentation/providers/cgm_provider.dart';

import 'features/cgm/dashboard/presentation/providers/cgm_dashboard_provider.dart';

import 'features/cgm/timeline/presentation/providers/timeline_provider.dart';

import 'features/cgm/sdk/cgm_sdk.dart';

import 'features/cgm/session/cgm_session_manager.dart';

import 'features/exercise/presentation/providers/exercise_provider.dart';

import 'features/finger_blood/presentation/providers/finger_blood_provider.dart';

import 'features/food/presentation/providers/food_provider.dart';

import 'features/insulin/presentation/providers/insulin_provider.dart';

import 'features/onboarding/presentation/providers/onboarding_provider.dart';

import 'features/splash/presentation/screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding
      .ensureInitialized();

  try {
    await NotificationService.init();
  } catch (e) {
    debugPrint(
      "NotificationService init failed: $e",
    );
  }

  try {
    await CgmSdk.init();
  } catch (e) {
    debugPrint(
      "CgmSdk init failed: $e",
    );
  }

  // Restores any saved CGM session and kicks off auto-reconnect.
  // Runs before any UI subscribes so the first stream emit is the
  // accurate state.
  try {
    await CgmSessionManager.instance
        .bootstrap();
  } catch (e) {
    debugPrint(
      "CgmSessionManager bootstrap failed: $e",
    );
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() =>
      _MyAppState();
}

class _MyAppState extends State<MyApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance
        .addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance
        .removeObserver(this);

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(
    AppLifecycleState state,
  ) {
    if (state ==
        AppLifecycleState.resumed) {
      CgmSessionManager.instance
          .onAppResumed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create:
              (_) => AuthProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              CGMDashboardProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              TimelineProvider(),
        ),
        ChangeNotifierProvider(
          create:
              (_) => FoodProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              ExerciseProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              InsulinProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              FingerBloodProvider(),
        ),
        ChangeNotifierProvider(
          create:
              (_) => CGMProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              OnboardingProvider(),
        ),
      ],

      child: MaterialApp(
        debugShowCheckedModeBanner:
            false,
        title: "CGM Platform",
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
        navigatorKey: navigatorKey,
      ),
    );
  }
}

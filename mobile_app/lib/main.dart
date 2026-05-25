import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'app/theme/app_theme.dart';

import 'features/auth/presentation/providers/auth_provider.dart';

import 'features/splash/presentation/screens/splash_screen.dart';

import 'features/cgm/dashboard/presentation/providers/cgm_dashboard_provider.dart';

import 'features/food/presentation/providers/food_provider.dart';

import 'features/food/presentation/providers/food_provider.dart';

import 'features/exercise/presentation/providers/exercise_provider.dart';

import 'features/insulin/presentation/providers/insulin_provider.dart';

import 'features/finger_blood/presentation/providers/finger_blood_provider.dart';

import 'features/cgm/connect/presentation/providers/cgm_provider.dart';

import 'core/services/notification_service.dart';

import 'core/constants/app_globals.dart';

import 'features/cgm/sdk/cgm_sdk.dart';

Future<void> main() async {

  WidgetsFlutterBinding
      .ensureInitialized();

  await NotificationService.init();

  await CgmSdk.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create:
              (_) => AuthProvider(),
        ),
        ChangeNotifierProvider(
          create:
              (_) => CGMDashboardProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => FoodProvider(),
        ),
        ChangeNotifierProvider(
          create:
              (_) => ExerciseProvider(),
        ),
        ChangeNotifierProvider(
          create:
              (_) => InsulinProvider(),
        ),
        ChangeNotifierProvider(
          create:
              (_) =>
                  FingerBloodProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => CGMProvider(),
        ),
      ],

      child: MaterialApp(
        debugShowCheckedModeBanner:
            false,

        theme: AppTheme.lightTheme,

        home: const SplashScreen(),

        navigatorKey: navigatorKey,
      ),
    );
  }
}
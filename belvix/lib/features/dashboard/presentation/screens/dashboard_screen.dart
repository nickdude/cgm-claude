import 'package:flutter/material.dart';

import 'main_navigation_screen.dart';

// Kept as a thin alias so existing call sites that imported
// `DashboardScreen` still land on the full main navigation
// (CGM dashboard + Food + Activity + Profile).
class DashboardScreen
    extends StatelessWidget {
  const DashboardScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const MainNavigationScreen();
  }
}

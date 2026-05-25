import 'package:flutter/material.dart';

import '../../../cgm/dashboard/presentation/screens/cgm_dashboard_screen.dart';

import '../../../food/presentation/screens/food_screen.dart';

import '../../../exercise/presentation/screens/activity_screen.dart';

import '../../../profile/presentation/screens/profile_screen.dart';

class MainNavigationScreen
    extends StatefulWidget {
  const MainNavigationScreen({
    super.key,
  });

  @override
  State<MainNavigationScreen>
      createState() =>
          _MainNavigationScreenState();
}

class _MainNavigationScreenState
    extends State<MainNavigationScreen> {
  int currentIndex = 0;

 final screens = [
  const CGMDashboardScreen(),

  const FoodScreen(),

  const ActivityScreen(),

  const ProfileScreen(),
];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screens[currentIndex],

      bottomNavigationBar:
          NavigationBar(
        selectedIndex: currentIndex,

        onDestinationSelected:
            (index) {
          setState(() {
            currentIndex = index;
          });
        },

        destinations: const [
          NavigationDestination(
            icon: Icon(
              Icons.home_outlined,
            ),

            selectedIcon:
                Icon(Icons.home),

            label: "Home",
          ),

          NavigationDestination(
            icon: Icon(
              Icons.restaurant_outlined,
            ),

            selectedIcon:
                Icon(Icons.restaurant),

            label: "Food",
          ),

          NavigationDestination(
            icon: Icon(
              Icons.fitness_center_outlined,
            ),

            selectedIcon:
                Icon(Icons
                    .fitness_center),
            label: "Activity",
          ),

          NavigationDestination(
            icon: Icon(
              Icons.person_outline,
            ),

            selectedIcon:
                Icon(Icons.person),

            label: "Profile",
          ),
        ],
      ),
    );
  }
}
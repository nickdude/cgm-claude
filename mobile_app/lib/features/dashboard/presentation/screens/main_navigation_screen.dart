import 'package:flutter/material.dart';

import '../../../cgm/dashboard/presentation/screens/cgm_dashboard_screen.dart';
import '../../../cgm/data/presentation/screens/cgm_readings_screen.dart';
import '../../../discover/presentation/screens/discover_screen.dart';
import '../../../exercise/presentation/screens/activity_screen.dart';
import '../../../finger_blood/presentation/screens/finger_blood_screen.dart';
import '../../../food/presentation/screens/food_screen.dart';
import '../../../insulin/presentation/screens/insulin_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../widgets/app_bottom_nav_bar.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int currentIndex = 0;

  bool isActionMenuOpen = false;

  late final List<Widget> screens = [
    const CGMDashboardScreen(),
    const CgmReadingsScreen(),
    const DiscoverScreen(),
    const ProfileScreen(),
  ];

  void _setTab(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  void _openQuickActions() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return _QuickActionSheetWrapper(
          onClose: () {
            if (mounted) {
              setState(() {
                isActionMenuOpen = false;
              });
            }
            Navigator.pop(sheetContext);
          },
          child: QuickActionMenu(
            onActionTap: (type) {
              Navigator.pop(sheetContext);
              if (mounted) {
                setState(() {
                  isActionMenuOpen = false;
                });
              }

              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => _quickActionScreen(type)),
              );
            },
          ),
        );
      },
    ).whenComplete(() {
      if (mounted) {
        setState(() {
          isActionMenuOpen = false;
        });
      }
    });
  }

  Widget _quickActionScreen(QuickActionType type) {
    switch (type) {
      case QuickActionType.diet:
        return const FoodScreen();
      case QuickActionType.insulin:
        return const InsulinScreen();
      case QuickActionType.medicine:
        return const _ComingSoonScreen(title: 'Medicine');
      case QuickActionType.exercise:
        return const ActivityScreen();
      case QuickActionType.fingerBlood:
        return const FingerBloodScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: currentIndex, children: screens),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: currentIndex,
        onTabSelected: _setTab,
        isActionMenuOpen: isActionMenuOpen,
        onCenterTap: () {
          if (isActionMenuOpen) {
            Navigator.maybePop(context);
            return;
          }

          setState(() {
            isActionMenuOpen = true;
          });

          _openQuickActions();
        },
      ),
    );
  }
}

class _QuickActionSheetWrapper extends StatelessWidget {
  const _QuickActionSheetWrapper({required this.child, required this.onClose});

  final Widget child;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 26),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 420),
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 46),
                decoration: BoxDecoration(
                  color: const Color(0xFF151D23),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x55000000),
                      blurRadius: 22,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: child,
              ),
              Positioned(
                bottom: -38,
                child: GestureDetector(
                  onTap: onClose,
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.black,
                      size: 34,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ComingSoonScreen extends StatelessWidget {
  const _ComingSoonScreen({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: const Center(child: Text('Coming soon')),
    );
  }
}

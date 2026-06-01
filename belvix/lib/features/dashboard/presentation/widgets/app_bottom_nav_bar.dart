import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    required this.currentIndex,
    required this.onTabSelected,
    this.onCenterTap,
    this.isActionMenuOpen = false,
    this.onQuickActionTap,
    super.key,
  });

  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback? onCenterTap;
  final bool isActionMenuOpen;
  final ValueChanged<QuickActionType>? onQuickActionTap;

  static const _tabs = <_NavTabData>[
    _NavTabData(label: 'Monitor', iconPath: 'assets/icons/monitor.svg'),
    _NavTabData(label: 'Data', iconPath: 'assets/icons/chart.svg'),
    _NavTabData(label: 'Discover', iconPath: 'assets/icons/compass.svg'),
    _NavTabData(label: 'Profile', iconPath: 'assets/icons/user.svg'),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final navHeight = 85 + bottomInset;

    return SizedBox(
      height: navHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Material(
              color: const Color(0xFFF6F6F6),
              child: Container(
                height: navHeight,
                padding: EdgeInsets.only(bottom: bottomInset),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Color(0xFFE2E2E2))),
                ),
                child: Row(
                children: [
                  Expanded(
                    child: _NavTab(
                      data: _tabs[0],
                      selected: currentIndex == 0,
                      onTap: () => onTabSelected(0),
                    ),
                  ),
                  Expanded(
                    child: _NavTab(
                      data: _tabs[1],
                      selected: currentIndex == 1,
                      onTap: () => onTabSelected(1),
                    ),
                  ),
                  const SizedBox(width: 88),
                  Expanded(
                    child: _NavTab(
                      data: _tabs[2],
                      selected: currentIndex == 2,
                      onTap: () => onTabSelected(2),
                    ),
                  ),
                  Expanded(
                    child: _NavTab(
                      data: _tabs[3],
                      selected: currentIndex == 3,
                      onTap: () => onTabSelected(3),
                    ),
                  ),
                ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 7 + bottomInset,
            left: 0,
            right: 0,
            child: Center(
              child: _CenterActionButton(
                onTap: onCenterTap,
                isOpen: isActionMenuOpen,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  const _NavTab({
    required this.data,
    required this.selected,
    required this.onTap,
  });

  final _NavTabData data;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFF111111) : const Color(0xFFA8A8A8);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              data.iconPath,
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
            ),
            const SizedBox(height: 4),
            Text(
              data.label,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CenterActionButton extends StatelessWidget {
  const _CenterActionButton({required this.onTap, required this.isOpen});

  final VoidCallback? onTap;
  final bool isOpen;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Material(
        color: isOpen ? Colors.white : Colors.black,
        shape: isOpen
            ? const CircleBorder(
                side: BorderSide(color: Color(0xFF0E1318), width: 10),
              )
            : const CircleBorder(),
        child: SizedBox(
          width: 92,
          height: 92,
          child: Center(
            child: AnimatedRotation(
              turns: isOpen ? 0.125 : 0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isOpen ? Icons.close : Icons.add,
                color: isOpen ? const Color(0xFF111111) : Colors.white,
                size: isOpen ? 42 : 40,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class QuickActionMenu extends StatelessWidget {
  const QuickActionMenu({required this.onActionTap, super.key});

  final ValueChanged<QuickActionType>? onActionTap;

  static const _items = <_QuickActionItemData>[
    _QuickActionItemData(
      type: QuickActionType.diet,
      label: 'Diet',
      icon: Icons.restaurant,
    ),
    _QuickActionItemData(
      type: QuickActionType.insulin,
      label: 'Insulin',
      icon: Icons.vaccines,
    ),
    // _QuickActionItemData(
    //   type: QuickActionType.medicine,
    //   label: 'Medicine',
    //   icon: Icons.medication,
    // ),
    _QuickActionItemData(
      type: QuickActionType.exercise,
      label: 'Exercise',
      icon: Icons.directions_run,
    ),
    _QuickActionItemData(
      type: QuickActionType.fingerBlood,
      label: 'Finger Blood',
      icon: Icons.water_drop,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF151D23),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      shadowColor: const Color(0x55000000),
      elevation: 10,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
        child: Material(
          color: const Color(0xFF343B42),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < _items.length; i++) ...[
              InkWell(
                onTap: () => onActionTap?.call(_items[i].type),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 13, 16, 13),
                  child: Row(
                    children: [
                      Icon(
                        _items[i].icon,
                        color: const Color(0xFFF1F3F4),
                        size: 25,
                      ),
                      const SizedBox(width: 14),
                      Text(
                        _items[i].label,
                        style: const TextStyle(
                          color: Color(0xFFF0F2F3),
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (i < _items.length - 1)
                Container(
                  height: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 14),
                  color: const Color(0x445F666D),
                ),
            ],
          ],
          ),
        ),
      ),
    );
  }
}

class _NavTabData {
  const _NavTabData({required this.label, required this.iconPath});

  final String label;
  final String iconPath;
}

class _QuickActionItemData {
  const _QuickActionItemData({
    required this.type,
    required this.label,
    required this.icon,
  });

  final QuickActionType type;
  final String label;
  final IconData icon;
}

enum QuickActionType { diet, insulin, medicine, exercise, fingerBlood }

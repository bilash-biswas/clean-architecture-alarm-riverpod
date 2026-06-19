import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({super.key});

  int _getCurrentIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/world-clock')) return 1;
    if (location.startsWith('/timer')) return 2;
    if (location.startsWith('/stopwatch')) return 3;
    if (location.startsWith('/sleep')) return 4;
    return 0; // Default to Alarms (/)
  }

  void _onTabTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/world-clock');
        break;
      case 2:
        context.go('/timer');
        break;
      case 3:
        context.go('/stopwatch');
        break;
      case 4:
        context.go('/sleep');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _getCurrentIndex(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final navBarBg = isDark
        ? const Color(0xFF1E1E24).withOpacity(0.4)
        : Colors.white.withOpacity(0.65);
    final borderColor = isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.black.withOpacity(0.06);
    final shadowColor = isDark
        ? Colors.black.withOpacity(0.4)
        : Colors.black.withOpacity(0.06);

    final alarmsColor = isDark ? const Color(0xFF9D4EDD) : const Color(0xFF7B2CBF);
    final clockColor = isDark ? const Color(0xFFFFB703) : const Color(0xFFD97706);
    final timerColor = isDark ? const Color(0xFF00F5D4) : const Color(0xFF0D9488);
    final stopwatchColor = isDark ? const Color(0xFFFF8500) : const Color(0xFFEA580C);
    final sleepColor = isDark ? const Color(0xFF00BBF9) : const Color(0xFF0284C7);

    return SafeArea(
      bottom: true,
      child: Container(
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
        height: 72,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 20,
              spreadRadius: -2,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: navBarBg,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: borderColor,
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(
                    context: context,
                    index: 0,
                    currentIndex: currentIndex,
                    icon: Icons.alarm,
                    label: 'Alarms',
                    activeColor: alarmsColor,
                  ),
                  _buildNavItem(
                    context: context,
                    index: 1,
                    currentIndex: currentIndex,
                    icon: Icons.language_outlined,
                    label: 'Clock',
                    activeColor: clockColor,
                  ),
                  _buildNavItem(
                    context: context,
                    index: 2,
                    currentIndex: currentIndex,
                    icon: Icons.hourglass_empty_outlined,
                    label: 'Timer',
                    activeColor: timerColor,
                  ),
                  _buildNavItem(
                    context: context,
                    index: 3,
                    currentIndex: currentIndex,
                    icon: Icons.timer_outlined,
                    label: 'Stopwatch',
                    activeColor: stopwatchColor,
                  ),
                  _buildNavItem(
                    context: context,
                    index: 4,
                    currentIndex: currentIndex,
                    icon: Icons.spa_outlined,
                    label: 'Sleep',
                    activeColor: sleepColor,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required int index,
    required int currentIndex,
    required IconData icon,
    required String label,
    required Color activeColor,
  }) {
    final isSelected = index == currentIndex;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final unselectedColor = isDark ? Colors.white.withOpacity(0.4) : Colors.black.withOpacity(0.4);
    final selectedTextColor = isDark ? Colors.white : Colors.black87;
    final unselectedTextColor = isDark ? Colors.white.withOpacity(0.3) : Colors.black.withOpacity(0.4);

    return GestureDetector(
      onTap: () => _onTabTapped(context, index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? activeColor.withOpacity(0.12) : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: isSelected ? activeColor : unselectedColor,
              size: 22,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? selectedTextColor : unselectedTextColor,
              fontSize: 9,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}


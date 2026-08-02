import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class CustomFooter extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onNavItemTap;
  final String? userRole; // 'vendor' or 'user'

  const CustomFooter({
    required this.selectedIndex,
    required this.onNavItemTap,
    this.userRole = 'user',
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 360;
    final footerHeight = isSmall ? 78.0 : 86.0;

    return Container(
      margin: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom,
      ),
      height: footerHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppTheme.borderColor, width: 0.8),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
          BoxShadow(
            color: AppTheme.saffron.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: userRole == 'vendor'
            ? [
                // Vendor tabs: Home, Societies, Earnings, Profile
                _buildNavItem(context, '🏠', 'Home', 0),
                _buildNavItem(context, '🏢', 'Societies', 1),
                _buildNavItem(context, '💰', 'Earnings', 2),
                _buildNavItem(context, '👤', 'Profile', 3),
              ]
            : [
                // User tabs: Home, SOS, AI Chat, Profile
                _buildNavItem(context, '🏠', 'Home', 0),
                _buildNavItem(context, '🆘', 'SOS', 1),
                _buildNavItem(context, '🤖', 'AI Chat', 2),
                _buildNavItem(context, '👤', 'Profile', 3),
        ],
      ),
    );
  }

  Widget _buildNavItem(
      BuildContext context, String icon, String label, int index) {
    final isActive = selectedIndex == index;

    return GestureDetector(
      onTap: () => onNavItemTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOut,
                padding: EdgeInsets.all(isActive ? 5 : 3),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppTheme.saffron.withOpacity(0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: isActive
                      ? Border.all(
                          color: AppTheme.saffron.withOpacity(0.2),
                          width: 1,
                        )
                      : null,
                ),
                child: AnimatedScale(
                  scale: isActive ? 1.1 : 1.0,
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeInOut,
                  child: Text(
                    icon,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
              const SizedBox(height: 1),
              AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOut,
                height: isActive ? 2.5 : 0,
                width: isActive ? 20 : 0,
                decoration: BoxDecoration(
                  color: AppTheme.saffron,
                  borderRadius: BorderRadius.circular(1.25),
                ),
              ),
              const SizedBox(height: 1),
              SizedBox(
                height: 8.5,
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 350),
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.bold,
                    color: isActive
                        ? AppTheme.saffron
                        : Colors.grey.shade400,
                    height: 1,
                  ),
                  child: Text(label),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

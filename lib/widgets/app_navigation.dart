import 'package:flutter/material.dart';
import 'package:testetrack/core/app_theme.dart';

class AppNavigation extends StatelessWidget {
  final String currentRoute;
  final Function(String) onNavigate;

  const AppNavigation({
    super.key,
    required this.currentRoute,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            context,
            'Home',
            Icons.home_outlined,
            currentRoute == '/home',
            () => onNavigate('/home'),
          ),
          _buildNavItem(
            context,
            'Add',
            Icons.add_circle_outline,
            currentRoute == '/add_recipe',
            () => onNavigate('/add_recipe'),
          ),
          _buildNavItem(
            context,
            'Location',
            Icons.location_on_outlined,
            currentRoute == '/location',
            () => onNavigate('/location'),
          ),
          _buildNavItem(
            context,
            'Favorites',
            Icons.favorite_border,
            currentRoute == '/favorites',
            () => onNavigate('/favorites'),
          ),
          _buildNavItem(
            context,
            'Settings',
            Icons.settings_outlined,
            currentRoute == '/settings' || currentRoute == '/profile',
            () => onNavigate('/settings'),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    String label,
    IconData icon,
    bool isActive,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? AppTheme.primary : AppTheme.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? AppTheme.primary : AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
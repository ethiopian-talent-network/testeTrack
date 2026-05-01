import 'package:flutter/material.dart';
import 'package:testetrack/core/app_theme.dart';

class  ResponsiveSearchBar extends StatelessWidget {
  final Function(String) onChanged;
  final Function(String)? onSubmitted;

  const  ResponsiveSearchBar({
    super.key,
    required this.onChanged,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.searchBoxDecoration,
      child: TextField(
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        decoration: const InputDecoration(
          hintText: 'Search recipes...',
          prefixIcon: Icon(Icons.search, color: AppTheme.textSecondary),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        style: const TextStyle(color: AppTheme.textPrimary),
      ),
    );
  }
}

class ResponsiveHelper {
  // Breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1200;
  static const double desktopBreakpoint = 1800;

  // Screen size categories
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= tabletBreakpoint;
  }

  // Grid columns based on screen size
  static int getGridColumns(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) return 2;
    if (width < 900) return 3;
    if (width < 1200) return 4;
    return 5;
  }

  // Aspect ratio based on screen size
  static double getCardAspectRatio(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) return 0.75;
    if (width < 900) return 0.8;
    return 0.85;
  }

  // Padding based on screen size
  static EdgeInsets getScreenPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) return const EdgeInsets.all(16);
    if (width < 1200) return const EdgeInsets.all(24);
    return const EdgeInsets.all(32);
  }

  // Font sizes based on screen size
  static double getHeadlineFontSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) return 24;
    if (width < 1200) return 28;
    return 32;
  }

  static double getTitleFontSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) return 18;
    if (width < 1200) return 20;
    return 22;
  }

  static double getBodyFontSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) return 14;
    if (width < 1200) return 16;
    return 18;
  }

  // Button sizes based on screen size
  static double getButtonHeight(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) return 44;
    if (width < 1200) return 48;
    return 52;
  }

  // Icon sizes based on screen size
  static double getIconSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) return 20;
    if (width < 1200) return 24;
    return 28;
  }

  // Spacing based on screen size
  static double getSpacing(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) return 8;
    if (width < 1200) return 12;
    return 16;
  }

  // Card elevation based on screen size
  static double getCardElevation(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) return 2;
    if (width < 1200) return 4;
    return 8;
  }

  // Border radius based on screen size
  static double getBorderRadius(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) return 8;
    if (width < 1200) return 12;
    return 16;
  }

  // Layout helpers
  static Widget buildResponsiveLayout({
    required BuildContext context,
    required Widget mobile,
    Widget? tablet,
    Widget? desktop,
  }) {
    if (ResponsiveHelper.isDesktop(context) && desktop != null) {
      return desktop;
    } else if (ResponsiveHelper.isTablet(context) && tablet != null) {
      return tablet;
    }
    return mobile;
  }

  // Navigation layout based on screen size
  static bool shouldUseBottomNav(BuildContext context) {
    return ResponsiveHelper.isMobile(context);
  }

  static bool shouldUseRailNav(BuildContext context) {
    return ResponsiveHelper.isTablet(context);
  }

  static bool shouldUseDrawerNav(BuildContext context) {
    return ResponsiveHelper.isDesktop(context);
  }
// Content width constraints
  static double getMaxContentWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 1200) return double.infinity;
    if (width < 1800) return 1200;
    return 1400;
  }

  // Safe area handling
  static EdgeInsets getSafeAreaPadding(BuildContext context) {
    return MediaQuery.of(context).padding;
  }

  // Keyboard visibility
  static bool isKeyboardVisible(BuildContext context) {
    return MediaQuery.of(context).viewInsets.bottom > 0;
  }

  // Orientation
  static bool isPortrait(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait;
  }

  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  // Device pixel ratio
  static double getPixelRatio(BuildContext context) {
    return MediaQuery.of(context).devicePixelRatio;
  }

  // Screen dimensions
  static Size getScreenSize(BuildContext context) {
    return MediaQuery.of(context).size;
  }

  static double getScreenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  static double getScreenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }
}
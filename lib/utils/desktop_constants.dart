import 'package:flutter/material.dart';

/// Responsive utility class that adapts to both mobile and desktop
class ResponsiveUtils {
  // Breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  // Screen type detection
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileBreakpoint;

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= tabletBreakpoint;

  static bool isVerySmallScreen(BuildContext context) =>
      MediaQuery.of(context).size.width < 360;

  // Responsive padding
  static double getResponsivePadding(BuildContext context) {
    if (isMobile(context)) return 16;
    if (isTablet(context)) return 20;
    return 24;
  }

  static double getResponsiveCardPadding(BuildContext context) {
    if (isMobile(context)) return 12;
    if (isTablet(context)) return 16;
    return 20;
  }

  static double getResponsiveVerticalSpacing(BuildContext context) {
    if (isMobile(context)) return 12;
    if (isTablet(context)) return 14;
    return 16;
  }

  static double getResponsiveHorizontalSpacing(BuildContext context) {
    if (isMobile(context)) return 12;
    if (isTablet(context)) return 14;
    return 16;
  }

  static double getResponsiveButtonHeight(BuildContext context) {
    if (isMobile(context)) return 44;
    if (isTablet(context)) return 46;
    return 48;
  }

  static double getResponsiveCardHeight(
    BuildContext context,
    double baseHeight,
  ) {
    if (isMobile(context)) return baseHeight * 0.8;
    if (isTablet(context)) return baseHeight * 0.9;
    return baseHeight;
  }

  static double getResponsiveIconSize(BuildContext context, double baseSize) {
    if (isMobile(context)) return baseSize * 0.9;
    return baseSize;
  }

  static double getResponsiveFontSize(
    BuildContext context,
    double baseFontSize,
  ) {
    if (isVerySmallScreen(context)) return baseFontSize * 0.9;
    if (isMobile(context)) return baseFontSize * 0.95;
    return baseFontSize;
  }

  // Content padding
  static EdgeInsets getResponsiveContentPadding(BuildContext context) {
    final padding = getResponsivePadding(context);
    return EdgeInsets.all(padding);
  }

  static EdgeInsets getResponsiveCardPaddingInsets(BuildContext context) {
    final padding = getResponsiveCardPadding(context);
    return EdgeInsets.all(padding);
  }

  // Grid columns
  static int getResponsiveGridColumns(
    BuildContext context, {
    int maxColumns = 4,
  }) {
    if (isMobile(context)) return 1;
    if (isTablet(context)) return 2;
    return maxColumns;
  }

  // Sidebar width
  static double getResponsiveSidebarWidth(BuildContext context) {
    if (isMobile(context)) return 280;
    return 250;
  }

  // Max content width
  static double getResponsiveMaxContentWidth(BuildContext context) {
    if (isMobile(context)) return double.infinity;
    return 1200;
  }

  // Button padding
  static EdgeInsets getResponsiveButtonPadding(BuildContext context) {
    final horizontal = getResponsiveHorizontalSpacing(context);
    if (isMobile(context)) {
      return EdgeInsets.symmetric(horizontal: horizontal, vertical: 10);
    }
    return EdgeInsets.symmetric(horizontal: horizontal, vertical: 12);
  }

  // Safe area padding for mobile
  static EdgeInsets getResponsiveSafeAreaPadding(BuildContext context) {
    if (isMobile(context)) {
      final mediaQuery = MediaQuery.of(context);
      return EdgeInsets.only(
        top: mediaQuery.padding.top,
        bottom: mediaQuery.padding.bottom,
      );
    }
    return EdgeInsets.zero;
  }
}

/// Desktop-compatible constants class for backward compatibility
/// Now uses ResponsiveUtils internally but provides static desktop values
class DesktopConstants {
  // Fixed spacing values optimized for desktop
  static const double padding = 24;
  static const double cardPadding = 20;
  static const double verticalSpacing = 16;
  static const double horizontalSpacing = 16;

  // Button dimensions
  static const double buttonHeight = 48;
  static const double iconButtonSize = 40;

  // Card dimensions
  static const double cardHeight = 120;
  static const double cardMinWidth = 200;

  // Icon sizes
  static const double smallIconSize = 16;
  static const double mediumIconSize = 20;
  static const double largeIconSize = 24;
  static const double extraLargeIconSize = 32;

  // Font sizes
  static const double smallFontSize = 12;
  static const double bodyFontSize = 14;
  static const double titleFontSize = 16;
  static const double headerFontSize = 20;
  static const double largeHeaderFontSize = 24;
  static const double extraLargeHeaderFontSize = 28;

  // Layout
  static const double sidebarWidth = 250;
  static const double maxContentWidth = 1200;

  // Grid
  static const int gridColumns = 4;
  static const double gridSpacing = 16;

  // Content padding for main areas
  static EdgeInsets get contentPadding => const EdgeInsets.all(padding);

  // Card padding
  static EdgeInsets get cardPaddingInsets => const EdgeInsets.all(cardPadding);

  // Button padding
  static EdgeInsets get buttonPadding => const EdgeInsets.symmetric(
        horizontal: horizontalSpacing,
        vertical: 12,
      );

  // Spacing helpers
  static Widget get verticalSpace => const SizedBox(height: verticalSpacing);
  static Widget get horizontalSpace => const SizedBox(width: horizontalSpacing);

  static Widget verticalSpaceCustom(double height) => SizedBox(height: height);
  static Widget horizontalSpaceCustom(double width) => SizedBox(width: width);

  // Responsive methods that delegate to ResponsiveUtils
  static EdgeInsets getResponsiveContentPadding(BuildContext context) =>
      ResponsiveUtils.getResponsiveContentPadding(context);

  static double getResponsivePadding(BuildContext context) =>
      ResponsiveUtils.getResponsivePadding(context);

  static double getResponsiveButtonHeight(BuildContext context) =>
      ResponsiveUtils.getResponsiveButtonHeight(context);

  static EdgeInsets getResponsiveButtonPadding(BuildContext context) =>
      ResponsiveUtils.getResponsiveButtonPadding(context);
}

import 'package:flutter/material.dart';

/// Desktop-only layout constants
/// Simplified from responsive design to focus on desktop experience
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
}

/// Legacy responsive utils class for backward compatibility
/// All methods now return desktop-optimized values
@Deprecated('Use DesktopConstants instead')
class ResponsiveUtils {
  static bool isMobile(BuildContext context) => false;
  static bool isTablet(BuildContext context) => false;
  static bool isDesktop(BuildContext context) => true;
  static bool isVerySmallScreen(BuildContext context) => false;

  static double getResponsivePadding(BuildContext context) =>
      DesktopConstants.padding;
  static double getResponsiveCardPadding(BuildContext context) =>
      DesktopConstants.cardPadding;
  static double getResponsiveVerticalSpacing(BuildContext context) =>
      DesktopConstants.verticalSpacing;
  static double getResponsiveHorizontalSpacing(BuildContext context) =>
      DesktopConstants.horizontalSpacing;
  static double getResponsiveButtonHeight(BuildContext context) =>
      DesktopConstants.buttonHeight;
  static double getResponsiveCardHeight(
          BuildContext context, double baseHeight,) =>
      DesktopConstants.cardHeight;
  static double getResponsiveIconSize(BuildContext context, double baseSize) =>
      baseSize;
  static double getResponsiveFontSize(
          BuildContext context, double baseFontSize,) =>
      baseFontSize;

  static EdgeInsets getResponsiveContentPadding(BuildContext context) =>
      DesktopConstants.contentPadding;

  static int getResponsiveGridColumns(BuildContext context,
          {int maxColumns = 4,}) =>
      DesktopConstants.gridColumns;
}

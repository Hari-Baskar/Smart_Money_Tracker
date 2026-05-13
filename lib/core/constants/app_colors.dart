import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  // Primary Colors (Green)
  static const Color primary = Color(0xFF006A34);
  static const Color primaryContainer = Color(0xFF078644);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFFF6FFF3);

  // Light Theme Colors
  static const Color backgroundLight = Color(0xFFFAF9FE);
  static const Color surfaceLight = Color(0xFFFAF9FE);
  static const Color surfaceContainerLowestLight = Color(0xFFFFFFFF);
  static const Color surfaceContainerLight = Color(0xFFEEEDF3);
  static const Color textLight = Color(0xFF1A1B1F);
  static const Color textMutedLight = Color(0xFF3E4A3F);

  // Dark Theme Colors
  static const Color backgroundDark = Color(0xFF0F110F);
  static const Color surfaceDark = Color(0xFF141614);
  static const Color surfaceContainerLowestDark = Color(0xFF1C1E1C);
  static const Color surfaceContainerDark = Color(0xFF252725);
  static const Color textDark = Color(0xFFE1E3E1);
  static const Color textMutedDark = Color(0xFFAEB2AE);
  
  // Legacy accessors (keep for compatibility but mark as light-default)
  static const Color background = backgroundLight;
  static const Color surface = surfaceLight;
  static const Color surfaceContainerLowest = surfaceContainerLowestLight;
  static const Color surfaceContainer = surfaceContainerLight;
  static const Color text = textLight;
  static const Color textMuted = textMutedLight;
  
  // Functional Colors
  static const Color success = Color(0xFF006A34);
  static const Color error = Color(0xFFBA1A1A);
  static const Color warning = Color(0xFFF59E0B);

  // Category Colors
  static const Color foodBg = Color(0xFFFFEDD5);
  static const Color foodIcon = Color(0xFFEA580C);
  static const Color shoppingBg = Color(0xFFDBEAFE);
  static const Color shoppingIcon = Color(0xFF2563EB);
  static const Color travelBg = Color(0xFFD1FAE5);
  static const Color travelIcon = Color(0xFF059669);
  
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryContainer],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Adaptive Helpers
  static bool isDark(BuildContext context) => Theme.of(context).brightness == Brightness.dark;

  static Color getBackground(BuildContext context) => 
      isDark(context) ? backgroundDark : backgroundLight;

  static Color getSurface(BuildContext context) => 
      isDark(context) ? surfaceDark : surfaceLight;

  static Color getSurfaceContainerLowest(BuildContext context) => 
      isDark(context) ? surfaceContainerLowestDark : surfaceContainerLowestLight;

  static Color getSurfaceContainer(BuildContext context) => 
      isDark(context) ? surfaceContainerDark : surfaceContainerLight;

  static Color getText(BuildContext context) => 
      isDark(context) ? textDark : textLight;

  static Color getTextMuted(BuildContext context) => 
      isDark(context) ? textMutedDark : textMutedLight;
}


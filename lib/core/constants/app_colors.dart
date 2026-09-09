import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  // Primary Colors (Green)
  static const Color primary = Color(0xFF006A34);
  static const Color primaryContainer = Color(0xFF078644);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFFF6FFF3);
  static const Color transparent = Color(0x00000000);

  // Base Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  // Light Theme Colors
  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceContainerLowestLight = Color(0xFFFFFFFF);
  static const Color surfaceContainerLight = Color(0xFFF5F5F5);
  static const Color textLight = Color(0xFF1A1B1F);
  static const Color textMutedLight = Color(0xFF3E4A3F);

  // Dark Theme Colors
  static const Color backgroundDark = Color(
    0xFF1E1E1E,
  ); // Reduced black background
  static const Color surfaceDark = Color(
    0xFF2E2E2E,
  ); // 10% lighter surface grey for cards
  static const Color surfaceContainerLowestDark = Color(
    0xFF343434,
  ); // For deep nested areas
  static const Color surfaceContainerDark = Color(
    0xFF3C3C3C,
  ); // For raised elements/borders
  static const Color textDark = Color(
    0xFFA8A8A8, // High contrast white for main text
  );
  static const Color textMutedDark = Color(
    0xFFA8A8A8, // Instagram's muted grey text
  );

  // Legacy accessors (keep for compatibility but mark as light-default)
  static const Color background = backgroundLight;
  static const Color surface = surfaceLight;
  static const Color surfaceContainerLowest = surfaceContainerLowestLight;
  static const Color surfaceContainer = surfaceContainerLight;
  static const Color text = textLight;
  static const Color textMuted = textMutedLight;

  // Functional Colors
  static const Color success = Color(0xFF34A853);
  static const Color error = Color(0xFFB42318);
  static const Color warning = Color(0xFFF59E0B);
  static const Color red = Color(0xFFEF4444);
  static const Color green = Color(0xFF10B981);
  static const Color blue = Color(0xFF3B82F6);
  static const Color indigo = Color(0xFF3730A3); // Deep Indigo
  static const Color pink = Color(0xFFE91E63);

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

  static const List<Color> analysisPalette = [
    Color(0xFF64B5F6),
    Color(0xFF81C784),
    Color(0xFFFFB74D),
    Color(0xFFBA68C8),
    Color(0xFFE57373),
    Color(0xFF4DB6AC),
    Color(0xFF7986CB),
    Color(0xFFFFD54F),
    Color(0xFFA1887F),
    Color(0xFF90A4AE),
  ];

  // Adaptive Helpers
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color getBackground(BuildContext context) =>
      isDark(context) ? backgroundDark : backgroundLight;

  static Color getSurface(BuildContext context) =>
      isDark(context) ? surfaceDark : surfaceLight;

  static Color getSurfaceContainerLowest(BuildContext context) =>
      isDark(context)
      ? Theme.of(context).colorScheme.surface
      : surfaceContainerLowestLight;

  static Color getSurfaceContainer(BuildContext context) =>
      isDark(context) ? surfaceContainerDark : surfaceContainerLight;

  static Color getDateContainerColor(BuildContext context) =>
      isDark(context)
          ? getSurfaceContainerLowest(context)
          : const Color(0xFFF7F7F7);

  static Color getText(BuildContext context) =>
      isDark(context) ? textDark : textLight;

  static Color getTextMuted(BuildContext context) =>
      isDark(context) ? textMutedDark : textMutedLight;

  static IconData getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant_rounded;
      case 'travel':
        return Icons.directions_car_rounded;
      case 'shopping':
        return Icons.shopping_bag_rounded;
      case 'bills':
        return Icons.receipt_long_rounded;
      case 'groceries':
        return Icons.local_grocery_store_rounded;
      case 'entertainment':
        return Icons.movie_rounded;
      case 'health':
        return Icons.medical_services_rounded;
      case 'investment':
        return Icons.trending_up_rounded;
      case 'salary':
        return Icons.payments_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  static Color getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return foodIcon;
      case 'travel':
        return travelIcon;
      case 'shopping':
        return shoppingIcon;
      case 'bills':
        return const Color(0xFFEF4444);
      case 'groceries':
        return const Color(0xFFD97706);
      case 'entertainment':
        return const Color(0xFFEC4899);
      case 'health':
        return const Color(0xFF0D9488);
      case 'investment':
        return const Color(0xFF0284C7);
      case 'salary':
        return const Color(0xFF10B981);
      case 'other':
      case 'unknown':
        return primary;
      default:
        return warning;
    }
  }

  static Color getCategoryBgColor(BuildContext context, String category) {
    final isDark = AppColors.isDark(context);
    final catColor = getCategoryColor(category);
    if (isDark) {
      return catColor.withValues(alpha: 0.15);
    }
    switch (category.toLowerCase()) {
      case 'food':
        return foodBg;
      case 'travel':
        return travelBg;
      case 'shopping':
        return shoppingBg;
      case 'bills':
        return const Color(0xFFFEE2E2);
      case 'groceries':
        return const Color(0xFFFEF3C7);
      case 'entertainment':
        return const Color(0xFFFCE7F3);
      case 'health':
        return const Color(0xFFCCFBF1);
      case 'investment':
        return const Color(0xFFE0F2FE);
      case 'salary':
        return const Color(0xFFD1FAE5);
      case 'other':
      case 'unknown':
        return primary.withValues(alpha: 0.1);
      default:
        return warning.withValues(alpha: 0.15);
    }
  }

  static String formatShortAmount(double amount) {
    if (amount.isNaN || amount.isInfinite) return amount.toString();
    final isNegative = amount < 0;
    final absAmount = amount.abs();

    if (absAmount < 1000) {
      return isNegative
          ? '-${_formatCompactLessThan1000(absAmount)}'
          : _formatCompactLessThan1000(absAmount);
    }

    final suffixes = [
      '',
      'K',
      'M',
      'B',
      'T',
      'Qa',
      'Qi',
      'Sx',
      'Sp',
      'Oc',
      'No',
      'Dc',
    ];
    int exp = 0;
    double value = absAmount;
    while (value >= 1000 && exp < suffixes.length - 1) {
      value /= 1000;
      exp++;
    }

    String formattedValue;
    if (value >= 100) {
      formattedValue = value.toStringAsFixed(0);
    } else if (value >= 10) {
      formattedValue = _formatWithMaxDecimals(value, 1);
    } else {
      formattedValue = _formatWithMaxDecimals(value, 2);
    }

    final suffix = suffixes[exp];
    final formatted = '$formattedValue$suffix';

    return isNegative ? '-$formatted' : formatted;
  }

  static String _formatCompactLessThan1000(double value) {
    return _formatWithMaxDecimals(value, 2);
  }

  static String _formatWithMaxDecimals(double value, int maxDecimals) {
    String result = value.toStringAsFixed(maxDecimals);
    if (result.contains('.')) {
      while (result.endsWith('0')) {
        result = result.substring(0, result.length - 1);
      }
      if (result.endsWith('.')) {
        result = result.substring(0, result.length - 1);
      }
    }
    return result;
  }
}

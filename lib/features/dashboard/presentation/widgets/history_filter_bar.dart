import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:smart_money_tracker/core/constants/app_colors.dart';
import 'package:smart_money_tracker/core/constants/app_sizes.dart';
import 'package:smart_money_tracker/core/theme/app_text_styles.dart';
import 'category_picker_sheet.dart';
import 'subcategory_picker_sheet.dart';

class HistoryFilterBar extends ConsumerWidget {
  final ValueNotifier<DateTimeRange> dateRange;
  final Future<void> Function() selectDateRange;
  final ValueNotifier<String> selectedCategory;
  final ValueNotifier<String> selectedSubcategory;
  final AsyncValue<List<dynamic>> subcategoriesAsync;
  final List<String> categoriesList;

  const HistoryFilterBar({
    super.key,
    required this.dateRange,
    required this.selectDateRange,
    required this.selectedCategory,
    required this.selectedSubcategory,
    required this.subcategoriesAsync,
    required this.categoriesList,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCategoryActive = selectedCategory.value != 'All';
    final isSubcategoryActive = selectedSubcategory.value != 'All';
    final hasActiveFilters = isCategoryActive || isSubcategoryActive;

    String subcategoryLabel = 'Subcategory';
    if (isSubcategoryActive) {
      subcategoryLabel = selectedSubcategory.value;
      if (subcategoriesAsync.hasValue) {
        final allSubs = subcategoriesAsync.value!;
        final match = allSubs
            .where((s) => s.id == selectedSubcategory.value)
            .firstOrNull;
        if (match != null) {
          subcategoryLabel = match.name;
        }
      }
    }

    return Container(
      padding: EdgeInsets.symmetric(vertical: AppSizes.h12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: AppSizes.w(20)),
        child: Row(
          children: [
            // Date Filter Chip
            _buildFilterChip(
              context: context,
              label:
                  '${DateFormat('MMM dd').format(dateRange.value.start)} - ${DateFormat('MMM dd').format(dateRange.value.end)}',
              icon: Icons.calendar_today_rounded,
              isActive: true,
              activeBgColor: Theme.of(context).colorScheme.surface,
              activeColor: AppColors.primary,
              onTap: selectDateRange,
            ),
            SizedBox(width: AppSizes.w12),

            // Category Filter Chip
            _buildFilterChip(
              context: context,
              label: selectedCategory.value == 'All'
                  ? 'Category'
                  : selectedCategory.value,
              icon: AppColors.getCategoryIcon(selectedCategory.value),
              isActive: isCategoryActive,
              activeBgColor: AppColors.getCategoryBgColor(
                context,
                selectedCategory.value,
              ),
              activeColor: AppColors.getCategoryColor(selectedCategory.value),
              onTap: () => _showCategoryBottomSheet(context),
            ),
            SizedBox(width: AppSizes.w12),

            // Subcategory Filter Chip
            _buildFilterChip(
              context: context,
              label: subcategoryLabel,
              icon: Icons.layers_rounded,
              isActive: isSubcategoryActive,
              isDisabled: !isCategoryActive,
              activeBgColor: AppColors.getCategoryBgColor(
                context,
                selectedCategory.value,
              ),
              activeColor: AppColors.getCategoryColor(selectedCategory.value),
              onTap: () => _showSubcategoryBottomSheet(context),
            ),

            // Reset Active Filters Chip
            if (hasActiveFilters) ...[
              SizedBox(width: AppSizes.w12),
              _buildResetChip(
                context: context,
                onTap: () {
                  selectedCategory.value = 'All';
                  selectedSubcategory.value = 'All';
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required BuildContext context,
    required String label,
    required IconData icon,
    bool isActive = false,
    bool isDisabled = false,
    Color? activeColor,
    Color? activeBgColor,
    VoidCallback? onTap,
  }) {
    final isDark = AppColors.isDark(context);

    final baseBgColor = isDark
        ? AppColors.surfaceContainerLowestDark
        : AppColors.white;
    final baseBorderColor = isDark
        ? AppColors.white.withOpacity(0.08)
        : AppColors.black.withOpacity(0.06);
    final baseTextColor = AppColors.getText(context);
    final baseIconColor = AppColors.getTextMuted(context);

    final bg = isDisabled
        ? baseBgColor.withOpacity(0.5)
        : (isActive
              ? (activeBgColor ?? AppColors.primary.withOpacity(0.12))
              : baseBgColor);

    final border = Border.all(
      color: isDisabled
          ? baseBorderColor.withOpacity(0.5)
          : (isActive
                ? (activeColor ?? AppColors.primary).withOpacity(0.3)
                : baseBorderColor),
      width: isActive ? 1.5 : 1.0,
    );

    final textStyle = AppTextStyles.small(
      context,
      color: isDisabled
          ? baseTextColor.withOpacity(0.4)
          : (isActive ? (activeColor ?? AppColors.primary) : baseTextColor),
    );

    final iconColor = isDisabled
        ? baseIconColor.withOpacity(0.4)
        : (isActive ? (activeColor ?? AppColors.primary) : baseIconColor);

    return Opacity(
      opacity: isDisabled ? 0.5 : 1.0,
      child: GestureDetector(
        onTap: isDisabled ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
            horizontal: AppSizes.w16,
            vertical: AppSizes.h(10),
          ),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppSizes.r24),
            border: border,
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: (activeColor ?? AppColors.primary).withOpacity(
                        0.06,
                      ),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: AppColors.black.withOpacity(0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: AppSizes.r16, color: iconColor),
              SizedBox(width: AppSizes.w8),
              Text(label, style: textStyle),
              SizedBox(width: AppSizes.w4),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: AppSizes.r16,
                color: iconColor.withOpacity(0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResetChip({
    required BuildContext context,
    required VoidCallback onTap,
  }) {
    final isDark = AppColors.isDark(context);
    final bg = isDark
        ? AppColors.error.withOpacity(0.1)
        : const Color(0xFFFEE2E2);
    final border = Border.all(color: AppColors.error.withOpacity(0.2));
    final textColor = AppColors.error;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSizes.w12,
          vertical: AppSizes.h(10),
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppSizes.r24),
          border: border,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.restart_alt_rounded,
              size: AppSizes.r16,
              color: textColor,
            ),
            SizedBox(width: AppSizes.w8),
            Text(
              'Reset',
              style: AppTextStyles.small(context, color: textColor),
            ),
            SizedBox(width: AppSizes.w8),
          ],
        ),
      ),
    );
  }

  void _showCategoryBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.transparent,
      isScrollControlled: true,
      builder: (context) => CategoryPickerSheet(
        selectedCategory: selectedCategory,
        customSubcategories: subcategoriesAsync.value ?? const [],
        categoriesList: categoriesList,
      ),
    );
  }

  void _showSubcategoryBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.transparent,
      isScrollControlled: true,
      builder: (context) => SubcategoryPickerSheet(
        activeCategory: selectedCategory.value,
        selectedSubcategory: selectedSubcategory,
        subcategoriesAsync: subcategoriesAsync,
      ),
    );
  }
}

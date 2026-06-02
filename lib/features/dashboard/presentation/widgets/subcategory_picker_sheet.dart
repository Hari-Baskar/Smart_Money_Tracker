import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:smart_money_tracker/core/constants/app_colors.dart';
import 'package:smart_money_tracker/core/constants/app_sizes.dart';
import 'package:smart_money_tracker/core/theme/app_text_styles.dart';

class SubcategoryPickerSheet extends ConsumerWidget {
  final String activeCategory;
  final ValueNotifier<String> selectedSubcategory;
  final AsyncValue<List<dynamic>> subcategoriesAsync;

  const SubcategoryPickerSheet({
    super.key,
    required this.activeCategory,
    required this.selectedSubcategory,
    required this.subcategoriesAsync,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = AppColors.isDark(context);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.r24)),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSizes.w24,
        AppSizes.h12,
        AppSizes.w24,
        AppSizes.h24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: AppSizes.w(48),
              height: AppSizes.h4,
              margin: EdgeInsets.only(bottom: AppSizes.h20),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.white.withOpacity(0.12)
                    : AppColors.black.withOpacity(0.08),
                borderRadius: BorderRadius.circular(AppSizes.r(2)),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Select Subcategory',
                style: AppTextStyles.headline(
                  context,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (selectedSubcategory.value != 'All')
                TextButton(
                  onPressed: () {
                    selectedSubcategory.value = 'All';
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Clear',
                    style: AppTextStyles.body(
                      context,
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: AppSizes.h16),
          Flexible(
            child: subcategoriesAsync.when(
              data: (allSubcategories) {
                final filtered = allSubcategories
                    .where((s) => s.parentCategory == activeCategory)
                    .map((s) => s.name as String)
                    .toSet()
                    .toList();

                final sortedSub = filtered..sort();
                final displaySub = ['All', ...sortedSub];

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: displaySub.length,
                  separatorBuilder: (context, index) => Divider(
                    color: isDark
                        ? AppColors.white.withOpacity(0.05)
                        : AppColors.black.withOpacity(0.04),
                    height: 1,
                  ),
                  itemBuilder: (context, index) {
                    final sub = displaySub[index];
                    final isSelected = selectedSubcategory.value == sub;
                    final activeCatColor = AppColors.getCategoryColor(
                      activeCategory,
                    );

                    return ListTile(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: AppSizes.w8,
                        vertical: AppSizes.h4,
                      ),
                      onTap: () {
                        selectedSubcategory.value = sub;
                        Navigator.pop(context);
                      },
                      leading: Container(
                        width: AppSizes.r(36),
                        height: AppSizes.r(36),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? activeCatColor.withOpacity(0.1)
                              : (isDark
                                    ? AppColors.surfaceContainerLowestDark
                                    : AppColors.backgroundLight),
                          borderRadius: BorderRadius.circular(AppSizes.r(10)),
                        ),
                        child: Icon(
                          isSelected
                              ? Icons.check_circle_rounded
                              : Icons.circle_outlined,
                          color: isSelected
                              ? activeCatColor
                              : AppColors.getTextMuted(
                                  context,
                                ).withOpacity(0.5),
                          size: AppSizes.r16,
                        ),
                      ),
                      title: Text(
                        sub,
                        style: AppTextStyles.body(
                          context,
                          color: isSelected
                              ? activeCatColor
                              : AppColors.getText(context),
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(
                              Icons.check_rounded,
                              color: activeCatColor,
                              size: AppSizes.r20,
                            )
                          : null,
                    );
                  },
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (_, __) => Center(
                child: Text(
                  'Failed to load subcategories',
                  style: AppTextStyles.body(context),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

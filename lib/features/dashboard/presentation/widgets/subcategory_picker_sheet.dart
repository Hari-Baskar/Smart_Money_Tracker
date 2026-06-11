import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:smart_money_tracker/core/models/transaction_model.dart';
import 'package:smart_money_tracker/core/constants/app_colors.dart';
import 'package:smart_money_tracker/core/constants/app_sizes.dart';
import 'package:smart_money_tracker/core/theme/app_text_styles.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/providers/subcategory_provider.dart';

class SubcategoryPickerSheet extends ConsumerWidget {
  final String activeCategory;
  final ValueNotifier<String> selectedSubcategory;
  final AsyncValue<List<dynamic>> subcategoriesAsync;
  final TransactionType? transactionType;

  const SubcategoryPickerSheet({
    super.key,
    required this.activeCategory,
    required this.selectedSubcategory,
    required this.subcategoriesAsync,
    this.transactionType,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = AppColors.isDark(context);
    final categoriesAsync = ref.watch(categoriesProvider);
    final categories = categoriesAsync.value ?? const [];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.white,
        borderRadius: AppSizes.boxBorderRadius,
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
                borderRadius: AppSizes.boxBorderRadius,
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Select Subcategory', style: AppTextStyles.heading(context)),
              if (selectedSubcategory.value != 'All')
                TextButton(
                  onPressed: () {
                    selectedSubcategory.value = 'All';
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Clear',
                    style: AppTextStyles.body(context, color: AppColors.error),
                  ),
                ),
            ],
          ),
          SizedBox(height: AppSizes.h16),
          Flexible(
            child: subcategoriesAsync.when(
              data: (allSubcategories) {
                final filtered = allSubcategories
                    .where((s) => s.parentCategoryId == activeCategory && !s.isArchived)
                    .where((s) {
                      if (transactionType != null) {
                        final isIncome =
                            transactionType == TransactionType.credit;
                        return s.isIncome == isIncome;
                      }
                      return true;
                    })
                    .toList();

                final sortedSub = filtered..sort((a, b) => a.name.compareTo(b.name));
                final displaySub = [
                  SubcategoryModel(id: 'All', name: 'All', parentCategoryId: activeCategory),
                  ...sortedSub
                ];

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
                    final isSelected = selectedSubcategory.value == sub.id;

                    String activeCategoryName = activeCategory;
                    final match = categories.where((c) => c.id == activeCategory).firstOrNull;
                    if (match != null) activeCategoryName = match.name;

                    final activeCatColor = AppColors.getCategoryColor(
                      activeCategoryName,
                    );

                    return ListTile(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: AppSizes.w8,
                        vertical: AppSizes.h4,
                      ),
                      onTap: () {
                        selectedSubcategory.value = sub.id;
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
                          borderRadius: AppSizes.boxBorderRadius,
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
                        sub.name,
                        style: AppTextStyles.body(
                          context,
                          color: isSelected
                              ? activeCatColor
                              : AppColors.getText(context),
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
              loading: () => const Center(child: CircularProgressIndicator()),
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

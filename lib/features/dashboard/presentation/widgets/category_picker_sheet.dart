import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:smart_money_tracker/core/constants/app_colors.dart';
import 'package:smart_money_tracker/core/constants/app_sizes.dart';
import 'package:smart_money_tracker/core/theme/app_text_styles.dart';

class CategoryPickerSheet extends StatelessWidget {
  final ValueNotifier<String> selectedCategory;
  final List<dynamic> customSubcategories;
  final List<String> categoriesList;

  const CategoryPickerSheet({
    super.key,
    required this.selectedCategory,
    required this.customSubcategories,
    required this.categoriesList,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final customCats = customSubcategories.map((s) => s.parentCategory as String).toSet().toList();
    final allCats = [
      ...categoriesList,
      ...customCats.where((c) => !const [
        'Food', 'Travel', 'Shopping', 'Bills', 'Groceries', 'Entertainment', 'Health', 'Investment', 'Salary', 'Other', 'Unknown', 'All'
      ].contains(c))
    ].toList();

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
                'Select Category',
                style: AppTextStyles.headline(
                  context,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (selectedCategory.value != 'All')
                TextButton(
                  onPressed: () {
                    selectedCategory.value = 'All';
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
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: AppSizes.w12,
                mainAxisSpacing: AppSizes.h12,
                childAspectRatio: 0.95,
              ),
              itemCount: allCats.length,
              itemBuilder: (context, index) {
                final cat = allCats[index];
                final isSelected = selectedCategory.value == cat;
                final catColor = AppColors.getCategoryColor(cat);
                final catBg = AppColors.getCategoryBgColor(context, cat);

                return GestureDetector(
                  onTap: () {
                    selectedCategory.value = cat;
                    Navigator.pop(context);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? catBg
                          : (isDark
                                ? AppColors.surfaceContainerLowestDark
                                : AppColors.backgroundLight),
                      borderRadius: BorderRadius.circular(AppSizes.r16),
                      border: Border.all(
                        color: isSelected
                            ? catColor
                            : (isDark
                                  ? AppColors.white.withOpacity(0.05)
                                  : AppColors.black.withOpacity(0.04)),
                        width: isSelected ? 2.0 : 1.0,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: catColor.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : [],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: AppSizes.r(44),
                          height: AppSizes.r(44),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (isDark
                                      ? AppColors.black.withOpacity(0.2)
                                      : AppColors.white)
                                : catBg,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            AppColors.getCategoryIcon(cat),
                            color: catColor,
                            size: AppSizes.r24,
                          ),
                        ),
                        SizedBox(height: AppSizes.h8),
                        Text(
                          cat,
                          style: AppTextStyles.small(
                            context,
                            color: isSelected
                                ? (isDark ? AppColors.white : catColor)
                                : AppColors.getText(context),
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

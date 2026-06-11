import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:smart_money_tracker/core/constants/app_colors.dart';
import 'package:smart_money_tracker/core/constants/app_sizes.dart';
import 'package:smart_money_tracker/core/theme/app_text_styles.dart';
import '../providers/subcategory_provider.dart';

class CategoryPickerSheet extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = AppColors.isDark(context);
    final categoriesAsync = ref.watch(categoriesProvider);
    final categories = categoriesAsync.value ?? const [];

    final customCats = categories
        .where((c) => c.isCustom && !c.isArchived)
        .map((c) => c.id)
        .toList();

    final allCats = [
      ...categoriesList,
      ...customCats,
    ].toSet().toList();

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
              Text('Select Category', style: AppTextStyles.heading(context)),
              if (selectedCategory.value != 'All')
                TextButton(
                  onPressed: () {
                    selectedCategory.value = 'All';
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
                final catId = allCats[index];
                final isSelected = selectedCategory.value == catId;
                
                String catName = catId;
                final match = categories.where((c) => c.id == catId).firstOrNull;
                if (match != null) catName = match.name;

                final catColor = AppColors.getCategoryColor(catName);
                final catBg = AppColors.getCategoryBgColor(context, catName);

                return GestureDetector(
                  onTap: () {
                    selectedCategory.value = catId;
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
                      borderRadius: AppSizes.boxBorderRadius,
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
                            AppColors.getCategoryIcon(catName),
                            color: catColor,
                            size: AppSizes.r24,
                          ),
                        ),
                        SizedBox(height: AppSizes.h8),
                        Text(
                          catName,
                          style: AppTextStyles.small(
                            context,
                            color: isSelected
                                ? (isDark ? AppColors.white : catColor)
                                : AppColors.getText(context),
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

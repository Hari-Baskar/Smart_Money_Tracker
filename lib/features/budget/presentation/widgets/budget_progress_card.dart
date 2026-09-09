import 'package:flutter/material.dart';
import 'package:smart_money_tracker/core/constants/app_colors.dart';
import 'package:smart_money_tracker/core/constants/app_sizes.dart';
import 'package:smart_money_tracker/core/models/budget_model.dart';
import 'package:smart_money_tracker/features/budget/domain/providers/budget_providers.dart';
import 'package:smart_money_tracker/core/theme/app_text_styles.dart';
import 'package:intl/intl.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:smart_money_tracker/core/models/transaction_model.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/providers/subcategory_provider.dart';
import 'package:smart_money_tracker/core/common/widgets/category_icon_widget.dart';

class BudgetProgressCard extends ConsumerWidget {
  final BudgetProgress progress;
  final VoidCallback? onTap;
  const BudgetProgressCard({super.key, required this.progress, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final categories = categoriesAsync.value ?? [];

    CategoryModel? categoryModel;
    if (progress.budget.categoryId != null) {
      try {
        categoryModel = categories.firstWhere(
          (c) =>
              c.id == progress.budget.categoryId ||
              c.name.toLowerCase() == progress.budget.categoryId!.toLowerCase(),
        );
      } catch (_) {}
    }

    String? resolvedSubName;
    if (progress.budget.subcategoryId != null) {
      final subcategoriesAsync = ref.watch(subcategoriesProvider);
      final subcategories = subcategoriesAsync.value ?? [];
      try {
        final subModel = subcategories.firstWhere(
          (s) => s.id == progress.budget.subcategoryId,
        );
        resolvedSubName = subModel.name;
      } catch (_) {
        resolvedSubName = progress.budget.subcategoryId;
      }
    }

    final resolvedCategoryName =
        categoryModel?.name ?? progress.budget.categoryId;
    final formattedCategory = resolvedCategoryName != null
        ? '${resolvedCategoryName[0].toUpperCase()}${resolvedCategoryName.substring(1)}'
        : 'Overall Budget';

    final hasCustomName =
        progress.budget.name.isNotEmpty &&
        progress.budget.name != 'Budget' &&
        progress.budget.name != 'Category Budget' &&
        progress.budget.name != 'Overall Budget' &&
        !progress.budget.name.endsWith(' Budget');

    final String displayTitle;
    if (hasCustomName) {
      displayTitle = progress.budget.name;
    } else if (resolvedSubName != null && resolvedSubName.isNotEmpty) {
      displayTitle = resolvedSubName;
    } else {
      displayTitle = formattedCategory;
    }

    final formatCurrency = NumberFormat.compactCurrency(
      locale: 'en_US',
      symbol: '₹',
      decimalDigits: 0,
    );

    final categoryColor = progress.budget.categoryId != null
        ? AppColors.getCategoryColor(progress.budget.categoryId!)
        : AppColors.warning;

    final now = DateTime.now();
    final isYearly = progress.budget.period == BudgetPeriod.yearly;
    final isCustomNonCurrentMonth =
        progress.budget.period == BudgetPeriod.custom &&
        progress.periodStart != null &&
        (progress.periodStart!.year != now.year ||
            progress.periodStart!.month != now.month);
    final showTotalAndDetails = isYearly || isCustomNonCurrentMonth;

    return InkWell(
      borderRadius: AppSizes.cardBorderRadius,
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.zero,
        padding: EdgeInsets.all(AppSizes.r16),
        decoration: BoxDecoration(
          color: AppColors.getSurfaceContainerLowest(context),
          borderRadius: AppSizes.cardBorderRadius,
          border: AppColors.isDark(context)
              ? null
              : Border.all(
                  color: AppColors.getBorder(context),
                  width: 1,
                ),
          boxShadow: AppColors.isDark(context)
              ? null
              : [
                  BoxShadow(
                    color: AppColors.black.withValues(alpha: 0.03),
                    blurRadius: 16,
                    spreadRadius: 0,
                    offset: Offset.zero,
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: AppSizes.r40,
                  height: AppSizes.r40,
                  decoration: BoxDecoration(
                    color: categoryColor,
                    shape: BoxShape.circle,
                  ),
                  child: progress.budget.categoryId == null
                      ? Icon(
                          Icons.pie_chart_rounded,
                          color: AppColors.white,
                          size: AppSizes.r24,
                        )
                      : CategoryIconWidget(
                          categoryName: resolvedCategoryName!,
                          emoji: categoryModel?.emoji,
                          color: AppColors.white,
                          size: AppSizes.r24,
                        ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (progress.budget.isStopped) ...[
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSizes.w6,
                          vertical: AppSizes.h2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(AppSizes.r8),
                        ),
                        child: Text(
                          'Stopped',
                          style: AppTextStyles.small(context).copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ] else if (progress.isCompleted) ...[
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSizes.w6,
                          vertical: AppSizes.h2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          borderRadius: BorderRadius.circular(AppSizes.r8),
                        ),
                        child: Text(
                          'Completed',
                          style: AppTextStyles.small(context).copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ] else if (progress.isUpcoming) ...[
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSizes.w6,
                          vertical: AppSizes.h2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.getTextMuted(
                            context,
                          ).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(AppSizes.r8),
                        ),
                        child: Text(
                          'Upcoming',
                          style: AppTextStyles.small(context).copyWith(
                            color: AppColors.getText(context),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ] else ...[
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSizes.w6,
                          vertical: AppSizes.h2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.getTextMuted(
                            context,
                          ).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(AppSizes.r8),
                        ),
                        child: Text(
                          progress.budget.period.name[0].toUpperCase() +
                              progress.budget.period.name.substring(1),
                          style: AppTextStyles.small(context).copyWith(
                            color: AppColors.getText(context),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            SizedBox(height: AppSizes.h8),
            Text(
              displayTitle,
              style: AppTextStyles.body(
                context,
                color: AppColors.getText(context),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (progress.isUpcoming) ...[
              SizedBox(height: AppSizes.h4),
              Text(
                formatCurrency.format(progress.limitAmount),
                style: AppTextStyles.subHeading(
                  context,
                  fontWeight: FontWeight.bold,
                  color: AppColors.getText(context),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: AppSizes.h4),
              Text(
                'Yet to start',
                style: AppTextStyles.body(
                  context,
                  color: AppColors.getTextMuted(context),
                ).copyWith(fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ] else if (showTotalAndDetails) ...[
              SizedBox(height: AppSizes.h4),
              Text(
                formatCurrency.format(progress.limitAmount),
                style: AppTextStyles.subHeading(
                  context,
                  fontWeight: FontWeight.bold,
                  color: AppColors.getText(context),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: AppSizes.h4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'View details',
                    style: AppTextStyles.body(
                      context,
                      color: AppColors.getTextMuted(context),
                    ).copyWith(fontWeight: FontWeight.w600),
                  ),
                  SizedBox(width: AppSizes.w4),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: AppSizes.r12,
                    color: AppColors.getTextMuted(context),
                  ),
                ],
              ),
            ] else ...[
              SizedBox(height: AppSizes.h4),
              Text(
                '${formatCurrency.format(progress.spent)} / ${formatCurrency.format(progress.limitAmount)}',
                style: AppTextStyles.subHeading(
                  context,
                  fontWeight: FontWeight.bold,
                  color: AppColors.getTextMuted(context),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: AppSizes.h4),
              Text(
                '${(progress.percentage * 100).toStringAsFixed(0)}% used',
                style: AppTextStyles.body(
                  context,
                  color: progress.percentage >= 1.0
                      ? AppColors.error
                      : progress.percentage >= 0.8
                      ? AppColors.warning
                      : AppColors.success,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

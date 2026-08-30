import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:smart_money_tracker/core/constants/app_colors.dart';
import 'package:smart_money_tracker/core/constants/app_sizes.dart';
import 'package:smart_money_tracker/features/budget/domain/providers/budget_providers.dart';
import 'package:smart_money_tracker/core/theme/app_text_styles.dart';
import 'package:intl/intl.dart';
import 'package:smart_money_tracker/core/models/budget_model.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:smart_money_tracker/core/models/transaction_model.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/providers/subcategory_provider.dart';
import 'package:smart_money_tracker/core/common/widgets/category_icon_widget.dart';

class BudgetProgressCard extends ConsumerWidget {
  final BudgetProgress progress;
  final VoidCallback? onTap;
  const BudgetProgressCard({Key? key, required this.progress, this.onTap})
    : super(key: key);

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

    final resolvedCategoryName =
        categoryModel?.name ?? progress.budget.categoryId;
    final displayTitle = resolvedCategoryName != null
        ? '${resolvedCategoryName[0].toUpperCase()}${resolvedCategoryName.substring(1)}'
        : 'Overall Budget';

    final formatCurrency = NumberFormat.compactCurrency(
      locale: 'en_US',
      symbol: '₹',
      decimalDigits: 0,
    );

    int? daysLeft;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (progress.isCompleted) {
      daysLeft = 0;
    } else if (progress.periodEnd != null) {
      final end = DateTime(
        progress.periodEnd!.year,
        progress.periodEnd!.month,
        progress.periodEnd!.day,
      );
      daysLeft = end.difference(today).inDays + 1;
      if (daysLeft < 0) daysLeft = 0;
    }

    String bottomText = '';
    if (progress.isOverBudget) {
      bottomText =
          'Over budget by ${formatCurrency.format(progress.spent - progress.budget.amount)}';
    } else {
      bottomText = formatCurrency.format(progress.remaining);
    }

    if (daysLeft != null) {
      if (daysLeft < 1 || progress.isCompleted) {
        bottomText += progress.isOverBudget
            ? ' • Completed'
            : ' left • Completed';
      } else if (daysLeft == 1) {
        bottomText += progress.isOverBudget
            ? ' • Expires today'
            : ' left • Expires today';
      } else {
        bottomText += ' • $daysLeft day${daysLeft == 1 ? '' : 's'} left';
      }
    } else {
      if (!progress.isOverBudget) {
        bottomText += ' left';
      }
    }

    final categoryColor = progress.budget.categoryId != null
        ? AppColors.getCategoryColor(progress.budget.categoryId!)
        : AppColors.warning;

    // Determine color based on usage (for text or progress bar if needed)
    Color progressColor = categoryColor;
    if (progress.percentage >= 1.0) {
      progressColor = AppColors.error;
    } else if (progress.percentage >= 0.8) {
      progressColor = AppColors.warning;
    }

    return InkWell(
      borderRadius: AppSizes.cardBorderRadius,
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.zero,
        padding: EdgeInsets.all(AppSizes.r(16)),
        decoration: BoxDecoration(
          color: AppColors.getSurfaceContainerLowest(context),
          borderRadius: AppSizes.cardBorderRadius,
          border: AppColors.isDark(context)
              ? null
              : Border.all(color: AppColors.black.withOpacity(0.08), width: 1),
          boxShadow: AppColors.isDark(context)
              ? null
              : [
                  BoxShadow(
                    color: AppColors.black.withOpacity(0.03),
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
                  width: AppSizes.r(40),
                  height: AppSizes.r(40),
                  decoration: BoxDecoration(
                    color: categoryColor,
                    shape: BoxShape.circle,
                  ),
                  child: progress.budget.categoryId == null
                      ? Icon(
                          Icons.pie_chart_rounded,
                          color: AppColors.white,
                          size: AppSizes.r(24),
                        )
                      : CategoryIconWidget(
                          categoryName: resolvedCategoryName!,
                          emoji: categoryModel?.emoji,
                          color: AppColors.white,
                          size: AppSizes.r(24),
                        ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (progress.budget.isStopped) ...[
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSizes.w(6),
                          vertical: AppSizes.h(2),
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(AppSizes.r(8)),
                        ),
                        child: Text(
                          'Stopped',
                          style: AppTextStyles.small(context).copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ] else if (progress.isCompleted) ...[
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSizes.w(6),
                          vertical: AppSizes.h(2),
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(AppSizes.r(8)),
                        ),
                        child: Text(
                          'Completed',
                          style: AppTextStyles.small(context).copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ] else ...[
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSizes.w(6),
                          vertical: AppSizes.h(2),
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.getTextMuted(
                            context,
                          ).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(AppSizes.r(8)),
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
              progress.budget.name.isNotEmpty
                  ? progress.budget.name
                  : displayTitle,
              style: AppTextStyles.body(
                context,
                color: AppColors.getText(context),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: AppSizes.h4),
            Text(
              '${formatCurrency.format(progress.spent)} / ${formatCurrency.format(progress.budget.amount)}',
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
                    : AppColors.primary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

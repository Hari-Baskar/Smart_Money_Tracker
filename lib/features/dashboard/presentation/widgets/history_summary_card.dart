import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:smart_money_tracker/core/constants/app_colors.dart';
import 'package:smart_money_tracker/core/constants/app_sizes.dart';
import 'package:smart_money_tracker/core/theme/app_text_styles.dart';
import 'package:smart_money_tracker/core/common/widgets/primary_button.dart';
import 'package:smart_money_tracker/core/constants/app_routes.dart';

class HistorySummaryCard extends StatelessWidget {
  final String selectedCategory;
  final String selectedSubcategory;
  final double totalSpent;
  final double totalIncome;
  final int incomeCount;
  final int expenseCount;
  final DateTimeRange? dateRange;
  final String creditLabel;
  final String debitLabel;
  final VoidCallback? onAnalysisTap;
  final VoidCallback? onExportTap;
  final VoidCallback? onFilterTap;
  final int activeFiltersCount;

  const HistorySummaryCard({
    super.key,
    required this.selectedCategory,
    required this.selectedSubcategory,
    required this.totalSpent,
    required this.totalIncome,
    this.incomeCount = 0,
    this.expenseCount = 0,
    this.dateRange,
    this.creditLabel = 'Total Credit',
    this.debitLabel = 'Total Debit',
    this.onAnalysisTap,
    this.onExportTap,
    this.onFilterTap,
    this.activeFiltersCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    String dateLabel = '';
    if (dateRange != null) {
      final start = DateFormat('MMM dd').format(dateRange!.start);
      final end = DateFormat('MMM dd').format(dateRange!.end);
      dateLabel = '$start to $end';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (dateLabel.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dateLabel,
                style: AppTextStyles.subHeading(
                  context,
                  color: AppColors.getTextMuted(context),
                ).copyWith(fontWeight: FontWeight.w600),
              ),
              if (activeFiltersCount > 0)
                TextButton(
                  onPressed: onFilterTap,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSizes.w12,
                      vertical: AppSizes.h4,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'View Filters ($activeFiltersCount)',
                    style: AppTextStyles.body(
                      context,
                      color: AppColors.primary,
                    ).copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
          SizedBox(height: AppSizes.h12),
        ],
        IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  context: context,
                  label: creditLabel,
                  amount: totalIncome,
                  color: AppColors.success,
                  count: incomeCount,
                  onTap: () {
                    context.push(AppRoutes.income, extra: dateRange);
                  },
                ),
              ),
              SizedBox(width: AppSizes.w8),
              Expanded(
                child: _buildSummaryItem(
                  context: context,
                  label: debitLabel,
                  amount: totalSpent,
                  color: AppColors.error,
                  count: expenseCount,
                  onTap: () {
                    context.push(AppRoutes.expense, extra: dateRange);
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryItem({
    required BuildContext context,
    required String label,
    required double amount,
    required Color color,
    required int count,
    VoidCallback? onTap,
  }) {
    final isDark = AppColors.isDark(context);
    final isIncome =
        label.toLowerCase().contains('income') ||
        label.toLowerCase().contains('credit');

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(AppSizes.r16),
        decoration: BoxDecoration(
          color: AppColors.getSurfaceContainerLowest(context),
          borderRadius: AppSizes.cardBorderRadius,
          border: isDark
              ? null
              : Border.all(color: AppColors.black.withOpacity(0.08), width: 1),
          boxShadow: isDark
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
                  width: AppSizes.r40,
                  height: AppSizes.r40,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isIncome
                        ? Icons.arrow_downward_rounded
                        : Icons.arrow_upward_rounded,
                    color: AppColors.white,
                    size: AppSizes.r24,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSizes.w(6),
                    vertical: AppSizes.h(2),
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.getTextMuted(context).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(AppSizes.r8),
                  ),
                  child: Text(
                    isIncome ? 'Income' : 'Expense',
                    style: AppTextStyles.small(context).copyWith(
                      color: AppColors.getText(context),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSizes.h8),
            Text(
              label,
              style: AppTextStyles.body(
                context,
                color: AppColors.getText(context),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: AppSizes.h4),
            Text(
              '₹${AppColors.formatShortAmount(amount)}',
              style: AppTextStyles.subHeading(
                context,
                fontWeight: FontWeight.bold,
                color: isIncome
                    ? AppColors.success
                    : (isDark ? AppColors.textDark : AppColors.textLight),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: AppSizes.h4),
            Text(
              '$count Transaction${count == 1 ? '' : 's'}',
              style: AppTextStyles.body(
                context,
                color: AppColors.getTextMuted(context),
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

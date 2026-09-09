import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:smart_money_tracker/core/constants/app_colors.dart';
import 'package:smart_money_tracker/core/constants/app_sizes.dart';
import 'package:smart_money_tracker/core/theme/app_text_styles.dart';
import 'package:smart_money_tracker/core/constants/app_routes.dart';
import 'package:smart_money_tracker/core/common/widgets/category_icon_widget.dart';
import 'package:smart_money_tracker/core/models/transaction_model.dart';

class HistorySummaryCard extends StatelessWidget {
  final String selectedCategory;
  final String selectedSubcategory;
  final double totalSpent;
  final double totalIncome;
  final int incomeCount;
  final int expenseCount;
  final DateTimeRange? dateRange;
  final TransactionType? transactionType;
  final bool? isIncomeCategory;
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
    this.transactionType,
    this.isIncomeCategory,
    this.creditLabel = 'Credit',
    this.debitLabel = 'Debit',
    this.onAnalysisTap,
    this.onExportTap,
    this.onFilterTap,
    this.activeFiltersCount = 0,
  });

  String _formatAmount(double val) {
    final isInt = val == val.truncateToDouble();
    return NumberFormat.currency(
      symbol: '₹',
      decimalDigits: isInt ? 0 : 2,
      locale: 'en_IN',
    ).format(val);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    String dateLabel = '';
    if (dateRange != null) {
      final start = DateFormat('MMM dd').format(dateRange!.start);
      final end = DateFormat('MMM dd, yyyy').format(dateRange!.end);
      dateLabel = '$start - $end';
    }

    final hasCustomCategory = selectedCategory != 'All';
    final hasCustomSubcategory = selectedSubcategory != 'All';

    String filterTitle;
    if (hasCustomCategory) {
      if (hasCustomSubcategory) {
        filterTitle = '$selectedCategory → $selectedSubcategory';
      } else {
        filterTitle = selectedCategory;
      }
    } else {
      filterTitle = 'All Transactions';
    }

    final balance = totalIncome - totalSpent;
    final totalTransactions = incomeCount + expenseCount;

    final isDebitOnly = transactionType == TransactionType.debit ||
        (isIncomeCategory == false) ||
        incomeCount == 0;
    final isCreditOnly = transactionType == TransactionType.credit ||
        (isIncomeCategory == true) ||
        expenseCount == 0;
    final isSingleType = isDebitOnly || isCreditOnly;

    final creditValue = isDebitOnly ? '-' : _formatAmount(totalIncome);
    final creditColor = isDebitOnly
        ? AppColors.getTextMuted(context)
        : AppColors.success;
    final creditOnTap = isDebitOnly
        ? null
        : () {
            context.push(AppRoutes.income, extra: dateRange);
          };

    final debitValue = isCreditOnly ? '-' : _formatAmount(totalSpent);
    final debitColor = isCreditOnly
        ? AppColors.getTextMuted(context)
        : AppColors.getText(context);
    final debitOnTap = isCreditOnly
        ? null
        : () {
            context.push(AppRoutes.expense, extra: dateRange);
          };

    final balanceValue = isSingleType
        ? '-'
        : (balance < 0
            ? '-${_formatAmount(balance.abs())}'
            : (balance > 0
                ? '+${_formatAmount(balance)}'
                : _formatAmount(balance)));

    final balanceColor = isSingleType
        ? AppColors.getTextMuted(context)
        : (balance < 0
            ? AppColors.error
            : (balance > 0
                ? AppColors.success
                : AppColors.getText(context)));

    return Container(
      decoration: BoxDecoration(
        color: AppColors.getSurfaceContainerLowest(context),
        borderRadius: AppSizes.cardBorderRadius,
        border: isDark
            ? null
            : Border.all(
                color: AppColors.black.withValues(alpha: 0.08),
                width: 1,
              ),
        boxShadow: isDark
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
          // ── Top Header Row (Filter details & arrow) ──
          InkWell(
            onTap: onFilterTap,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppSizes.cardRadius),
            ),
            child: Padding(
              padding: EdgeInsets.all(AppSizes.w16),
              child: Row(
                children: [
                  // Icon indicator
                  Container(
                    width: AppSizes.r40,
                    height: AppSizes.r40,
                    decoration: BoxDecoration(
                      color: hasCustomCategory
                          ? AppColors.getCategoryColor(selectedCategory)
                          : (isDark
                              ? const Color(0xFF2A2A2A)
                              : AppColors.primary.withValues(alpha: 0.12)),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: hasCustomCategory
                          ? CategoryIconWidget(
                              categoryName: selectedCategory,
                              color: AppColors.white,
                              size: AppSizes.r20,
                            )
                          : Icon(
                              Icons.tune_rounded,
                              color: isDark
                                  ? AppColors.white
                                  : AppColors.primary,
                              size: AppSizes.r20,
                            ),
                    ),
                  ),
                  SizedBox(width: AppSizes.w12),
                  // Title and Subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          filterTitle,
                          style: AppTextStyles.subHeading(context).copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.getText(context),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: AppSizes.h2),
                        Text(
                          dateLabel.isNotEmpty
                              ? (activeFiltersCount > 0
                                  ? '$dateLabel · $activeFiltersCount filter${activeFiltersCount == 1 ? '' : 's'}'
                                  : dateLabel)
                              : 'Tap to filter history',
                          style: AppTextStyles.body(context).copyWith(
                            color: AppColors.getTextMuted(context),
                            fontSize: AppSizes.r12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.getTextMuted(context),
                    size: AppSizes.r24,
                  ),
                ],
              ),
            ),
          ),

          Divider(
            height: 1,
            thickness: 1,
            color: isDark
                ? const Color(0xFF2E2E32)
                : const Color(0xFFE5E7EB),
          ),

          // ── Metrics Grid (Credit, Debit, Balance, Total Transactions) ──
          Padding(
            padding: EdgeInsets.all(AppSizes.w16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row 1: Credit & Debit
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailCell(
                        context,
                        label: creditLabel,
                        value: creditValue,
                        valueColor: creditColor,
                        onTap: creditOnTap,
                      ),
                    ),
                    SizedBox(width: AppSizes.w16),
                    Expanded(
                      child: _buildDetailCell(
                        context,
                        label: debitLabel,
                        value: debitValue,
                        valueColor: debitColor,
                        onTap: debitOnTap,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppSizes.h20),

                // Row 2: Balance & Total Transactions
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailCell(
                        context,
                        label: 'Balance',
                        value: balanceValue,
                        valueColor: balanceColor,
                      ),
                    ),
                    SizedBox(width: AppSizes.w16),
                    Expanded(
                      child: _buildDetailCell(
                        context,
                        label: 'Total transactions',
                        value: '$totalTransactions',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCell(
    BuildContext context, {
    required String label,
    required String value,
    Color? valueColor,
    VoidCallback? onTap,
  }) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.body(
            context,
          ).copyWith(color: AppColors.getTextMuted(context)),
        ),
        SizedBox(height: AppSizes.h4),
        Text(
          value,
          style: AppTextStyles.body(context).copyWith(
            fontWeight: FontWeight.w600,
            color: valueColor ?? AppColors.getText(context),
          ),
        ),
      ],
    );

    if (onTap != null) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: content,
      );
    }
    return content;
  }
}

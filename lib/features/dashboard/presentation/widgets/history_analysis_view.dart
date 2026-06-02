import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:smart_money_tracker/core/constants/app_colors.dart';
import 'package:smart_money_tracker/core/constants/app_sizes.dart';
import 'package:smart_money_tracker/core/models/transaction_model.dart';
import 'package:smart_money_tracker/core/theme/app_text_styles.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/widgets/premium_pie_chart.dart';

class HistoryAnalysisView extends StatelessWidget {
  final List<TransactionModel> transactions;
  final ValueNotifier<String> analysisType;

  const HistoryAnalysisView({
    super.key,
    required this.transactions,
    required this.analysisType,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final isExpense = analysisType.value == 'Expenses';

    final filteredTransactions = transactions.where((t) {
      return isExpense
          ? t.type == TransactionType.debit
          : t.type == TransactionType.credit;
    }).toList();

    // Segmented toggle widget
    final segmentedToggle = Container(
      margin: EdgeInsets.only(bottom: AppSizes.h16),
      padding: EdgeInsets.all(AppSizes.r(4)),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainerLight,
        borderRadius: BorderRadius.circular(AppSizes.r16),
      ),
      child: Row(
        children: [
          // Expenses Toggle
          Expanded(
            child: GestureDetector(
              onTap: () => analysisType.value = 'Expenses',
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(vertical: AppSizes.h(8)),
                decoration: BoxDecoration(
                  color: isExpense
                      ? (isDark ? AppColors.primary : AppColors.white)
                      : AppColors.transparent,
                  borderRadius: BorderRadius.circular(AppSizes.r12),
                  boxShadow: isExpense && !isDark
                      ? [
                          BoxShadow(
                            color: AppColors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                alignment: Alignment.center,
                child: Text(
                  'Expenses',
                  style: AppTextStyles.small(
                    context,
                    fontWeight: FontWeight.bold,
                    color: isExpense
                        ? (isDark ? AppColors.white : AppColors.primary)
                        : AppColors.getTextMuted(context),
                  ),
                ),
              ),
            ),
          ),
          
          // Income Toggle
          Expanded(
            child: GestureDetector(
              onTap: () => analysisType.value = 'Income',
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(vertical: AppSizes.h(8)),
                decoration: BoxDecoration(
                  color: !isExpense
                      ? (isDark ? AppColors.primary : AppColors.white)
                      : AppColors.transparent,
                  borderRadius: BorderRadius.circular(AppSizes.r12),
                  boxShadow: !isExpense && !isDark
                      ? [
                          BoxShadow(
                            color: AppColors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                alignment: Alignment.center,
                child: Text(
                  'Income',
                  style: AppTextStyles.small(
                    context,
                    fontWeight: FontWeight.bold,
                    color: !isExpense
                        ? (isDark ? AppColors.white : AppColors.primary)
                        : AppColors.getTextMuted(context),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (filteredTransactions.isEmpty) {
      return Column(
        children: [
          segmentedToggle,
          SizedBox(height: AppSizes.h24),
          _buildEmptyState(
            context,
            'No ${analysisType.value.toLowerCase()} transactions found for this selection',
          ),
        ],
      );
    }

    // Flatten transactions with splits so that splits are analyzed individually
    final List<TransactionModel> flattenedTransactions = [];
    for (var t in filteredTransactions) {
      if (t.splits.isEmpty) {
        flattenedTransactions.add(t);
      } else {
        // Add each explicit split as a virtual transaction
        double splitTotal = 0;
        int splitIndex = 0;
        for (var split in t.splits) {
          splitTotal += split.amount;
          final virtualTxn = TransactionModel(
            id: '${t.id}_split_$splitIndex',
            amount: split.amount,
            merchant: t.merchant,
            date: split.date ?? t.date,
            type: t.type,
            category: split.category,
            subcategory: split.subcategory,
            rawSms: t.rawSms,
            splits: const [],
            isEdited: t.isEdited,
            reference: t.reference,
            bankId: t.bankId,
            paymentMethodId: t.paymentMethodId,
          );
          flattenedTransactions.add(virtualTxn);
          splitIndex++;
        }

        // Add the remainder (parent total − sum of splits) under the parent's
        // own category so it is not lost in analysis.
        final remainder = t.amount - splitTotal;
        if (remainder > 0.01) {
          flattenedTransactions.add(TransactionModel(
            id: '${t.id}_remainder',
            amount: remainder,
            merchant: t.merchant,
            date: t.date,
            type: t.type,
            category: t.category,
            subcategory: t.subcategory,
            rawSms: t.rawSms,
            splits: const [],
            isEdited: t.isEdited,
            reference: t.reference,
            bankId: t.bankId,
            paymentMethodId: t.paymentMethodId,
          ));
        }
      }
    }

    // 1. Group by category
    final Map<String, List<TransactionModel>> categoryGroups = {};
    for (var t in flattenedTransactions) {
      categoryGroups.putIfAbsent(t.category, () => []).add(t);
    }

    // Calculate category totals
    final Map<String, double> categoryAmounts = {};
    for (var entry in categoryGroups.entries) {
      final total = entry.value.fold(0.0, (sum, t) => sum + t.amount);
      categoryAmounts[entry.key] = total;
    }

    // 2. Sort categories by total amount descending
    final sortedCategories = categoryGroups.keys.toList()
      ..sort((a, b) {
        final totalA = categoryGroups[a]!.fold(0.0, (sum, t) => sum + t.amount);
        final totalB = categoryGroups[b]!.fold(0.0, (sum, t) => sum + t.amount);
        return totalB.compareTo(totalA);
      });

    return Column(
      children: [
        segmentedToggle,
        PremiumPieChart(
          categoryAmounts: categoryAmounts,
          currencySymbol: '₹',
        ),
        SizedBox(height: AppSizes.h24),

        ...sortedCategories.map((cat) {
          final catTransactions = categoryGroups[cat]!;
          final catTotal = catTransactions.fold(
            0.0,
            (sum, t) => sum + t.amount,
          );

          // 3. Group by subcategory within category
          final Map<String, double> subGroups = {};
          for (var t in catTransactions) {
            subGroups[t.subcategory] =
                (subGroups[t.subcategory] ?? 0.0) + t.amount;
          }

          final sortedSubs = subGroups.keys.toList()
            ..sort((a, b) => subGroups[b]!.compareTo(subGroups[a]!));

          return Container(
            margin: EdgeInsets.only(bottom: AppSizes.h12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: AppSizes.cardBorderRadius,
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withOpacity(0.06),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: AppColors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.symmetric(
                  horizontal: AppSizes.w16,
                  vertical: AppSizes.h4,
                ),
                leading: Container(
                  width: AppSizes.r40,
                  height: AppSizes.r40,
                  decoration: BoxDecoration(
                    color: AppColors.getCategoryBgColor(context, cat),
                    borderRadius: AppSizes.cardBorderRadius,
                  ),
                  child: Icon(
                    AppColors.getCategoryIcon(cat),
                    color: AppColors.getCategoryColor(cat),
                    size: AppSizes.r20,
                  ),
                ),
                title: Text(
                  cat,
                  style: AppTextStyles.body(
                    context,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                trailing: Text(
                  '₹${AppColors.formatShortAmount(catTotal)}',
                  style: AppTextStyles.body(
                    context,
                    color: catTransactions.any(
                          (t) => t.type == TransactionType.credit,
                        )
                        ? AppColors.success
                        : AppColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                children: [
                  Padding(
                    padding: EdgeInsets.only(
                      left: AppSizes.w16,
                      right: AppSizes.w16,
                      bottom: AppSizes.h16,
                    ),
                    child: Column(
                      children: [
                        Divider(
                          color: Theme.of(context).colorScheme.surfaceVariant,
                        ),
                        SizedBox(height: AppSizes.h8),
                        ...sortedSubs.map((sub) {
                          final subTotal = subGroups[sub]!;
                          final percentage = (subTotal / catTotal) * 100;
                          return Padding(
                            padding: EdgeInsets.symmetric(vertical: AppSizes.h(6)),
                            child: Row(
                              children: [
                                Container(
                                  width: AppSizes.r8,
                                  height: AppSizes.r8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                SizedBox(width: AppSizes.w12),
                                Expanded(
                                  child: Text(
                                    sub,
                                    style: AppTextStyles.small(context),
                                  ),
                                ),
                                Text(
                                  '₹${AppColors.formatShortAmount(subTotal)}',
                                  style: AppTextStyles.small(
                                    context,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(width: AppSizes.w12),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: AppSizes.w8,
                                    vertical: AppSizes.h(2),
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.surfaceVariant,
                                    borderRadius: AppSizes.cardBorderRadius,
                                  ),
                                  child: Text(
                                    '${percentage.toStringAsFixed(0)}%',
                                    style: AppTextStyles.small(
                                      context,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: AppSizes.r(64),
            color: Theme.of(
              context,
            ).colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
          SizedBox(height: AppSizes.h16),
          Text(
            message,
            style: AppTextStyles.body(
              context,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

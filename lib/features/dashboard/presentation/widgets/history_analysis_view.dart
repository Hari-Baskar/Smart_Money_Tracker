import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:smart_money_tracker/core/constants/app_colors.dart';
import 'package:smart_money_tracker/core/constants/app_sizes.dart';
import 'package:smart_money_tracker/core/models/transaction_model.dart';
import 'package:smart_money_tracker/core/theme/app_text_styles.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/widgets/premium_pie_chart.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/widgets/premium_bar_chart.dart';
import 'package:intl/intl.dart';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/providers/transaction_provider.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/providers/subcategory_provider.dart';
import 'package:smart_money_tracker/core/services/analytics_service.dart';
import 'package:smart_money_tracker/core/common/widgets/banner_ad_widget.dart';

class HistoryAnalysisView extends HookConsumerWidget {
  final List<TransactionModel> transactions;
  final ValueNotifier<String> analysisType;

  const HistoryAnalysisView({
    super.key,
    required this.transactions,
    required this.analysisType,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useEffect(() {
      AnalyticsService.logEvent('view_history_analysis');
      return null;
    }, const []);

    final isDark = AppColors.isDark(context);
    final isExpense = analysisType.value == 'Expenses';
    final expandedCategory = useState<String?>(null);
    
    final categoriesAsync = ref.watch(categoriesProvider);
    final subcategoriesAsync = ref.watch(subcategoriesProvider);
    final categories = categoriesAsync.value ?? const [];
    final subcategories = subcategoriesAsync.value ?? const [];

    String resolveCategory(String id) {
      final match = categories.where((c) => c.id == id).firstOrNull;
      return match?.name ?? id;
    }
    String resolveSubcategory(String id) {
      final match = subcategories.where((s) => s.id == id).firstOrNull;
      return match?.name ?? id;
    }

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
        color: isDark
            ? AppColors.surfaceContainerDark
            : Colors.white,
        borderRadius: AppSizes.boxBorderRadius,
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
                      ? AppColors.primary
                      : AppColors.transparent,
                  borderRadius: AppSizes.boxBorderRadius,
                  boxShadow: isExpense && !isDark
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                alignment: Alignment.center,
                child: Text(
                  'Expenses',
                  style: AppTextStyles.body(
                    context,
                    color: isExpense
                        ? Colors.white
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
                      ? AppColors.primary
                      : AppColors.transparent,
                  borderRadius: AppSizes.boxBorderRadius,
                  boxShadow: !isExpense && !isDark
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                alignment: Alignment.center,
                child: Text(
                  'Income',
                  style: AppTextStyles.body(
                    context,
                    color: !isExpense
                        ? Colors.white
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
          flattenedTransactions.add(
            TransactionModel(
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
            ),
          );
        }
      }
    }

    // 1. Group by category
    final Map<String, List<TransactionModel>> categoryGroups = {};
    for (var t in flattenedTransactions) {
      categoryGroups.putIfAbsent(t.category, () => []).add(t);
    }

    // Calculate category totals and use display names as keys
    final Map<String, double> categoryAmounts = {};
    for (var entry in categoryGroups.entries) {
      final total = entry.value.fold(0.0, (sum, t) => sum + t.amount);
      final displayCat = resolveCategory(entry.key);
      categoryAmounts[displayCat] = (categoryAmounts[displayCat] ?? 0.0) + total;
    }

    // 2. Sort categories (IDs) by total amount descending
    final sortedCategories = categoryGroups.keys.toList()
      ..sort((a, b) {
        final totalA = categoryGroups[a]!.fold(0.0, (sum, t) => sum + t.amount);
        final totalB = categoryGroups[b]!.fold(0.0, (sum, t) => sum + t.amount);
        return totalB.compareTo(totalA);
      });

    final totalAmount = filteredTransactions.fold<double>(
      0,
      (sum, t) => sum + t.amount,
    );

    return Column(
      children: [
        segmentedToggle,
        PremiumPieChart(
          categoryAmounts: categoryAmounts,
          currencySymbol: '₹',
          totalAmount: totalAmount,
          isExpense: isExpense,
        ),
        SizedBox(height: AppSizes.h8),
        const BannerAdWidget(),
        SizedBox(height: AppSizes.h8),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceContainerDark : Colors.white,
            borderRadius: AppSizes.cardBorderRadius,
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withOpacity(0.03),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: EdgeInsets.all(AppSizes.w16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Category Breakdown',
                style: AppTextStyles.body(context, fontWeight: FontWeight.bold).copyWith(color: isDark ? Colors.white : Colors.black87),
              ),
              SizedBox(height: AppSizes.h24),
              ...List.generate(sortedCategories.length, (index) {
                final cat = sortedCategories[index];
                final catTransactions = categoryGroups[cat]!;
                final catTotal = catTransactions.fold(0.0, (sum, t) => sum + t.amount);
                final percentage = totalAmount > 0 ? (catTotal / totalAmount) : 0.0;
                final isExpanded = expandedCategory.value == cat;
                
                const palette = [
                  Color(0xFF64B5F6),
                  Color(0xFF81C784),
                  Color(0xFFFFB74D),
                  Color(0xFFBA68C8),
                  Color(0xFFE57373),
                  Color(0xFF4DB6AC),
                  Color(0xFF7986CB),
                  Color(0xFFFFD54F),
                  Color(0xFFA1887F),
                  Color(0xFF90A4AE),
                ];
                final color = palette[index % palette.length];

                return GestureDetector(
                  onTap: () {
                    expandedCategory.value = isExpanded ? null : cat;
                  },
                  child: Container(
                    margin: EdgeInsets.only(bottom: AppSizes.h20),
                    color: Colors.transparent,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: AppSizes.r(48),
                              height: AppSizes.r(48),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                AppColors.getCategoryIcon(resolveCategory(cat)),
                                color: color,
                                size: AppSizes.r24,
                              ),
                            ),
                            SizedBox(width: AppSizes.w12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    resolveCategory(cat),
                                    style: AppTextStyles.body(context).copyWith(color: isDark ? Colors.white : Colors.black87),
                                  ),
                                  SizedBox(height: AppSizes.h8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: percentage,
                                      backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                                      valueColor: AlwaysStoppedAnimation<Color>(color),
                                      minHeight: 6,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: AppSizes.w16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '₹${catTotal.toStringAsFixed(2)}',
                                  style: AppTextStyles.body(
                                    context,
                                    color: isExpense ? AppColors.error : AppColors.success,
                                  ).copyWith(fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${(percentage * 100).toStringAsFixed(0)}%',
                                  style: AppTextStyles.small(context, color: isDark ? Colors.grey[400] : AppColors.textMuted),
                                ),
                              ],
                            ),
                            SizedBox(width: AppSizes.w8),
                            Icon(
                              isExpanded ? Icons.expand_less : Icons.expand_more,
                              color: isDark ? Colors.grey[400] : AppColors.textMuted.withOpacity(0.5),
                              size: AppSizes.r20,
                            ),
                          ],
                        ),
                        if (isExpanded) ...[
                          SizedBox(height: AppSizes.h16),
                          Divider(color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.2)),
                          SizedBox(height: AppSizes.h8),
                          Text(
                            '${catTransactions.length} Transactions',
                            style: AppTextStyles.small(context, color: isDark ? Colors.grey[400] : AppColors.textMuted),
                          ),
                          SizedBox(height: AppSizes.h12),
                          ...catTransactions.map((t) {
                            return Padding(
                              padding: EdgeInsets.only(bottom: AppSizes.h8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                      child: Text(
                                        t.merchant.trim().isNotEmpty && t.merchant.trim() != '-'
                                            ? t.merchant
                                            : DateFormat('MMM dd, hh:mm a').format(t.date),
                                        style: AppTextStyles.body(context).copyWith(fontSize: 13, color: isDark ? Colors.white : Colors.black87),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    '₹${t.amount.toStringAsFixed(2)}',
                                    style: AppTextStyles.body(context).copyWith(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
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
            textAlign: TextAlign.center,
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

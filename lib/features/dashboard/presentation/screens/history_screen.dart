import 'package:smart_money_tracker/core/constants/app_sizes.dart';
import 'package:smart_money_tracker/core/constants/app_colors.dart';
import 'package:smart_money_tracker/core/theme/app_text_styles.dart';
import 'package:smart_money_tracker/core/models/transaction_model.dart';
import 'package:smart_money_tracker/core/constants/payment_constants.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/providers/transaction_provider.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/screens/transaction_detail_screen.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/screens/history_filter_screen.dart';
import '../widgets/expandable_transaction_card.dart';
import '../widgets/history_summary_card.dart';
import '../widgets/history_analysis_view.dart';
import 'package:smart_money_tracker/features/main/presentation/screens/main_screen.dart';
import 'package:smart_money_tracker/core/common/widgets/banner_ad_widget.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends HookConsumerWidget {
  const HistoryScreen({super.key});



  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showAnalysis = useState(false);
    final analysisType = useState('Expenses');

    final filterState = useState(
      HistoryFilterState(
        dateRange: DateTimeRange(
          start: DateTime.now().subtract(const Duration(days: 30)),
          end: DateTime.now(),
        ),
        category: 'All',
        subcategory: 'All',
      ),
    );

    Future<void> openFilterScreen() async {
      final result = await Navigator.of(context).push<HistoryFilterState>(
        MaterialPageRoute(
          builder: (_) => HistoryFilterScreen(initial: filterState.value),
        ),
      );
      if (result != null) {
        filterState.value = result;
      }
    }

    // Shortcuts
    final selectedCategory = filterState.value.category;
    final selectedSubcategory = filterState.value.subcategory;
    final dateRange = filterState.value.dateRange;
    final selectedBankId = filterState.value.bankId;
    final selectedPaymentMethodId = filterState.value.paymentMethodId;
    final activeFilterCount = [
      selectedCategory != 'All',
      selectedSubcategory != 'All',
      selectedBankId != null,
      selectedPaymentMethodId != null,
    ].where((v) => v).length;

    final startOfRange = DateTime(
      dateRange.start.year,
      dateRange.start.month,
      dateRange.start.day,
    );
    final endOfRange = DateTime(
      dateRange.end.year,
      dateRange.end.month,
      dateRange.end.day,
      23,
      59,
      59,
      999,
    );
    final adjustedRange = DateTimeRange(start: startOfRange, end: endOfRange);

    final transactionsAsync = ref.watch(
      transactionsInDateRangeProvider(adjustedRange),
    );

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: AppColors.transparent,
        elevation: 0,
        leading: showAnalysis.value
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new),
                onPressed: () => showAnalysis.value = false,
              )
            : IconButton(
                icon: Icon(Icons.menu_rounded, size: AppSizes.r(28)),
                onPressed: () => ref
                    .read(mainScaffoldKeyProvider)
                    .currentState
                    ?.openDrawer(),
              ),
        title: Text(
          showAnalysis.value ? 'Analysis' : 'History',
          style: AppTextStyles.heading(context),
        ),
        centerTitle: true,
        actions: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: Icon(
                  Icons.tune_rounded,
                  size: AppSizes.r(24),
                  color: filterState.value.hasActiveFilters
                      ? AppColors.primary
                      : null,
                ),
                tooltip: 'Filters',
                onPressed: openFilterScreen,
              ),
              if (activeFilterCount > 0)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    width: AppSizes.r(16),
                    height: AppSizes.r(16),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$activeFilterCount',
                        style: AppTextStyles.small(
                          context,
                          color: AppColors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 8,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(AppSizes.w12),
        child: Column(
          children: [

            Expanded(
              child: transactionsAsync.when(
                data: (transactions) {
                  // 1. Filter by Date Range (already handled by provider range)
                  final dateFiltered = transactions.where((t) {
                    return t.date.isAfter(
                          dateRange.start.subtract(
                            const Duration(seconds: 1),
                          ),
                        ) &&
                        t.date.isBefore(
                          dateRange.end.add(const Duration(days: 1)),
                        );
                  }).toList();

                  // 2. Filter by Category, Subcategory, Bank, PaymentMethod & Calculate Totals
                  double totalSpent = 0;
                  double totalIncome = 0;
                  final List<TransactionModel> finalFiltered = [];

                  for (var t in dateFiltered) {
                    // Bank filter
                    if (selectedBankId != null && t.bankId != selectedBankId) {
                      continue;
                    }
                    // Payment method filter
                    if (selectedPaymentMethodId != null &&
                        t.paymentMethodId != selectedPaymentMethodId) {
                      continue;
                    }

                    if (selectedCategory == 'All') {
                      final subcategoryMatch = selectedSubcategory == 'All' ||
                          t.subcategory == selectedSubcategory;
                      if (subcategoryMatch) {
                        finalFiltered.add(t);
                        if (t.type == TransactionType.credit) {
                          totalIncome += t.amount;
                        } else {
                          totalSpent += t.amount;
                        }
                      }
                    } else {
                      if (t.splits.isEmpty) {
                        final categoryMatch = t.category == selectedCategory;
                        final subcategoryMatch = selectedSubcategory == 'All' ||
                            t.subcategory == selectedSubcategory;
                        if (categoryMatch && subcategoryMatch) {
                          finalFiltered.add(t);
                          if (t.type == TransactionType.credit) {
                            totalIncome += t.amount;
                          } else {
                            totalSpent += t.amount;
                          }
                        }
                      } else {
                        // Transaction has splits, and category filter is NOT 'All'.
                        double splitTotal = 0;
                        int splitIndex = 0;
                        for (var split in t.splits) {
                          splitTotal += split.amount;
                          final categoryMatch =
                              split.category == selectedCategory;
                          final subcategoryMatch =
                              selectedSubcategory == 'All' ||
                              split.subcategory == selectedSubcategory;

                          if (categoryMatch && subcategoryMatch) {
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
                            finalFiltered.add(virtualTxn);
                            if (t.type == TransactionType.credit) {
                              totalIncome += split.amount;
                            } else {
                              totalSpent += split.amount;
                            }
                          }
                          splitIndex++;
                        }

                        final remainder = t.amount - splitTotal;
                        if (remainder > 0.01) {
                          final categoryMatch = t.category == selectedCategory;
                          final subcategoryMatch =
                              selectedSubcategory == 'All' ||
                              t.subcategory == selectedSubcategory;
                          if (categoryMatch && subcategoryMatch) {
                            final virtualRemainder = TransactionModel(
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
                            );
                            finalFiltered.add(virtualRemainder);
                            if (t.type == TransactionType.credit) {
                              totalIncome += remainder;
                            } else {
                              totalSpent += remainder;
                            }
                          }
                        }
                      }
                    }
                  }

                  if (finalFiltered.isEmpty) {
                    return _buildEmptyState(
                      context,
                      filterState.value.hasActiveFilters
                          ? 'No transactions match your filters'
                          : 'No transactions found for this selection',
                      filterState.value.hasActiveFilters
                          ? openFilterScreen
                          : null,
                    );
                  }

                  return ListView(
                    children: [
                      // Dynamic Summary Card
                      HistorySummaryCard(
                        selectedCategory: selectedCategory,
                        selectedSubcategory: selectedSubcategory,
                        totalSpent: totalSpent,
                        totalIncome: totalIncome,
                        incomeCount: finalFiltered
                            .where((t) => t.type == TransactionType.credit)
                            .length,
                        expenseCount: finalFiltered
                            .where((t) => t.type != TransactionType.credit)
                            .length,
                      ),
                      SizedBox(height: AppSizes.h12),

                      // Banner Ad
                      const BannerAdWidget(),
                      SizedBox(height: AppSizes.h12),

                      // Header with Toggle
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  showAnalysis.value
                                      ? 'Analysis'
                                      : selectedCategory == 'All'
                                      ? 'All Transactions'
                                      : selectedSubcategory == 'All'
                                      ? '$selectedCategory Transactions'
                                      : '$selectedCategory > $selectedSubcategory',
                                  style: AppTextStyles.body(
                                    context,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                if (selectedBankId != null || selectedPaymentMethodId != null)
                                  Text(
                                    [
                                      if (selectedBankId != null)
                                        PaymentConstants.getBankName(selectedBankId),
                                      if (selectedPaymentMethodId != null)
                                        PaymentConstants.getPaymentMethodName(selectedPaymentMethodId),
                                    ].join(' · '),
                                    style: AppTextStyles.small(
                                      context,
                                      color: AppColors.primary,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () =>
                                showAnalysis.value = !showAnalysis.value,
                            icon: Icon(
                              showAnalysis.value
                                  ? Icons.history_rounded
                                  : Icons.analytics_rounded,
                              size: AppSizes.r(18),
                              color: AppColors.primary,
                            ),
                            label: Text(
                              showAnalysis.value
                                  ? 'Show History'
                                  : 'View Analysis',
                              style: AppTextStyles.body(
                                context,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),

                      if (showAnalysis.value)
                        HistoryAnalysisView(
                          transactions: finalFiltered,
                          analysisType: analysisType,
                        )
                      else
                        ..._groupAndBuildTransactions(context, finalFiltered),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Error: $err')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _groupAndBuildTransactions(
    BuildContext context,
    List<TransactionModel> transactions,
  ) {
    final sortedTransactions = List<TransactionModel>.from(transactions)
      ..sort((a, b) => b.date.compareTo(a.date));

    final Map<String, List<TransactionModel>> grouped = {};
    for (var t in sortedTransactions) {
      final dateKey = DateFormat('MMMM dd, yyyy').format(t.date);
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(t);
    }

    List<Widget> widgets = [];
    for (var dateKey in grouped.keys) {
      widgets.add(
        Padding(
          padding: EdgeInsets.symmetric(vertical: AppSizes.h12),
          child: Text(
            dateKey,
            style: AppTextStyles.body(context, color: AppColors.primary),
          ),
        ),
      );
      widgets.addAll(
        grouped[dateKey]!.map((t) => _buildTransactionCard(context, t)),
      );
    }
    return widgets;
  }

  Widget _buildEmptyState(
    BuildContext context,
    String message, [
    VoidCallback? onAdjustFilters,
  ]) {
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
            textAlign: TextAlign.center,
          ),
          if (onAdjustFilters != null) ...[  
            SizedBox(height: AppSizes.h12),
            TextButton.icon(
              onPressed: onAdjustFilters,
              icon: Icon(Icons.tune_rounded, size: AppSizes.r16),
              label: const Text('Adjust Filters'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTransactionCard(BuildContext context, TransactionModel t) {
    return ExpandableTransactionCard(
      transaction: t,
      margin: EdgeInsets.symmetric(vertical: AppSizes.h4),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TransactionDetailScreen(transaction: t),
          ),
        );
      },
    );
  }
}

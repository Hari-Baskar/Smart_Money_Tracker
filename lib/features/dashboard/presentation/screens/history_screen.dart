import 'package:smart_money_tracker/core/constants/app_sizes.dart';
import 'package:smart_money_tracker/core/constants/app_colors.dart';
import 'package:smart_money_tracker/core/theme/app_text_styles.dart';
import 'package:smart_money_tracker/core/models/transaction_model.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/providers/transaction_provider.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/providers/subcategory_provider.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/screens/transaction_detail_screen.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/widgets/premium_pie_chart.dart';
import '../widgets/expandable_transaction_card.dart';
import '../widgets/history_filter_bar.dart';
import '../widgets/history_summary_card.dart';
import '../widgets/history_analysis_view.dart';
import 'package:smart_money_tracker/features/main/presentation/screens/main_screen.dart';
import 'package:smart_money_tracker/core/common/widgets/banner_ad_widget.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends HookConsumerWidget {
  const HistoryScreen({super.key});

  static const List<String> _categoriesList = [
    'All',
    'Food',
    'Travel',
    'Shopping',
    'Bills',
    'Groceries',
    'Entertainment',
    'Health',
    'Investment',
    'Salary',
    'Other',
    'Unknown',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = useState('All');
    final selectedSubcategory = useState('All');
    final showAnalysis = useState(false);
    final analysisType = useState('Expenses');
    final subcategoriesAsync = ref.watch(subcategoriesProvider);

    useEffect(() {
      selectedSubcategory.value = 'All';
      return null;
    }, [selectedCategory.value]);

    final dateRange = useState(
      DateTimeRange(
        start: DateTime.now().subtract(const Duration(days: 30)),
        end: DateTime.now(),
      ),
    );

    Future<void> selectDateRange() async {
      final DateTimeRange? picked = await showDateRangePicker(
        context: context,
        initialDateRange: dateRange.value,
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
        builder: (context, child) {
          final isDark = AppColors.isDark(context);
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: isDark
                  ? const ColorScheme.dark(
                      primary: Color(0xFF078644),
                      onPrimary: AppColors.white,
                      primaryContainer: Color(0xFF004D25),
                      onPrimaryContainer: AppColors.white,
                      surface: AppColors.surfaceDark,
                      onSurface: AppColors.white,
                      secondary: Color(0xFF078644),
                      onSecondary: AppColors.white,
                    )
                  : const ColorScheme.light(
                      primary: AppColors.primary,
                      onPrimary: AppColors.white,
                      onSurface: AppColors.textLight,
                    ),
            ),
            child: child!,
          );
        },
      );
      if (picked != null && picked != dateRange.value) {
        dateRange.value = picked;
      }
    }

    final selectedRange = dateRange.value;
    final startOfRange = DateTime(
      selectedRange.start.year,
      selectedRange.start.month,
      selectedRange.start.day,
    );
    final endOfRange = DateTime(
      selectedRange.end.year,
      selectedRange.end.month,
      selectedRange.end.day,
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
                icon: Icon(
                  Icons.arrow_back_rounded,
                  color: AppColors.primary,
                  size: AppSizes.r(28),
                ),
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
          showAnalysis.value ? 'Expense Analysis' : 'History',
          style: AppTextStyles.heading(context),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(AppSizes.w12),
        child: Column(
          children: [
            // Sleek, Custom Professional Filter Bar
            HistoryFilterBar(
              dateRange: dateRange,
              selectDateRange: selectDateRange,
              selectedCategory: selectedCategory,
              selectedSubcategory: selectedSubcategory,
              subcategoriesAsync: subcategoriesAsync,
              categoriesList: _categoriesList,
            ),

            Expanded(
              child: transactionsAsync.when(
                data: (transactions) {
                  // 1. Filter by Date Range
                  final dateFiltered = transactions.where((t) {
                    return t.date.isAfter(
                          dateRange.value.start.subtract(
                            const Duration(seconds: 1),
                          ),
                        ) &&
                        t.date.isBefore(
                          dateRange.value.end.add(const Duration(days: 1)),
                        );
                  }).toList();

                  // 2. Filter by Category & Subcategory & Calculate Totals
                  double totalSpent = 0;
                  double totalIncome = 0;
                  final List<TransactionModel> finalFiltered = [];

                  for (var t in dateFiltered) {
                    if (selectedCategory.value == 'All') {
                      final subcategoryMatch =
                          selectedSubcategory.value == 'All' ||
                          t.subcategory == selectedSubcategory.value;
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
                        final categoryMatch =
                            t.category == selectedCategory.value;
                        final subcategoryMatch =
                            selectedSubcategory.value == 'All' ||
                            t.subcategory == selectedSubcategory.value;
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
                        // 1. Check each explicit split against the filter.
                        double splitTotal = 0;
                        int splitIndex = 0;
                        for (var split in t.splits) {
                          splitTotal += split.amount;
                          final categoryMatch =
                              split.category == selectedCategory.value;
                          final subcategoryMatch =
                              selectedSubcategory.value == 'All' ||
                              split.subcategory == selectedSubcategory.value;

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

                        // 2. The remaining amount (parent total − sum of splits) belongs
                        //    to the parent's own category. Check it against the filter too.
                        final remainder = t.amount - splitTotal;
                        if (remainder > 0.01) {
                          final categoryMatch =
                              t.category == selectedCategory.value;
                          final subcategoryMatch =
                              selectedSubcategory.value == 'All' ||
                              t.subcategory == selectedSubcategory.value;
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
                      'No transactions found for this selection',
                    );
                  }

                  return ListView(
                    children: [
                      // Dynamic Summary Card
                      HistorySummaryCard(
                        selectedCategory: selectedCategory.value,
                        selectedSubcategory: selectedSubcategory.value,
                        totalSpent: totalSpent,
                        totalIncome: totalIncome,
                      ),
                      SizedBox(height: AppSizes.h12),

                      // Banner Ad
                      const BannerAdWidget(),
                      SizedBox(height: AppSizes.h12),

                      // Header with Toggle
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            showAnalysis.value
                                ? 'Expense Analysis'
                                : selectedCategory.value == 'All'
                                ? 'All Transactions'
                                : selectedSubcategory.value == 'All'
                                ? '${selectedCategory.value} Transactions'
                                : '${selectedCategory.value} > ${selectedSubcategory.value}',
                            style: AppTextStyles.body(
                              context,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
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

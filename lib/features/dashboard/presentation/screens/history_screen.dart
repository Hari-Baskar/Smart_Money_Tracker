import 'package:smart_money_tracker/core/constants/app_sizes.dart';
import 'package:smart_money_tracker/core/constants/app_colors.dart';
import 'package:smart_money_tracker/core/theme/app_text_styles.dart';
import 'package:smart_money_tracker/core/models/transaction_model.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/providers/transaction_provider.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/providers/subcategory_provider.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/screens/transaction_detail_screen.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/widgets/premium_pie_chart.dart';
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
                      onPrimary: Colors.white,
                      primaryContainer: Color(0xFF004D25),
                      onPrimaryContainer: Colors.white,
                      surface: AppColors.surfaceDark,
                      onSurface: Colors.white,
                      secondary: Color(0xFF078644),
                      onSecondary: Colors.white,
                    )
                  : const ColorScheme.light(
                      primary: AppColors.primary,
                      onPrimary: Colors.white,
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
    final startOfRange = DateTime(selectedRange.start.year, selectedRange.start.month, selectedRange.start.day);
    final endOfRange = DateTime(selectedRange.end.year, selectedRange.end.month, selectedRange.end.day, 23, 59, 59, 999);
    final adjustedRange = DateTimeRange(start: startOfRange, end: endOfRange);

    final transactionsAsync = ref.watch(transactionsInDateRangeProvider(adjustedRange));

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
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
                icon: Icon(
                  Icons.menu_rounded,
                  color: AppColors.primary,
                  size: AppSizes.r(28),
                ),
                onPressed: () => ref.read(mainScaffoldKeyProvider).currentState?.openDrawer(),
              ),
        title: Text(
          showAnalysis.value ? 'Expense Analysis' : 'History',
          style: AppTextStyles.headline(context),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Sleek, Custom Professional Filter Bar
          _buildFilterBar(
            context: context,
            dateRange: dateRange,
            selectDateRange: selectDateRange,
            selectedCategory: selectedCategory,
            selectedSubcategory: selectedSubcategory,
            subcategoriesAsync: subcategoriesAsync,
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
                      final categoryMatch = t.category == selectedCategory.value;
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
                        final categoryMatch = split.category == selectedCategory.value;
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
                        final categoryMatch = t.category == selectedCategory.value;
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
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSizes.w(20),
                    vertical: AppSizes.h(10),
                  ),
                  children: [
                    // Dynamic Summary Card
                    _buildSummaryCard(
                      context,
                      selectedCategory.value,
                      selectedSubcategory.value,
                      totalSpent,
                      totalIncome,
                    ),
                    SizedBox(height: AppSizes.h24),

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
                            fontWeight: FontWeight.bold,
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
                            style: AppTextStyles.small(
                              context,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSizes.h12),
                    if (showAnalysis.value)
                      _buildAnalysisView(context, finalFiltered, analysisType)
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
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    String selectedCategory,
    String selectedSubcategory,
    double totalSpent,
    double totalIncome,
  ) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: AppSizes.h12),
      padding: EdgeInsets.all(AppSizes.r16),
      decoration: BoxDecoration(
        color: AppColors.getSurfaceContainerLowest(context),
        borderRadius: BorderRadius.circular(AppSizes.r20),
        boxShadow: [
          BoxShadow(
            color: AppColors.isDark(context)
                ? Colors.black.withOpacity(0.25)
                : Colors.black.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: AppColors.isDark(context)
              ? Colors.white.withOpacity(0.06)
              : AppColors.primary.withOpacity(0.08),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Today's Spending Card
          Expanded(
            child: Container(
              padding: EdgeInsets.all(AppSizes.r16),
              decoration: BoxDecoration(
                color: AppColors.isDark(context)
                    ? Colors.red.withOpacity(0.06)
                    : const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(AppSizes.r16),
                border: Border.all(
                  color: AppColors.error.withOpacity(
                    AppColors.isDark(context) ? 0.2 : 0.08,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(AppSizes.r8),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.trending_up_rounded,
                          color: AppColors.error,
                          size: AppSizes.r16,
                        ),
                      ),
                      SizedBox(width: AppSizes.w8),
                      Text(
                        'Spending',
                        style: AppTextStyles.small(
                          context,
                          color: AppColors.getTextMuted(context),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppSizes.h12),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '₹${AppColors.formatShortAmount(totalSpent)}',
                      style: AppTextStyles.display(
                        context,
                        color: AppColors.error,
                        fontWeight: FontWeight.bold,
                        fontSize: 20.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: AppSizes.w12),
          // Today's Income Card
          Expanded(
            child: Container(
              padding: EdgeInsets.all(AppSizes.r16),
              decoration: BoxDecoration(
                color: AppColors.isDark(context)
                    ? Colors.green.withOpacity(0.06)
                    : const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(AppSizes.r16),
                border: Border.all(
                  color: AppColors.success.withOpacity(
                    AppColors.isDark(context) ? 0.2 : 0.08,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(AppSizes.r8),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.trending_down_rounded,
                          color: AppColors.success,
                          size: AppSizes.r16,
                        ),
                      ),
                      SizedBox(width: AppSizes.w8),
                      Text(
                        'Income',
                        style: AppTextStyles.small(
                          context,
                          color: AppColors.getTextMuted(context),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppSizes.h12),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '₹${AppColors.formatShortAmount(totalIncome)}',
                      style: AppTextStyles.display(
                        context,
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                        fontSize: 20.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
          padding: EdgeInsets.symmetric(
            vertical: AppSizes.h12,
            horizontal: AppSizes.w8,
          ),
          child: Text(
            dateKey,
            style: AppTextStyles.small(context, color: AppColors.primary),
          ),
        ),
      );
      widgets.addAll(
        grouped[dateKey]!.map((t) => _buildTransactionCard(context, t)),
      );
    }
    return widgets;
  }

  Widget _buildAnalysisView(
    BuildContext context,
    List<TransactionModel> transactions,
    ValueNotifier<String> analysisType,
  ) {
    final isDark = AppColors.isDark(context);
    final isExpense = analysisType.value == 'Expenses';
    
    // Filter transactions based on Expenses / Income
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
                      ? (isDark ? AppColors.primary : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppSizes.r12),
                  boxShadow: isExpense && !isDark
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
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
                        ? (isDark ? Colors.white : AppColors.primary)
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
                      ? (isDark ? AppColors.primary : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppSizes.r12),
                  boxShadow: !isExpense && !isDark
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
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
                        ? (isDark ? Colors.white : AppColors.primary)
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
            margin: EdgeInsets.only(bottom: 12.h),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: AppSizes.cardBorderRadius,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: Colors.transparent),
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
                    color:
                        catTransactions.any(
                          (t) => t.type == TransactionType.credit,
                        )
                        ? Colors.green
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
                            padding: EdgeInsets.symmetric(vertical: 6.h),
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

  Widget _buildTransactionCard(BuildContext context, TransactionModel t) {
    return _ExpandableTransactionCard(
      transaction: t,
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

  Widget _buildFilterBar({
    required BuildContext context,
    required ValueNotifier<DateTimeRange> dateRange,
    required Future<void> Function() selectDateRange,
    required ValueNotifier<String> selectedCategory,
    required ValueNotifier<String> selectedSubcategory,
    required AsyncValue<List<dynamic>> subcategoriesAsync,
  }) {
    final isCategoryActive = selectedCategory.value != 'All';
    final isSubcategoryActive = selectedSubcategory.value != 'All';
    final hasActiveFilters = isCategoryActive || isSubcategoryActive;

    return Container(
      padding: EdgeInsets.symmetric(vertical: AppSizes.h12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: AppSizes.w(20)),
        child: Row(
          children: [
            // Date Filter Chip
            _buildFilterChip(
              context: context,
              label:
                  '${DateFormat('MMM dd').format(dateRange.value.start)} - ${DateFormat('MMM dd').format(dateRange.value.end)}',
              icon: Icons.calendar_today_rounded,
              isActive: true,
              activeBgColor: Theme.of(context).colorScheme.surface,
              activeColor: AppColors.primary,
              onTap: selectDateRange,
            ),
            SizedBox(width: AppSizes.w12),

            // Category Filter Chip
            _buildFilterChip(
              context: context,
              label: selectedCategory.value == 'All'
                  ? 'Category'
                  : selectedCategory.value,
              icon: AppColors.getCategoryIcon(selectedCategory.value),
              isActive: isCategoryActive,
              activeBgColor: AppColors.getCategoryBgColor(
                context,
                selectedCategory.value,
              ),
              activeColor: AppColors.getCategoryColor(selectedCategory.value),
              onTap: () => _showCategoryBottomSheet(
                context,
                selectedCategory,
                subcategoriesAsync.value ?? const [],
              ),
            ),
            SizedBox(width: AppSizes.w12),

            // Subcategory Filter Chip
            _buildFilterChip(
              context: context,
              label: selectedSubcategory.value == 'All'
                  ? 'Subcategory'
                  : selectedSubcategory.value,
              icon: Icons.layers_rounded,
              isActive: isSubcategoryActive,
              isDisabled: !isCategoryActive,
              activeBgColor: AppColors.getCategoryBgColor(
                context,
                selectedCategory.value,
              ),
              activeColor: AppColors.getCategoryColor(selectedCategory.value),
              onTap: () => _showSubcategoryBottomSheet(
                context,
                selectedCategory.value,
                selectedSubcategory,
                subcategoriesAsync,
              ),
            ),

            // Reset Active Filters Chip
            if (hasActiveFilters) ...[
              SizedBox(width: AppSizes.w12),
              _buildResetChip(
                context: context,
                onTap: () {
                  selectedCategory.value = 'All';
                  selectedSubcategory.value = 'All';
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required BuildContext context,
    required String label,
    required IconData icon,
    bool isActive = false,
    bool isDisabled = false,
    Color? activeColor,
    Color? activeBgColor,
    VoidCallback? onTap,
  }) {
    final isDark = AppColors.isDark(context);

    final baseBgColor = isDark
        ? AppColors.surfaceContainerLowestDark
        : AppColors.white;
    final baseBorderColor = isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.black.withOpacity(0.06);
    final baseTextColor = AppColors.getText(context);
    final baseIconColor = AppColors.getTextMuted(context);

    final bg = isDisabled
        ? baseBgColor.withOpacity(0.5)
        : (isActive
              ? (activeBgColor ?? AppColors.primary.withOpacity(0.12))
              : baseBgColor);

    final border = Border.all(
      color: isDisabled
          ? baseBorderColor.withOpacity(0.5)
          : (isActive
                ? (activeColor ?? AppColors.primary).withOpacity(0.3)
                : baseBorderColor),
      width: isActive ? 1.5 : 1.0,
    );

    final textStyle = AppTextStyles.small(
      context,
      color: isDisabled
          ? baseTextColor.withOpacity(0.4)
          : (isActive ? (activeColor ?? AppColors.primary) : baseTextColor),
      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
    );

    final iconColor = isDisabled
        ? baseIconColor.withOpacity(0.4)
        : (isActive ? (activeColor ?? AppColors.primary) : baseIconColor);

    return Opacity(
      opacity: isDisabled ? 0.5 : 1.0,
      child: GestureDetector(
        onTap: isDisabled ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
            horizontal: AppSizes.w16,
            vertical: AppSizes.h(10),
          ),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(100.r),
            border: border,
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: (activeColor ?? AppColors.primary).withOpacity(
                        0.06,
                      ),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: AppSizes.r16, color: iconColor),
              SizedBox(width: AppSizes.w8),
              Text(label, style: textStyle),
              SizedBox(width: AppSizes.w4),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: AppSizes.r16,
                color: iconColor.withOpacity(0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResetChip({
    required BuildContext context,
    required VoidCallback onTap,
  }) {
    final isDark = AppColors.isDark(context);
    final bg = isDark ? Colors.red.withOpacity(0.1) : const Color(0xFFFEE2E2);
    final border = Border.all(color: Colors.red.withOpacity(0.2));
    final textColor = Colors.red[700] ?? Colors.red;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSizes.w12,
          vertical: AppSizes.h(10),
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(100.r),
          border: border,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.restart_alt_rounded,
              size: AppSizes.r16,
              color: textColor,
            ),
            SizedBox(width: AppSizes.w8),
            Text(
              'Reset',
              style: AppTextStyles.small(
                context,
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCategoryBottomSheet(
    BuildContext context,
    ValueNotifier<String> selectedCategory,
    List<dynamic> customSubcategories,
  ) {
    final customCats = customSubcategories.map((s) => s.parentCategory as String).toSet().toList();
    final allCats = [
      ..._categoriesList,
      ...customCats.where((c) => !const ['Food', 'Travel', 'Shopping', 'Bills', 'Groceries', 'Entertainment', 'Health', 'Investment', 'Salary', 'Other', 'Unknown', 'All'].contains(c))
    ].toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final isDark = AppColors.isDark(context);
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
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
                        ? Colors.white.withOpacity(0.12)
                        : Colors.black.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(2.r),
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
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(
                            color: isSelected
                                ? catColor
                                : (isDark
                                      ? Colors.white.withOpacity(0.05)
                                      : Colors.black.withOpacity(0.04)),
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
                                          ? Colors.black.withOpacity(0.2)
                                          : Colors.white)
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
                                    ? (isDark ? Colors.white : catColor)
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
      },
    );
  }

  void _showSubcategoryBottomSheet(
    BuildContext context,
    String activeCategory,
    ValueNotifier<String> selectedSubcategory,
    AsyncValue<List<dynamic>> subcategoriesAsync,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final isDark = AppColors.isDark(context);
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
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
                        ? Colors.white.withOpacity(0.12)
                        : Colors.black.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select Subcategory',
                    style: AppTextStyles.headline(
                      context,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (selectedSubcategory.value != 'All')
                    TextButton(
                      onPressed: () {
                        selectedSubcategory.value = 'All';
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
                child: subcategoriesAsync.when(
                  data: (allSubcategories) {
                    final filtered = allSubcategories
                        .where((s) => s.parentCategory == activeCategory)
                        .map((s) => s.name as String)
                        .toSet()
                        .toList();

                    final sortedSub = filtered..sort();
                    final displaySub = ['All', ...sortedSub];

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const BouncingScrollPhysics(),
                      itemCount: displaySub.length,
                      separatorBuilder: (context, index) => Divider(
                        color: isDark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.black.withOpacity(0.04),
                        height: 1,
                      ),
                      itemBuilder: (context, index) {
                        final sub = displaySub[index];
                        final isSelected = selectedSubcategory.value == sub;
                        final activeCatColor = AppColors.getCategoryColor(
                          activeCategory,
                        );

                        return ListTile(
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: AppSizes.w8,
                            vertical: AppSizes.h4,
                          ),
                          onTap: () {
                            selectedSubcategory.value = sub;
                            Navigator.pop(context);
                          },
                          leading: Container(
                            width: AppSizes.r(36),
                            height: AppSizes.r(36),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? activeCatColor.withOpacity(0.1)
                                  : (isDark
                                        ? AppColors.surfaceContainerLowestDark
                                        : AppColors.backgroundLight),
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: Icon(
                              isSelected
                                  ? Icons.check_circle_rounded
                                  : Icons.circle_outlined,
                              color: isSelected
                                  ? activeCatColor
                                  : AppColors.getTextMuted(
                                      context,
                                    ).withOpacity(0.5),
                              size: AppSizes.r16,
                            ),
                          ),
                          title: Text(
                            sub,
                            style: AppTextStyles.body(
                              context,
                              color: isSelected
                                  ? activeCatColor
                                  : AppColors.getText(context),
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                            ),
                          ),
                          trailing: isSelected
                              ? Icon(
                                  Icons.check_rounded,
                                  color: activeCatColor,
                                  size: AppSizes.r20,
                                )
                              : null,
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, __) => Center(
                    child: Text(
                      'Failed to load subcategories',
                      style: AppTextStyles.body(context),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ExpandableTransactionCard extends StatefulWidget {
  final TransactionModel transaction;
  final VoidCallback onTap;

  const _ExpandableTransactionCard({
    required this.transaction,
    required this.onTap,
  });

  @override
  State<_ExpandableTransactionCard> createState() => _ExpandableTransactionCardState();
}

class _ExpandableTransactionCardState extends State<_ExpandableTransactionCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.transaction;
    final hasSplits = t.splits.isNotEmpty;

    return Container(
      margin: EdgeInsets.only(bottom: AppSizes.h12),
      decoration: BoxDecoration(
        color: AppColors.getSurfaceContainerLowest(context),
        borderRadius: BorderRadius.circular(AppSizes.r16),
        boxShadow: [
          BoxShadow(
            color: AppColors.isDark(context)
                ? Colors.black.withOpacity(0.2)
                : Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: AppColors.isDark(context)
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.03),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: hasSplits
                ? () => setState(() => _isExpanded = !_isExpanded)
                : widget.onTap,
            child: ListTile(
              contentPadding: EdgeInsets.all(AppSizes.r12),
              leading: Container(
                width: AppSizes.r(48),
                height: AppSizes.r(48),
                decoration: BoxDecoration(
                  color: t.type == TransactionType.credit
                      ? AppColors.success.withOpacity(0.12)
                      : AppColors.getCategoryBgColor(context, t.category),
                  borderRadius: BorderRadius.circular(AppSizes.r12),
                ),
                child: Icon(
                  t.type == TransactionType.credit
                      ? Icons.account_balance_wallet_rounded
                      : AppColors.getCategoryIcon(t.category),
                  color: t.type == TransactionType.credit
                      ? AppColors.success
                      : AppColors.getCategoryColor(t.category),
                  size: AppSizes.r24,
                ),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      t.subcategory,
                      style: AppTextStyles.body(
                        context,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: AppSizes.w8),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSizes.w8,
                      vertical: AppSizes.h(2),
                    ),
                    decoration: BoxDecoration(
                      color: hasSplits
                          ? (AppColors.isDark(context)
                              ? AppColors.primary.withOpacity(0.15)
                              : AppColors.primary.withOpacity(0.08))
                          : (AppColors.isDark(context)
                              ? Colors.white.withOpacity(0.06)
                              : AppColors.primary.withOpacity(0.06)),
                      borderRadius: BorderRadius.circular(AppSizes.r(20)),
                      border: hasSplits
                          ? Border.all(color: AppColors.primary.withOpacity(0.3), width: 0.5)
                          : null,
                    ),
                    child: Text(
                      hasSplits ? 'SPLIT' : t.category.toUpperCase(),
                      style: AppTextStyles.small(
                        context,
                        color: hasSplits
                            ? AppColors.primary
                            : AppColors.getTextMuted(context),
                        fontSize: 8.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              subtitle: Padding(
                padding: EdgeInsets.only(top: AppSizes.h4),
                child: Text(
                  t.merchant.trim().isNotEmpty
                      ? "${t.type == TransactionType.credit ? 'From' : 'Payee'}: ${t.merchant} • ${DateFormat('hh:mm a').format(t.date)}"
                      : DateFormat('hh:mm a').format(t.date),
                  style: AppTextStyles.small(
                    context,
                    color: AppColors.getTextMuted(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${t.type == TransactionType.credit ? '+' : '-'}₹${AppColors.formatShortAmount(t.amount)}',
                    style: AppTextStyles.headline(
                      context,
                      color: t.type == TransactionType.credit
                          ? AppColors.success
                          : AppColors.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (hasSplits) ...[
                    SizedBox(width: AppSizes.w4),
                    // Edit icon for split transactions
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: widget.onTap,
                      child: Padding(
                        padding: EdgeInsets.only(left: AppSizes.w(2)),
                        child: Icon(
                          Icons.edit_rounded,
                          color: AppColors.getTextMuted(context).withOpacity(0.5),
                          size: AppSizes.r16,
                        ),
                      ),
                    ),
                    SizedBox(width: AppSizes.w4),
                    Icon(
                      _isExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: AppColors.getTextMuted(context),
                      size: AppSizes.r24,
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (hasSplits)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              child: AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                child: SizedBox(
                  width: double.infinity,
                  child: Column(
                    children: [
                      if (_isExpanded) ...[
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            AppSizes.w16,
                            AppSizes.h8,
                            AppSizes.w16,
                            AppSizes.h12,
                          ),
                          child: Column(
                            children: t.splits.map((split) {
                              final catColor = AppColors.getCategoryColor(split.category);
                              final catBg = AppColors.getCategoryBgColor(context, split.category);
                              final displayCategoryName = split.category.toUpperCase();

                              return Container(
                                margin: EdgeInsets.symmetric(vertical: AppSizes.h4),
                                padding: EdgeInsets.symmetric(
                                  horizontal: AppSizes.w12,
                                  vertical: AppSizes.h8,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.isDark(context)
                                      ? Colors.white.withOpacity(0.02)
                                      : AppColors.primary.withOpacity(0.02),
                                  borderRadius: BorderRadius.circular(AppSizes.r12),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: AppSizes.r(32),
                                      height: AppSizes.r(32),
                                      decoration: BoxDecoration(
                                        color: catBg,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        AppColors.getCategoryIcon(split.category),
                                        color: catColor,
                                        size: AppSizes.r16,
                                      ),
                                    ),
                                    SizedBox(width: AppSizes.w12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            split.subcategory,
                                            style: AppTextStyles.body(
                                              context,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12.sp,
                                            ),
                                          ),
                                          Text(
                                            displayCategoryName,
                                            style: AppTextStyles.small(
                                              context,
                                              color: AppColors.getTextMuted(context),
                                              fontSize: 8.sp,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '₹${AppColors.formatShortAmount(split.amount)}',
                                      style: AppTextStyles.body(
                                        context,
                                        color: t.type == TransactionType.credit
                                            ? AppColors.success
                                            : AppColors.error,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12.sp,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

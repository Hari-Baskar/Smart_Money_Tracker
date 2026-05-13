import 'package:expense_tracker/core/constants/app_colors.dart';
import 'package:expense_tracker/core/theme/app_text_styles.dart';
import 'package:expense_tracker/core/models/transaction_model.dart';
import 'package:expense_tracker/features/dashboard/presentation/providers/transaction_provider.dart';
import 'package:expense_tracker/features/dashboard/presentation/screens/transaction_detail_screen.dart';
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
    'Other',
    'Unknown',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = useState('All');
    final dateRange = useState(DateTimeRange(
      start: DateTime.now().subtract(const Duration(days: 30)),
      end: DateTime.now(),
    ));

    Future<void> selectDateRange() async {
      final DateTimeRange? picked = await showDateRangePicker(
        context: context,
        initialDateRange: dateRange.value,
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: AppColors.primary,
                onPrimary: Colors.white,
                onSurface: AppColors.isDark(context) ? Colors.white : AppColors.textLight,
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

    final transactionsAsync = ref.watch(transactionsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'History',
          style: AppTextStyles.headline(context),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: selectDateRange,
            icon: Icon(
              Icons.date_range_rounded,
              color: AppColors.primary,
              size: 24.r,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Date Range Display
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
            child: InkWell(
              onTap: selectDateRange,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: Theme.of(context).colorScheme.surfaceVariant),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 16.r,
                      color: AppColors.primary,
                    ),
                    SizedBox(width: 12.w),
                    Text(
                      '${DateFormat('MMM dd').format(dateRange.value.start)} - ${DateFormat('MMM dd').format(dateRange.value.end)}',
                      style: AppTextStyles.small(
                        context,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.edit_rounded,
                      size: 14.r,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Category Filter
          SizedBox(
            height: 60.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              itemCount: _categoriesList.length,
              itemBuilder: (context, index) {
                final category = _categoriesList[index];
                final isSelected = selectedCategory.value == category;
                return Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 4.w,
                    vertical: 10.h,
                  ),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (val) {
                      selectedCategory.value = category;
                    },
                    selectedColor: AppColors.primary,
                    checkmarkColor: Colors.white,
                    labelStyle: AppTextStyles.small(
                      context,
                      color: isSelected ? Colors.white : Theme.of(context).colorScheme.onBackground,
                    ),
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    side: BorderSide(
                      color: isSelected
                          ? AppColors.primary
                          : Theme.of(context).colorScheme.surfaceVariant,
                    ),
                  ),
                );
              },
            ),
          ),

          Expanded(
            child: transactionsAsync.when(
              data: (transactions) {
                // 1. Filter by Date Range
                final dateFiltered = transactions.where((t) {
                  return t.date.isAfter(
                        dateRange.value.start.subtract(const Duration(seconds: 1)),
                      ) &&
                      t.date.isBefore(
                        dateRange.value.end.add(const Duration(days: 1)),
                      );
                }).toList();

                // 2. Filter by Category & Calculate Totals
                double selectedTotal = 0;
                final List<TransactionModel> finalFiltered = [];

                for (var t in dateFiltered) {
                  if (selectedCategory.value == 'All' ||
                      t.category == selectedCategory.value) {
                    finalFiltered.add(t);
                    selectedTotal += t.amount;
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
                    horizontal: 20.w,
                    vertical: 10.h,
                  ),
                  children: [
                    // Dynamic Summary Card
                    _buildSummaryCard(context, selectedCategory.value, selectedTotal),
                    SizedBox(height: 24.h),

                    Text(
                      selectedCategory.value == 'All'
                          ? 'All Transactions'
                          : '${selectedCategory.value} Transactions',
                      style: AppTextStyles.body(
                        context,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(height: 12.h),
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

  Widget _buildSummaryCard(BuildContext context, String selectedCategory, double total) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            selectedCategory == 'All'
                ? 'Total Expenses'
                : 'Total $selectedCategory',
            style: AppTextStyles.small(
              context,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            '₹${total.toStringAsFixed(0)}',
            style: AppTextStyles.display(context, color: Colors.white),
          ),
          SizedBox(height: 8.h),
          Text(
            'for selected period',
            style: AppTextStyles.small(
              context,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _groupAndBuildTransactions(BuildContext context, List<TransactionModel> transactions) {
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
          padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
          child: Text(
            dateKey,
            style: AppTextStyles.small(
              context,
              color: AppColors.primary,
            ),
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
            size: 64.r,
            color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
          SizedBox(height: 16.h),
          Text(
            message,
            style: AppTextStyles.body(context, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(BuildContext context, TransactionModel t) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TransactionDetailScreen(transaction: t),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: EdgeInsets.all(12.r),
          leading: Container(
            width: 48.r,
            height: 48.r,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              _getCategoryIcon(t.category),
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              size: 24.r,
            ),
          ),
          title: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Payee  ',
                  style: AppTextStyles.small(
                    context,
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
                  ),
                ),
                TextSpan(
                  text: t.merchant,
                  style: AppTextStyles.body(context),
                ),
              ],
            ),
          ),
          subtitle: Text(
            '${t.category} • ${DateFormat('hh:mm a').format(t.date)}',
            style: AppTextStyles.small(context),
          ),
          trailing: Text(
            '-₹${t.amount.toStringAsFixed(0)}',
            style: AppTextStyles.headline(
              context,
              color: AppColors.error,
            ),
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant_rounded;
      case 'travel':
        return Icons.directions_car_rounded;
      case 'shopping':
        return Icons.shopping_bag_rounded;
      case 'bills':
        return Icons.receipt_long_rounded;
      case 'groceries':
        return Icons.local_grocery_store_rounded;
      case 'entertainment':
        return Icons.movie_rounded;
      case 'health':
        return Icons.medical_services_rounded;
      default:
        return Icons.category_rounded;
    }
  }
}

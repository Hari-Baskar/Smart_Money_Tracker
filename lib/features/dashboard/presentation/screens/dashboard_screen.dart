import 'package:expense_tracker/core/constants/app_colors.dart';
import 'package:expense_tracker/core/theme/app_text_styles.dart';
import 'package:expense_tracker/core/models/transaction_model.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:expense_tracker/features/auth/presentation/providers/auth_provider.dart';
import '../providers/transaction_provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'add_transaction_screen.dart';
import 'transaction_detail_screen.dart';

class DashboardScreen extends HookConsumerWidget {
  const DashboardScreen({super.key});

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

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return AppColors.foodIcon;
      case 'travel':
        return AppColors.travelIcon;
      case 'shopping':
        return AppColors.shoppingIcon;
      default:
        return AppColors.primary;
    }
  }

  Color _getCategoryBgColor(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return AppColors.foodBg;
      case 'travel':
        return AppColors.travelBg;
      case 'shopping':
        return AppColors.shoppingBg;
      default:
        return AppColors.primary.withOpacity(0.1);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(todayTransactionsProvider);
    final nameAsync = ref.watch(userNameProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18.r,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: Icon(
                Icons.person_outline,
                color: AppColors.primary,
                size: 20.r,
              ),
            ),
            SizedBox(width: 12.w),
            Text(
              'Smart Money',
              style: AppTextStyles.headline(
                context,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.notifications_none_rounded,
              color: AppColors.primary,
              size: 24.r,
            ),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(
              Icons.sync_rounded,
              color: AppColors.primary,
              size: 24.r,
            ),
            onPressed: () {
              ref.read(transactionSyncProvider.notifier).sync();
              Fluttertoast.showToast(msg: 'Scanning');
            },
          ),
          IconButton(
            icon: Icon(
              Icons.logout_rounded,
              color: AppColors.primary,
              size: 24.r,
            ),
            onPressed: () async {
              final shouldLogout = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  title: Text('Logout', style: AppTextStyles.headline(context)),
                  content: Text('Are you sure you want to log out?', style: AppTextStyles.body(context)),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text('Cancel', style: AppTextStyles.body(context)),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.error,
                      ),
                      child: Text('Logout', style: AppTextStyles.body(context, color: AppColors.error, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              );

              if (shouldLogout == true) {
                await ref.read(authNotifierProvider.notifier).signOut();
              }
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddTransactionScreen(),
            ),
          );
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          'Add Transaction',
          style: AppTextStyles.small(
            context,
            color: Colors.white,
          ),
        ),
      ),
      body: transactionsAsync.when(
        data: (transactions) {
          final totalSpent = transactions.fold(0.0, (sum, t) => sum + t.amount);

          // Sort transactions by date descending
          final sortedTransactions = List<TransactionModel>.from(transactions)
            ..sort((a, b) => b.date.compareTo(a.date));

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Greeting
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 8.h),
                  child: Text(
                    'Good Evening',
                    style: AppTextStyles.headline(
                      context,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ),

              // Summary Card
              SliverToBoxAdapter(
                child: Container(
                  margin: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 12.h,
                  ),
                  padding: EdgeInsets.all(24.r),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(24.r),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Today\'s Spending',
                            style: AppTextStyles.small(
                              context,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            '₹${NumberFormat('#,##,###').format(totalSpent)}',
                            style: AppTextStyles.display(
                              context,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 12.h),
                          Row(
                            children: [
                              Icon(
                                Icons.trending_up,
                                color: Colors.white,
                                size: 16.r,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                'Spent today',
                                style: AppTextStyles.small(
                                  context,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Positioned(
                        right: -10,
                        top: -10,
                        child: Container(
                          width: 80.r,
                          height: 80.r,
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(20),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Categories Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 12.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Categories',
                        style: AppTextStyles.headline(
                          context,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Categories Grid
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 120.h,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    children: _buildCategorySummaryBoxes(context, transactions),
                  ),
                ),
              ),

              // SMS Disclaimer Banner with Scan Button
              SliverToBoxAdapter(
                child: Consumer(
                  builder: (context, ref, child) {
                    final syncState = ref.watch(transactionSyncProvider);
                    final isSyncing = syncState is AsyncLoading;

                    return Container(
                      margin: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 0),
                      padding: EdgeInsets.all(16.r),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.1),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.sms_outlined,
                                color: AppColors.primary,
                                size: 20.r,
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Text(
                                  'Missing a transaction?',
                                  style: AppTextStyles.body(
                                    context,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'If a recent payment wasn\'t detected, try scanning your SMS inbox again.',
                            style: AppTextStyles.small(
                              context,
                              color: AppColors.textMuted,
                            ),
                          ),
                          SizedBox(height: 12.h),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: isSyncing
                                  ? null
                                  : () => ref
                                        .read(transactionSyncProvider.notifier)
                                        .sync(),
                              icon: isSyncing
                                  ? SizedBox(
                                      width: 16.r,
                                      height: 16.r,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.primary,
                                      ),
                                    )
                                  : const Icon(Icons.search_rounded),
                              label: Text(
                                isSyncing ? 'Scanning...' : 'Scan SMS Now',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary.withOpacity(
                                  0.1,
                                ),
                                foregroundColor: AppColors.primary,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Recent Transactions Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 32.h, 20.w, 12.h),
                  child: Text(
                    'Today\'s Transactions',
                    style: AppTextStyles.headline(
                      context,
                    ),
                  ),
                ),
              ),

              if (transactions.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40.h),
                    child: Center(
                      child: Text(
                        'No transactions for today',
                        style: AppTextStyles.small(context),
                      ),
                    ),
                  ),
                )
              else
                // Transaction List
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildTransactionCard(
                      context,
                      sortedTransactions[index],
                    ),
                    childCount: sortedTransactions.length,
                  ),
                ),

              SliverPadding(padding: EdgeInsets.only(bottom: 100.h)),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildTransactionCard(BuildContext context, TransactionModel t) {
    return Consumer(
      builder: (context, ref, child) {
        return Dismissible(
          key: Key(t.id),
          direction: DismissDirection.endToStart,
          confirmDismiss: (direction) async {
            return await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: Theme.of(context).colorScheme.surface,
                title: Text('Delete Transaction', style: AppTextStyles.headline(context)),
                content: Text(
                  'Are you sure you want to delete this transaction?',
                  style: AppTextStyles.body(context),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text('Cancel', style: AppTextStyles.body(context)),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: TextButton.styleFrom(foregroundColor: AppColors.error),
                    child: Text('Delete', style: AppTextStyles.body(context, color: AppColors.error, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
          onDismissed: (direction) {
            ref.read(transactionSyncProvider.notifier).deleteTransaction(t.id);
            Fluttertoast.showToast(msg: 'Transaction deleted');
          },
          background: Container(
            alignment: Alignment.centerRight,
            padding: EdgeInsets.only(right: 20.w),
            margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: AppColors.error,
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: const Icon(Icons.delete_outline, color: Colors.white),
          ),
          child: InkWell(
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
              margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
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
                          color: AppColors.textMuted.withOpacity(0.5),
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
          ),
        );
      },
    );
  }

  List<Widget> _buildCategorySummaryBoxes(
    BuildContext context,
    List<TransactionModel> transactions,
  ) {
    final Map<String, double> totals = {};
    for (var t in transactions) {
      totals[t.category] = (totals[t.category] ?? 0) + t.amount;
    }

    final categories = totals.keys.toList()
      ..sort((a, b) => totals[b]!.compareTo(totals[a]!));

    if (categories.isEmpty) {
      // Fallback categories for visual if no today transactions
      return [
        _buildCategoryBox(context, 'Food', 0),
        _buildCategoryBox(context, 'Shopping', 0),
        _buildCategoryBox(context, 'Travel', 0),
      ];
    }

    return categories
        .map((cat) => _buildCategoryBox(context, cat, totals[cat]!))
        .toList();
  }

  Widget _buildCategoryBox(
    BuildContext context,
    String category,
    double amount,
  ) {
    return Container(
      width: 130.w,
      margin: EdgeInsets.only(right: 12.w),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: _getCategoryBgColor(category),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getCategoryIcon(category),
              color: _getCategoryColor(category),
              size: 20.r,
            ),
          ),
          const Spacer(),
          Text(
            category,
            style: AppTextStyles.small(context),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '₹${amount.toStringAsFixed(0)}',
            style: AppTextStyles.headline(context),
          ),
        ],
      ),
    );
  }
}

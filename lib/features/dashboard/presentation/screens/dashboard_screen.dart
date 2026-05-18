import 'package:smart_money_tracker/core/constants/app_sizes.dart';
import 'package:smart_money_tracker/core/constants/app_colors.dart';
import 'package:smart_money_tracker/core/theme/app_text_styles.dart';
import 'package:smart_money_tracker/core/models/transaction_model.dart';
import 'package:smart_money_tracker/features/main/presentation/widgets/app_drawer.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:smart_money_tracker/features/auth/presentation/providers/auth_provider.dart';
import '../providers/transaction_provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'add_transaction_screen.dart';
import 'transaction_detail_screen.dart';
import 'package:smart_money_tracker/core/services/update_service.dart';
import 'package:smart_money_tracker/core/common/widgets/update_dialog.dart';
import 'package:smart_money_tracker/core/common/widgets/banner_ad_widget.dart';

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

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return 'Good Morning';
    } else if (hour >= 12 && hour < 17) {
      return 'Good Afternoon';
    } else if (hour >= 17 && hour < 21) {
      return 'Good Evening';
    } else {
      return 'Good Night';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen for updates
    ref.listen(updateProvider, (previous, next) {
      next.when(
        data: (state) {
          if (state.status != UpdateStatus.none && state.config != null) {
            showDialog(
              context: context,
              barrierDismissible: state.status != UpdateStatus.mandatory,
              builder: (context) => UpdateDialog(
                currentVersion: state.currentVersion,
                newVersion: state.status == UpdateStatus.mandatory
                    ? state.config!.minVersion
                    : state.config!.maxVersion,
                isMandatory: state.status == UpdateStatus.mandatory,
                releaseNotes: state.config!.releaseNotes,
                updateUrl: state.config!.updateUrl,
              ),
            );
          }
        },
        error: (err, stack) {
          debugPrint('Update Check Error: $err');
          // Silent failure for updates to avoid annoying the user,
          // but logged for debugging.
        },
        loading: () => debugPrint('Checking for updates...'),
      );
    });

    final transactionsAsync = ref.watch(todayTransactionsProvider);
    final userProfileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      drawer: const AppDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(
              Icons.menu_rounded,
              color: AppColors.isDark(context)
                  ? AppColors.getText(context)
                  : AppColors.primary,
              size: 28.r,
            ),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text(
          'Smart Money',
          style: AppTextStyles.headline(
            context,
            color: AppColors.isDark(context)
                ? AppColors.getText(context)
                : AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.notifications_none_rounded,
              color: AppColors.isDark(context)
                  ? AppColors.getText(context)
                  : AppColors.primary,
              size: 24.r,
            ),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(
              Icons.sync_rounded,
              color: AppColors.isDark(context)
                  ? AppColors.getText(context)
                  : AppColors.primary,
              size: 24.r,
            ),
            onPressed: () {
              ref.read(transactionSyncProvider.notifier).sync();
              Fluttertoast.showToast(msg: 'Scanning');
            },
          ),
          SizedBox(width: 8.w),
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
          style: AppTextStyles.small(context, color: Colors.white),
        ),
      ),
      body: transactionsAsync.when(
        data: (transactions) {
          final totalSpent = transactions
              .where((t) => t.type == TransactionType.debit)
              .fold(0.0, (sum, t) => sum + t.amount);

          final totalIncome = transactions
              .where((t) => t.type == TransactionType.credit)
              .fold(0.0, (sum, t) => sum + t.amount);

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
                    _getGreeting(),
                    style: AppTextStyles.headline(
                      context,
                      color: AppColors.getTextMuted(context),
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
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: AppSizes.cardBorderRadius,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.05),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Today\'s Spending',
                                style: AppTextStyles.small(
                                  context,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                totalSpent >= 1000
                                    ? '₹${(totalSpent / 1000).toStringAsFixed(1)}K'
                                    : '₹${NumberFormat('#,###').format(totalSpent)}',
                                style: AppTextStyles.display(
                                  context,
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 18.sp, // Reduced from 26.sp
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Today\'s Income',
                                style: AppTextStyles.small(
                                  context,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                totalIncome >= 1000
                                    ? '₹${(totalIncome / 1000).toStringAsFixed(1)}K'
                                    : '₹${NumberFormat('#,###').format(totalIncome)}',
                                style: AppTextStyles.display(
                                  context,
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 18.sp, // Reduced from 26.sp
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 16.h),
                      Divider(
                        color: Theme.of(
                          context,
                        ).colorScheme.outlineVariant.withOpacity(0.5),
                        height: 1,
                      ),
                      SizedBox(height: 16.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.trending_up,
                                color: AppColors.error.withOpacity(0.8),
                                size: 16.r,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                'Spent today',
                                style: AppTextStyles.small(
                                  context,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Icon(
                                Icons.trending_down,
                                color: AppColors.success.withOpacity(0.8),
                                size: 16.r,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                'Income today',
                                style: AppTextStyles.small(
                                  context,
                                  color: AppColors.getTextMuted(context),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
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
                        borderRadius: AppSizes.cardBorderRadius,
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
                                  style: AppTextStyles.body(context),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'If a recent payment wasn\'t detected, try scanning your SMS inbox again. Note: Encrypted RCS messages cannot be detected due to system privacy.',
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
                                  borderRadius: AppSizes.cardBorderRadius,
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

              // Banner Ad
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                  child: const BannerAdWidget(),
                ),
              ),

              // Recent Transactions Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 32.h, 20.w, 12.h),
                  child: Text(
                    'Today\'s Transactions',
                    style: AppTextStyles.headline(context),
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
                title: Text(
                  'Delete Transaction',
                  style: AppTextStyles.headline(context),
                ),
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
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.error,
                    ),
                    child: Text(
                      'Delete',
                      style: AppTextStyles.body(
                        context,
                        color: AppColors.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TransactionDetailScreen(transaction: t),
                ),
              );
            },
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
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
              child: ListTile(
                contentPadding: EdgeInsets.all(12.r),
                leading: Container(
                  width: 48.r,
                  height: 48.r,
                  decoration: BoxDecoration(
                    color: t.type == TransactionType.credit
                        ? Colors.green.withOpacity(0.1)
                        : Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    t.type == TransactionType.credit
                        ? Icons.account_balance_wallet_rounded
                        : _getCategoryIcon(t.category),
                    color: t.type == TransactionType.credit
                        ? Colors.green
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    size: 24.r,
                  ),
                ),
                title: Text(
                  '${t.subcategory} (${t.category})',
                  style: AppTextStyles.body(
                    context,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  "${t.type == TransactionType.credit ? 'From' : 'Payee'}: ${t.merchant} • ${DateFormat('hh:mm a').format(t.date)}",
                  style: AppTextStyles.small(context),
                ),
                trailing: Text(
                  '${t.type == TransactionType.credit ? '+' : '-'}₹${t.amount.toStringAsFixed(0)}',
                  style: AppTextStyles.headline(
                    context,
                    color: t.type == TransactionType.credit
                        ? Colors.green
                        : AppColors.error,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

}

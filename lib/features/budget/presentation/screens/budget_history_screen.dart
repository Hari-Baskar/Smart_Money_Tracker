import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_money_tracker/core/constants/app_colors.dart';
import 'package:smart_money_tracker/core/constants/app_sizes.dart';
import 'package:smart_money_tracker/core/constants/app_routes.dart';
import 'package:smart_money_tracker/core/theme/app_text_styles.dart';
import 'package:smart_money_tracker/core/models/transaction_model.dart';
import 'package:smart_money_tracker/core/common/widgets/modal_action_sheet.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/widgets/expandable_transaction_card.dart';
import 'package:intl/intl.dart';

enum TransactionViewMode {
  daily,
  weekly,
  monthly,
}

class BudgetHistoryScreen extends HookConsumerWidget {
  final List<TransactionModel> transactions;
  final String budgetName;

  const BudgetHistoryScreen({
    super.key,
    required this.transactions,
    required this.budgetName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewMode = useState<TransactionViewMode>(TransactionViewMode.daily);

    final listItems = transactions.isEmpty
        ? <Widget>[]
        : _groupAndBuildTransactions(context, transactions, viewMode.value);

    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AppBar(
        title: Text(
          budgetName.isNotEmpty ? '$budgetName Transactions' : 'Transactions',
          style: AppTextStyles.subHeading(context),
        ),
        centerTitle: true,
        backgroundColor: AppColors.getBackground(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: AppColors.getText(context),
            size: AppSizes.r20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (transactions.isNotEmpty)
            IconButton(
              icon: Icon(
                Icons.more_vert_rounded,
                color: AppColors.getText(context),
                size: AppSizes.r24,
              ),
              onPressed: () => _showViewModeModal(context, viewMode),
            ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          if (transactions.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: AppSizes.r(64),
                      color: AppColors.getTextMuted(context).withValues(alpha: 0.5),
                    ),
                    SizedBox(height: AppSizes.h16),
                    Text(
                      'No transactions',
                      style: AppTextStyles.heading(
                        context,
                        color: AppColors.getTextMuted(context),
                      ),
                    ),
                    SizedBox(height: AppSizes.h(200)),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: EdgeInsets.symmetric(vertical: AppSizes.h12),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => listItems[index],
                  childCount: listItems.length,
                ),
              ),
            ),
          SliverToBoxAdapter(child: SizedBox(height: AppSizes.h32)),
        ],
      ),
    );
  }

  void _showViewModeModal(
    BuildContext context,
    ValueNotifier<TransactionViewMode> viewMode,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.transparent,
      builder: (modalContext) {
        return ModalActionSheet(
          children: [
            _buildViewModeItem(
              context: modalContext,
              title: 'Daily',
              isSelected: viewMode.value == TransactionViewMode.daily,
              onTap: () {
                viewMode.value = TransactionViewMode.daily;
                Navigator.pop(modalContext);
              },
            ),
            _buildViewModeItem(
              context: modalContext,
              title: 'Weekly',
              isSelected: viewMode.value == TransactionViewMode.weekly,
              onTap: () {
                viewMode.value = TransactionViewMode.weekly;
                Navigator.pop(modalContext);
              },
            ),
            _buildViewModeItem(
              context: modalContext,
              title: 'Monthly',
              isSelected: viewMode.value == TransactionViewMode.monthly,
              onTap: () {
                viewMode.value = TransactionViewMode.monthly;
                Navigator.pop(modalContext);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildViewModeItem({
    required BuildContext context,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.r12),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSizes.w16,
            vertical: AppSizes.h12,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.body(context).copyWith(
                    color: AppColors.getText(context),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
              Container(
                width: AppSizes.r20,
                height: AppSizes.r20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? AppColors.getText(context)
                        : AppColors.getTextMuted(context).withValues(alpha: 0.35),
                    width: isSelected ? 5.5 : 1.8,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _groupAndBuildTransactions(
    BuildContext context,
    List<TransactionModel> txns,
    TransactionViewMode mode,
  ) {
    final sortedTransactions = List<TransactionModel>.from(txns)
      ..sort((a, b) => b.date.compareTo(a.date));

    final Map<DateTime, List<TransactionModel>> grouped = {};

    for (var t in sortedTransactions) {
      DateTime key;
      if (mode == TransactionViewMode.daily) {
        key = DateTime(t.date.year, t.date.month, t.date.day);
      } else if (mode == TransactionViewMode.weekly) {
        final dateOnly = DateTime(t.date.year, t.date.month, t.date.day);
        key = dateOnly.subtract(Duration(days: dateOnly.weekday - 1)); // Monday
      } else {
        key = DateTime(t.date.year, t.date.month, 1); // 1st of month
      }

      if (!grouped.containsKey(key)) {
        grouped[key] = [];
      }
      grouped[key]!.add(t);
    }

    List<Widget> widgets = [];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final currentWeekStart = today.subtract(Duration(days: today.weekday - 1));
    final lastWeekStart = currentWeekStart.subtract(const Duration(days: 7));
    final currentMonthStart = DateTime(now.year, now.month, 1);
    final lastMonthStart = DateTime(now.year, now.month - 1, 1);

    for (var groupKey in grouped.keys) {
      String headerTitle = '';
      String summarySubtitle = 'Transaction summary';

      if (mode == TransactionViewMode.daily) {
        if (groupKey == today) {
          headerTitle = 'Today';
        } else if (groupKey == yesterday) {
          headerTitle = 'Yesterday';
        } else {
          headerTitle = DateFormat('MMMM dd, yyyy').format(groupKey);
        }
        summarySubtitle = 'Daily transaction summary';
      } else if (mode == TransactionViewMode.weekly) {
        final weekEnd = groupKey.add(const Duration(days: 6));
        String rangeStr;
        if (groupKey.year == weekEnd.year) {
          if (groupKey.month == weekEnd.month) {
            rangeStr =
                '${DateFormat('MMM dd').format(groupKey)} - ${DateFormat('dd, yyyy').format(weekEnd)}';
          } else {
            rangeStr =
                '${DateFormat('MMM dd').format(groupKey)} - ${DateFormat('MMM dd, yyyy').format(weekEnd)}';
          }
        } else {
          rangeStr =
              '${DateFormat('MMM dd, yyyy').format(groupKey)} - ${DateFormat('MMM dd, yyyy').format(weekEnd)}';
        }

        if (groupKey == currentWeekStart) {
          headerTitle = 'This Week ($rangeStr)';
        } else if (groupKey == lastWeekStart) {
          headerTitle = 'Last Week ($rangeStr)';
        } else {
          headerTitle = rangeStr;
        }
        summarySubtitle = 'Weekly transaction summary';
      } else {
        final monthStr = DateFormat('MMMM yyyy').format(groupKey);
        if (groupKey == currentMonthStart) {
          headerTitle = 'This Month ($monthStr)';
        } else if (groupKey == lastMonthStart) {
          headerTitle = 'Last Month ($monthStr)';
        } else {
          headerTitle = monthStr;
        }
        summarySubtitle = 'Monthly transaction summary';
      }

      final transactionsForGroup = grouped[groupKey]!;

      double groupIncome = 0;
      double groupExpense = 0;
      int creditCount = 0;
      int debitCount = 0;
      for (var t in transactionsForGroup) {
        if (t.type == TransactionType.credit) {
          groupIncome += t.amount;
          creditCount++;
        } else {
          groupExpense += t.amount;
          debitCount++;
        }
      }

      widgets.add(
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            showModalBottomSheet(
              context: context,
              backgroundColor: AppColors.transparent,
              isScrollControlled: true,
              builder: (modalContext) {
                final isDark = AppColors.isDark(modalContext);
                return Container(
                  padding: EdgeInsets.fromLTRB(
                    AppSizes.w24,
                    AppSizes.h12,
                    AppSizes.w24,
                    AppSizes.h24,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : AppColors.white,
                    borderRadius: AppSizes.boxBorderRadius,
                  ),
                  child: SafeArea(
                    top: false,
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
                                  ? AppColors.white.withValues(alpha: 0.12)
                                  : AppColors.black.withValues(alpha: 0.08),
                              borderRadius: AppSizes.boxBorderRadius,
                            ),
                          ),
                        ),
                        Text(
                          headerTitle,
                          style: AppTextStyles.subHeading(modalContext),
                        ),
                        SizedBox(height: AppSizes.h4),
                        Text(
                          summarySubtitle,
                          style: AppTextStyles.body(modalContext).copyWith(
                            color: AppColors.getTextMuted(modalContext),
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: AppSizes.h24),
                        Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Total Credit',
                                      style: AppTextStyles.body(modalContext)
                                          .copyWith(
                                            color: AppColors.getTextMuted(
                                              modalContext,
                                            ),
                                          ),
                                    ),
                                    SizedBox(height: AppSizes.h4),
                                    Text(
                                      '$creditCount transaction${creditCount == 1 ? '' : 's'}',
                                      style: AppTextStyles.small(
                                        modalContext,
                                        color: AppColors.getTextMuted(
                                          modalContext,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  '₹${AppColors.formatShortAmount(groupIncome)}',
                                  style: AppTextStyles.body(modalContext)
                                      .copyWith(
                                        color: AppColors.success,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                              ],
                            ),
                            SizedBox(height: AppSizes.h16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Total Debit',
                                      style: AppTextStyles.body(modalContext)
                                          .copyWith(
                                            color: AppColors.getTextMuted(
                                              modalContext,
                                            ),
                                          ),
                                    ),
                                    SizedBox(height: AppSizes.h4),
                                    Text(
                                      '$debitCount transaction${debitCount == 1 ? '' : 's'}',
                                      style: AppTextStyles.small(
                                        modalContext,
                                        color: AppColors.getTextMuted(
                                          modalContext,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  '₹${AppColors.formatShortAmount(groupExpense)}',
                                  style: AppTextStyles.body(modalContext)
                                      .copyWith(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppSizes.w16,
              vertical: AppSizes.h12,
            ),
            decoration: BoxDecoration(
              color: AppColors.isDark(context)
                  ? AppColors.getSurfaceContainerLowest(context)
                  : const Color(0xFFF7F7F7),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    headerTitle,
                    style: AppTextStyles.heading(
                      context,
                      fontSize: 14,
                      color: AppColors.getText(context),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${transactionsForGroup.length} txn${transactionsForGroup.length == 1 ? '' : 's'}',
                      style: AppTextStyles.small(context).copyWith(
                        color: AppColors.getTextMuted(context),
                      ),
                    ),
                    SizedBox(width: AppSizes.w8),
                    Icon(
                      Icons.info_outline_rounded,
                      size: AppSizes.r16,
                      color: AppColors.getTextMuted(context).withValues(alpha: 0.5),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      for (int i = 0; i < transactionsForGroup.length; i++) {
        final txn = transactionsForGroup[i];
        final isLast = i == transactionsForGroup.length - 1;

        widgets.add(
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSizes.w12),
            child: ExpandableTransactionCard(
              transaction: txn,
              isGrouped: true,
              margin: EdgeInsets.only(bottom: isLast ? 0 : AppSizes.h4),
              onTap: () {
                context.push(AppRoutes.transactionDetail, extra: txn);
              },
            ),
          ),
        );
      }
    }
    return widgets;
  }
}

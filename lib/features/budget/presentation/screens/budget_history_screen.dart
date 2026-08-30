import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_money_tracker/core/constants/app_colors.dart';
import 'package:smart_money_tracker/core/constants/app_sizes.dart';
import 'package:smart_money_tracker/core/constants/app_routes.dart';
import 'package:smart_money_tracker/core/theme/app_text_styles.dart';
import 'package:smart_money_tracker/core/models/transaction_model.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/widgets/expandable_transaction_card.dart';
import 'package:intl/intl.dart';

class BudgetHistoryScreen extends ConsumerWidget {
  final List<TransactionModel> transactions;
  final String budgetName;

  const BudgetHistoryScreen({
    Key? key,
    required this.transactions,
    required this.budgetName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listItems = transactions.isEmpty ? <Widget>[] : _groupAndBuildTransactions(context, transactions);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Text(budgetName.isNotEmpty ? '$budgetName Transactions' : 'Transactions', style: AppTextStyles.subHeading(context)),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Theme.of(context).colorScheme.onBackground,
            size: AppSizes.r20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
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
                      color: AppColors.getTextMuted(context).withOpacity(0.5),
                    ),
                    SizedBox(height: AppSizes.h16),
                    Text(
                      'No transactions',
                      style: AppTextStyles.heading(
                        context,
                        color: AppColors.getTextMuted(context),
                      ),
                    ),
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

  List<Widget> _groupAndBuildTransactions(
    BuildContext context,
    List<TransactionModel> txns,
  ) {
    final sortedTransactions = List<TransactionModel>.from(txns)
      ..sort((a, b) => b.date.compareTo(a.date));

    final Map<DateTime, List<TransactionModel>> grouped = {};
    for (var t in sortedTransactions) {
      final dateOnly = DateTime(t.date.year, t.date.month, t.date.day);
      if (!grouped.containsKey(dateOnly)) {
        grouped[dateOnly] = [];
      }
      grouped[dateOnly]!.add(t);
    }

    List<Widget> widgets = [];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (var date in grouped.keys) {
      String topDateStr = DateFormat('yyyy').format(date);
      String bottomDateStr = DateFormat('MMMM dd').format(date);
      Color topColor = AppColors.getTextMuted(context);
      Color bottomColor = AppColors.getText(context);

      if (date == today) {
        bottomDateStr = 'Today';
      } else if (date == yesterday) {
        bottomDateStr = 'Yesterday';
      }

      final transactionsForDay = grouped[date]!;

      double dailyIncome = 0;
      double dailyExpense = 0;
      int creditCount = 0;
      int debitCount = 0;
      for (var t in transactionsForDay) {
        if (t.type == TransactionType.credit) {
          dailyIncome += t.amount;
          creditCount++;
        } else {
          dailyExpense += t.amount;
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
                final headerText =
                    bottomDateStr == 'Today' || bottomDateStr == 'Yesterday'
                    ? bottomDateStr
                    : '$bottomDateStr, $topDateStr';
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
                                  ? AppColors.white.withOpacity(0.12)
                                  : AppColors.black.withOpacity(0.08),
                              borderRadius: AppSizes.boxBorderRadius,
                            ),
                          ),
                        ),
                        Text(
                          headerText,
                          style: AppTextStyles.subHeading(modalContext),
                        ),
                        SizedBox(height: AppSizes.h4),
                        Text(
                          'Transaction summary',
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
                                  '₹${AppColors.formatShortAmount(dailyIncome)}',
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
                                  '₹${AppColors.formatShortAmount(dailyExpense)}',
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
                Text(
                  bottomDateStr == 'Today' || bottomDateStr == 'Yesterday'
                      ? bottomDateStr
                      : '$bottomDateStr, $topDateStr',
                  style: AppTextStyles.heading(
                    context,
                    fontSize: 14,
                    color: bottomColor,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                Icon(
                  Icons.info_outline_rounded,
                  size: AppSizes.r16,
                  color: AppColors.getTextMuted(context).withOpacity(0.5),
                ),
              ],
            ),
          ),
        ),
      );

      for (int i = 0; i < transactionsForDay.length; i++) {
        final txn = transactionsForDay[i];
        final isLast = i == transactionsForDay.length - 1;

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

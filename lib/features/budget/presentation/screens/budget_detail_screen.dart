import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_money_tracker/core/constants/app_colors.dart';
import 'package:smart_money_tracker/core/constants/app_sizes.dart';
import 'package:smart_money_tracker/core/constants/app_routes.dart';
import 'package:smart_money_tracker/core/theme/app_text_styles.dart';
import 'package:smart_money_tracker/core/utils/app_toast.dart';
import 'package:smart_money_tracker/features/auth/presentation/providers/auth_provider.dart';
import 'package:smart_money_tracker/features/budget/domain/providers/budget_providers.dart';
import 'package:smart_money_tracker/features/budget/presentation/widgets/budget_progress_card.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/widgets/expandable_transaction_card.dart';
import 'package:smart_money_tracker/core/models/transaction_model.dart';
import 'package:intl/intl.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/providers/subcategory_provider.dart';
import 'package:smart_money_tracker/core/common/widgets/banner_ad_widget.dart';
import 'package:smart_money_tracker/core/common/widgets/category_icon_widget.dart';
import 'package:smart_money_tracker/core/common/widgets/primary_button.dart';
import 'package:smart_money_tracker/core/common/widgets/delete_budget_bottom_sheet.dart';
import 'package:smart_money_tracker/core/common/widgets/stop_budget_bottom_sheet.dart';

class BudgetDetailScreen extends ConsumerWidget {
  final BudgetProgress initialProgress;

  const BudgetDetailScreen({Key? key, required this.initialProgress})
    : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch for updates to this specific budget
    final budgetProgressList = ref.watch(budgetProgressProvider);
    final progress = budgetProgressList.firstWhere(
      (p) => p.budget.id == initialProgress.budget.id,
      orElse: () => initialProgress,
    );

    // Format Date Range
    String dateRange = '';
    if (progress.periodStart != null && progress.periodEnd != null) {
      final startStr = DateFormat('MMM d, yyyy').format(progress.periodStart!);
      final endStr = DateFormat('MMM d, yyyy').format(progress.periodEnd!);
      dateRange = '$startStr - $endStr';
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Text('Budget Details', style: AppTextStyles.subHeading(context)),
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
        actions: [
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              color: Theme.of(context).colorScheme.onBackground,
            ),
            onSelected: (value) async {
              if (value == 'edit') {
                context.push(AppRoutes.createBudget, extra: progress.budget);
              } else if (value == 'stop') {
                final shouldStop = await showStopBudgetBottomSheet(context);
                if (shouldStop == true) {
                  final user = ref.read(authStateProvider).value;
                  if (user != null) {
                    final now = DateTime.now();
                    DateTime? newEndDate = now;
                    if (progress.budget.endDate != null &&
                        progress.budget.endDate!.isBefore(now)) {
                      newEndDate = progress.budget.endDate;
                    }
                    final updatedBudget = progress.budget.copyWith(
                      isStopped: true,
                      endDate: newEndDate,
                    );
                    await ref
                        .read(budgetRepositoryProvider)
                        .saveBudget(user.id, updatedBudget);
                    if (context.mounted) {
                      AppToast.show(context, 'Budget stopped');
                    }
                  }
                }
              } else if (value == 'delete') {
                final shouldDelete = await showDeleteBudgetBottomSheet(context);
                if (shouldDelete == true) {
                  final user = ref.read(authStateProvider).value;
                  if (user != null) {
                    await ref
                        .read(budgetRepositoryProvider)
                        .deleteBudget(user.id, progress.budget.id!);
                    if (context.mounted) {
                      context.pop();
                      AppToast.show(context, 'Budget deleted');
                    }
                  }
                }
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              if (!progress.budget.isStopped) ...[
                PopupMenuItem<String>(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(
                        Icons.edit_outlined,
                        size: AppSizes.r20,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: AppSizes.w12),
                      Text('Edit', style: AppTextStyles.body(context)),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'stop',
                  child: Row(
                    children: [
                      Icon(
                        Icons.stop_circle_outlined,
                        size: AppSizes.r20,
                        color: AppColors.warning,
                      ),
                      SizedBox(width: AppSizes.w12),
                      Text(
                        'Stop',
                        style: AppTextStyles.body(
                          context,
                        ).copyWith(color: AppColors.warning),
                      ),
                    ],
                  ),
                ),
              ],
              PopupMenuItem<String>(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_outline,
                      size: AppSizes.r20,
                      color: AppColors.error,
                    ),
                    SizedBox(width: AppSizes.w12),
                    Text(
                      'Delete',
                      style: AppTextStyles.body(
                        context,
                      ).copyWith(color: AppColors.error),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              children: [
                SizedBox(height: AppSizes.h16),
                _buildDetailsSection(context, ref, progress, dateRange),
                SizedBox(height: AppSizes.h12),
                const BannerAdWidget(),
                SizedBox(height: AppSizes.h12),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSizes.w16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Transactions',
                    style: AppTextStyles.subHeading(context),
                  ),
                  if (progress.transactions.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        context.push(
                          AppRoutes.budgetHistory,
                          extra: {
                            'transactions': progress.transactions,
                            'budgetName': progress.budget.name.isNotEmpty
                                ? progress.budget.name
                                : 'Budget',
                          },
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'View All',
                            style: AppTextStyles.body(
                              context,
                              color: AppColors.primary,
                            ).copyWith(fontWeight: FontWeight.w600),
                          ),
                          SizedBox(width: AppSizes.w4),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: AppSizes.r12,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (progress.transactions.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: AppSizes.h32),
                    Icon(
                      Icons.receipt_long_outlined,
                      size: AppSizes.r(64),
                      color: AppColors.getTextMuted(context).withOpacity(0.5),
                    ),
                    SizedBox(height: AppSizes.h16),
                    Text(
                      'No transactions yet',
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
              padding: EdgeInsets.only(top: AppSizes.h8),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final txn = progress.transactions[index];
                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppSizes.w16),
                      child: ExpandableTransactionCard(
                        transaction: txn,
                        isGrouped: false,
                        onTap: () {
                          context.push(AppRoutes.transactionDetail, extra: txn);
                        },
                      ),
                    );
                  },
                  childCount: progress.transactions.length > 5
                      ? 5
                      : progress.transactions.length,
                ),
              ),
            ),
          SliverToBoxAdapter(child: SizedBox(height: AppSizes.h64)),
        ],
      ),
    );
  }

  Widget _buildDetailsSection(
    BuildContext context,
    WidgetRef ref,
    BudgetProgress progress,
    String dateRange,
  ) {
    int? daysLeft;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (progress.isCompleted) {
      daysLeft = 0;
    } else if (progress.periodEnd != null) {
      final end = DateTime(
        progress.periodEnd!.year,
        progress.periodEnd!.month,
        progress.periodEnd!.day,
      );
      daysLeft = end.difference(today).inDays + 1;
      if (daysLeft < 0) daysLeft = 0;
    }

    final periodName = progress.budget.period.name;
    final displayPeriod =
        '${periodName[0].toUpperCase()}${periodName.substring(1)}';

    final categoriesAsync = ref.watch(categoriesProvider);
    final categories = categoriesAsync.value ?? [];

    dynamic categoryModel;
    if (progress.budget.categoryId != null) {
      try {
        categoryModel = categories.firstWhere(
          (c) =>
              c.id == progress.budget.categoryId ||
              c.name.toLowerCase() == progress.budget.categoryId!.toLowerCase(),
        );
      } catch (_) {}
    }
    final resolvedCategoryName =
        categoryModel?.name ?? progress.budget.categoryId;
    final displayCategory = resolvedCategoryName != null
        ? '${resolvedCategoryName[0].toUpperCase()}${resolvedCategoryName.substring(1)}'
        : 'All Categories';

    final budgetName =
        (progress.budget.name.isNotEmpty &&
            progress.budget.name != 'Budget' &&
            progress.budget.name != 'Category Budget' &&
            progress.budget.name != 'Overall Budget')
        ? progress.budget.name
        : (progress.budget.categoryId != null
              ? '$displayCategory Budget'
              : 'Overall Budget');

    final statusText = progress.budget.isStopped
        ? 'Stopped'
        : progress.isCompleted
        ? 'Completed'
        : 'Active';
    final statusColor = progress.budget.isStopped
        ? AppColors.error
        : progress.isCompleted
        ? AppColors.primary
        : AppColors.success;

    final categoryColor = progress.budget.categoryId != null
        ? AppColors.getCategoryColor(progress.budget.categoryId!)
        : AppColors.warning;

    Color progressColor = categoryColor;
    if (progress.percentage >= 1.0) {
      progressColor = AppColors.error;
    } else if (progress.percentage >= 0.8) {
      progressColor = AppColors.warning;
    }

    final percentageText = '${(progress.percentage * 100).toStringAsFixed(0)}%';

    final formatExactCurrency = NumberFormat.currency(
      locale: 'en_US',
      symbol: '₹',
      decimalDigits: 0,
    );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSizes.w16),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: AppSizes.cardBorderRadius,
          border: AppColors.isDark(context)
              ? null
              : Border.all(color: AppColors.black.withOpacity(0.08)),
          boxShadow: AppColors.isDark(context)
              ? null
              : [
                  BoxShadow(
                    color: AppColors.black.withOpacity(0.03),
                    blurRadius: 16,
                    spreadRadius: 0,
                    offset: Offset.zero,
                  ),
                ],
        ),
        child: Column(
          children: [
            _buildDetailRow(
              context,
              icon: Icons.label_outline_rounded,
              label: 'Budget Name',
              value: budgetName,
            ),
            Divider(
              height: 1,
              color: AppColors.getTextMuted(context).withOpacity(0.2),
            ),
            _buildDetailRow(
              context,
              icon: Icons.info_outline_rounded,
              label: 'Status',
              value: statusText,
              valueColor: statusColor,
            ),
            Divider(
              height: 1,
              color: AppColors.getTextMuted(context).withOpacity(0.2),
            ),
            _buildDetailRow(
              context,
              icon: Icons.data_usage_rounded,
              label: 'Used',
              value: percentageText,
              valueColor: progressColor,
            ),
            Divider(
              height: 1,
              color: AppColors.getTextMuted(context).withOpacity(0.2),
            ),
            _buildDetailRow(
              context,
              icon: Icons.account_balance_wallet_rounded,
              label: 'Total Budget',
              value: formatExactCurrency.format(progress.budget.amount),
            ),
            Divider(
              height: 1,
              color: AppColors.getTextMuted(context).withOpacity(0.2),
            ),
            _buildDetailRow(
              context,
              icon: Icons.shopping_bag_outlined,
              label: 'Spent',
              value: formatExactCurrency.format(progress.spent),
            ),
            Divider(
              height: 1,
              color: AppColors.getTextMuted(context).withOpacity(0.2),
            ),
            _buildDetailRow(
              context,
              icon: progress.isOverBudget
                  ? Icons.warning_amber_rounded
                  : Icons.savings_outlined,
              label: progress.isOverBudget ? 'Over Budget' : 'Remaining',
              value: progress.isOverBudget
                  ? formatExactCurrency.format(
                      progress.spent - progress.budget.amount,
                    )
                  : formatExactCurrency.format(progress.remaining),
              valueColor: progress.isOverBudget
                  ? AppColors.error
                  : AppColors.success,
            ),
            Divider(
              height: 1,
              color: AppColors.getTextMuted(context).withOpacity(0.2),
            ),
            _buildDetailRow(
              context,
              icon: Icons.category_outlined,
              label: 'Category',
              value: displayCategory,
            ),
            Divider(
              height: 1,
              color: AppColors.getTextMuted(context).withOpacity(0.2),
            ),
            _buildDetailRow(
              context,
              icon: Icons.calendar_today_rounded,
              label: 'Period',
              value: displayPeriod,
            ),
            Divider(
              height: 1,
              color: AppColors.getTextMuted(context).withOpacity(0.2),
            ),
            if (dateRange.isNotEmpty) ...[
              _buildDetailRow(
                context,
                icon: Icons.date_range_rounded,
                label: 'Timeline',
                value: dateRange,
              ),
              Divider(
                height: 1,
                color: AppColors.getTextMuted(context).withOpacity(0.2),
              ),
            ],
            if (daysLeft != null) ...[
              _buildDetailRow(
                context,
                icon: Icons.timelapse_rounded,
                label: 'Time left',
                value: '$daysLeft day${daysLeft == 1 ? '' : 's'}',
                valueColor: daysLeft <= 3 && daysLeft > 0
                    ? AppColors.warning
                    : (daysLeft == 0 ? AppColors.getTextMuted(context) : null),
              ),
            ],
            if (progress.budget.isStopped &&
                progress.budget.endDate != null) ...[
              Divider(
                height: 1,
                color: AppColors.getTextMuted(context).withOpacity(0.2),
              ),
              _buildDetailRow(
                context,
                icon: Icons.block_flipped,
                label: 'Stopped on',
                value: DateFormat(
                  'MMM d, yyyy',
                ).format(progress.budget.endDate!),
                valueColor: AppColors.error,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSizes.w16,
        vertical: AppSizes.h16,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: AppSizes.r20,
            color: AppColors.getTextMuted(context),
          ),
          SizedBox(width: AppSizes.w12),
          Text(
            label,
            style: AppTextStyles.body(
              context,
              color: AppColors.getTextMuted(context),
            ),
          ),
          Spacer(),
          Text(
            value,
            style: AppTextStyles.body(context).copyWith(
              fontWeight: FontWeight.w600,
              color: valueColor ?? AppColors.getText(context),
            ),
          ),
        ],
      ),
    );
  }
}

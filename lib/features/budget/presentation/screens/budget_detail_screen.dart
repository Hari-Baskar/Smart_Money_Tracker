import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_money_tracker/core/constants/app_colors.dart';
import 'package:smart_money_tracker/core/constants/app_sizes.dart';
import 'package:smart_money_tracker/core/constants/app_routes.dart';
import 'package:smart_money_tracker/core/theme/app_text_styles.dart';
import 'package:smart_money_tracker/core/utils/app_toast.dart';
import 'package:smart_money_tracker/features/auth/presentation/providers/auth_provider.dart';
import 'package:smart_money_tracker/features/budget/domain/providers/budget_providers.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/widgets/expandable_transaction_card.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/providers/subcategory_provider.dart';
import 'package:smart_money_tracker/core/common/widgets/banner_ad_widget.dart';
import 'package:smart_money_tracker/core/common/widgets/category_icon_widget.dart';
import 'package:smart_money_tracker/core/common/widgets/primary_button.dart';
import 'package:smart_money_tracker/core/common/widgets/delete_budget_bottom_sheet.dart';
import 'package:smart_money_tracker/core/common/widgets/stop_budget_bottom_sheet.dart';

import 'package:smart_money_tracker/core/common/widgets/modal_action_sheet.dart';

class BudgetDetailScreen extends ConsumerWidget {
  final BudgetProgress initialProgress;

  const BudgetDetailScreen({super.key, required this.initialProgress});

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
      backgroundColor: AppColors.getBackground(context),
      appBar: AppBar(
        backgroundColor: AppColors.getBackground(context),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: AppColors.getText(context),
            size: AppSizes.r24,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.more_vert_rounded,
              color: AppColors.getText(context),
              size: AppSizes.r24,
            ),
            onPressed: () => _showManageBudgetOptions(context, ref, progress),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              children: [
                SizedBox(height: AppSizes.h8),
                _buildDetailsSection(context, ref, progress, dateRange),
                SizedBox(height: AppSizes.h16),
                const BannerAdWidget(),
                SizedBox(height: AppSizes.h24),
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
                    style: AppTextStyles.subHeading(
                      context,
                    ).copyWith(fontWeight: FontWeight.w600),
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
                              color: AppColors.getTextMuted(context),
                            ).copyWith(fontWeight: FontWeight.w600),
                          ),
                          SizedBox(width: AppSizes.w4),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: AppSizes.r12,
                            color: AppColors.getTextMuted(context),
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
                      color: AppColors.getTextMuted(
                        context,
                      ).withValues(alpha: 0.5),
                    ),
                    SizedBox(height: AppSizes.h8),
                    Text(
                      'No transactions yet',
                      style: AppTextStyles.body(
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

    String? resolvedSubName;
    if (progress.budget.subcategoryId != null) {
      final subcategoriesAsync = ref.watch(subcategoriesProvider);
      final subcategories = subcategoriesAsync.value ?? [];
      try {
        final subModel = subcategories.firstWhere(
          (s) => s.id == progress.budget.subcategoryId,
        );
        resolvedSubName = subModel.name;
      } catch (_) {
        resolvedSubName = progress.budget.subcategoryId;
      }
    }

    final resolvedCategoryName =
        categoryModel?.name ?? progress.budget.categoryId ?? 'All Categories';
    final formattedCategory =
        '${resolvedCategoryName[0].toUpperCase()}${resolvedCategoryName.substring(1)}';

    final hasCustomName =
        progress.budget.name.isNotEmpty &&
        progress.budget.name != 'Budget' &&
        progress.budget.name != 'Category Budget' &&
        progress.budget.name != 'Overall Budget';

    final categoryWithSub = resolvedSubName != null
        ? '$formattedCategory ➔ $resolvedSubName'
        : formattedCategory;

    String mainName;
    String subtitle;

    if (hasCustomName) {
      mainName = progress.budget.name;
      subtitle = '$categoryWithSub • $displayPeriod Budget';
    } else {
      mainName = categoryWithSub;
      subtitle = '$displayPeriod Budget';
    }

    final categoryColor = AppColors.getCategoryColor(
      progress.budget.categoryId ?? '',
    );

    final startDateStr = progress.periodStart != null
        ? DateFormat('d MMM yyyy').format(progress.periodStart!)
        : DateFormat('d MMM yyyy').format(DateTime.now());

    final endDateStr = progress.periodEnd != null
        ? DateFormat('d MMM yyyy').format(progress.periodEnd!)
        : 'Ongoing';

    String formatAmount(double val) {
      final isInt = val == val.truncateToDouble();
      return NumberFormat.currency(
        symbol: '₹',
        decimalDigits: isInt ? 0 : 2,
        locale: 'en_IN',
      ).format(val);
    }

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

    final percentage = progress.percentage;
    final isOverBudget = progress.isOverBudget;
    final progressColor = isOverBudget ? AppColors.error : AppColors.success;

    // Status header info
    String statusTitle;
    String statusSubtitle;
    if (progress.budget.isStopped) {
      statusTitle = 'Budget stopped';
      statusSubtitle = 'All tracking is paused';
    } else if (progress.isOverBudget) {
      statusTitle = 'Budget exceeded';
      statusSubtitle = '${formatAmount(progress.remaining.abs())} over limit';
    } else if (progress.isCompleted) {
      statusTitle = 'Budget completed';
      statusSubtitle = 'Period has ended';
    } else {
      statusTitle = 'Budget active';
      statusSubtitle = 'All expenses are tracked';
    }

    return Column(
      children: [
        // 1. Centered Category Icon with Filled Background
        Center(
          child: Container(
            width: AppSizes.w(64),
            height: AppSizes.w(64),
            decoration: BoxDecoration(
              color: categoryColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: CategoryIconWidget(
                categoryName: progress.budget.categoryId ?? '',
                color: AppColors.white,
                size: AppSizes.r24,
              ),
            ),
          ),
        ),
        SizedBox(height: AppSizes.h8),

        // 2. Centered Category Name
        Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSizes.w24),
            child: Text(
              mainName,
              textAlign: TextAlign.center,
              style: AppTextStyles.subHeading(
                context,
              ).copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        SizedBox(height: AppSizes.h4),

        // 3. Centered Period
        Center(
          child: Text(
            subtitle,
            textAlign: TextAlign.center,
            style: AppTextStyles.body(
              context,
            ).copyWith(color: AppColors.getTextMuted(context)),
          ),
        ),
        SizedBox(height: AppSizes.h24),

        // 4. Main Details Card
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSizes.w16),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.isDark(context)
                  ? const Color(0xFF18181A)
                  : AppColors.getSurfaceContainerLowest(context),
              borderRadius: BorderRadius.circular(AppSizes.r8),
              border: Border.all(
                color: AppColors.isDark(context)
                    ? const Color(0xFF2E2E32)
                    : const Color(0xFFE5E7EB),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Card Header / Progress Banner
                InkWell(
                  onTap: () => _showManageBudgetOptions(context, ref, progress),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(AppSizes.r(16)),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(AppSizes.w16),
                    child: Row(
                      children: [
                        // Circular Progress Indicator
                        CircularPercentIndicator(
                          radius: AppSizes.r(24),
                          lineWidth: 4.5,
                          animation: true,
                          percent: percentage > 1.0
                              ? 1.0
                              : (percentage < 0.0 ? 0.0 : percentage),
                          center: Text(
                            '${(percentage * 100).toInt()}%',
                            style: AppTextStyles.small(context).copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: AppSizes.r(11),
                              color: AppColors.getText(context),
                            ),
                          ),
                          progressColor: progressColor,
                          backgroundColor: AppColors.isDark(context)
                              ? const Color(0xFF2A2A2A)
                              : const Color(0xFFE5E7EB),
                          circularStrokeCap: CircularStrokeCap.round,
                        ),
                        SizedBox(width: AppSizes.w12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                statusTitle,
                                style: AppTextStyles.subHeading(context)
                                    .copyWith(
                                      color: AppColors.getTextMuted(context),
                                    ),
                              ),
                              SizedBox(height: AppSizes.h2),
                              Text(
                                statusSubtitle,
                                style: AppTextStyles.body(context).copyWith(
                                  color: AppColors.getTextMuted(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: AppColors.getTextMuted(context),
                          size: AppSizes.r24,
                        ),
                      ],
                    ),
                  ),
                ),

                Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.isDark(context)
                      ? const Color(0xFF2E2E32)
                      : const Color(0xFFE5E7EB),
                ),

                // Grid Details
                Padding(
                  padding: EdgeInsets.all(AppSizes.w16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Row 1: Total & Used
                      Row(
                        children: [
                          Expanded(
                            child: _buildDetailCell(
                              context,
                              label: 'Total',
                              value: formatAmount(progress.budget.amount),
                            ),
                          ),
                          SizedBox(width: AppSizes.w16),
                          Expanded(
                            child: _buildDetailCell(
                              context,
                              label: 'Used',
                              value: formatAmount(progress.spent),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: AppSizes.h20),

                      // Row 2: Remaining & Days Left
                      Row(
                        children: [
                          Expanded(
                            child: _buildDetailCell(
                              context,
                              label: 'Remaining',
                              value: progress.remaining < 0
                                  ? '-${formatAmount(progress.remaining.abs())}'
                                  : formatAmount(progress.remaining),
                            ),
                          ),
                          SizedBox(width: AppSizes.w16),
                          Expanded(
                            child: _buildDetailCell(
                              context,
                              label: 'Days left',
                              value: progress.budget.isStopped
                                  ? 'Stopped'
                                  : progress.isCompleted
                                  ? 'Ended'
                                  : (daysLeft != null
                                        ? '$daysLeft days'
                                        : 'Ongoing'),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: AppSizes.h20),

                      // Row 3: Start Date & End Date
                      Row(
                        children: [
                          Expanded(
                            child: _buildDetailCell(
                              context,
                              label: 'Start date',
                              value: startDateStr,
                            ),
                          ),
                          SizedBox(width: AppSizes.w16),
                          Expanded(
                            child: _buildDetailCell(
                              context,
                              label: 'End date',
                              value: endDateStr,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailCell(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.body(
            context,
          ).copyWith(color: AppColors.getTextMuted(context)),
        ),
        SizedBox(height: AppSizes.h4),
        Text(
          value,
          style: AppTextStyles.body(context).copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.getText(context),
          ),
        ),
      ],
    );
  }

  void _showManageBudgetOptions(
    BuildContext context,
    WidgetRef ref,
    BudgetProgress progress,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.transparent,
      builder: (BuildContext bottomSheetContext) {
        return ModalActionSheet(
          children: [
            if (!progress.budget.isStopped) ...[
              ModalActionItem(
                icon: Icons.edit_outlined,
                title: 'Edit Budget',
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  context.push(
                    AppRoutes.createBudget,
                    extra: progress.budget,
                  );
                },
              ),
              ModalActionItem(
                icon: Icons.pause_circle_outline_rounded,
                title: 'Stop Budget',
                onTap: () async {
                  Navigator.pop(bottomSheetContext);
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
                },
              ),
            ],
            ModalActionItem(
              icon: Icons.delete_outline_rounded,
              title: 'Delete Budget',
              isDestructive: true,
              onTap: () async {
                Navigator.pop(bottomSheetContext);
                final shouldDelete = await showDeleteBudgetBottomSheet(context);
                if (shouldDelete == true) {
                  final user = ref.read(authStateProvider).value;
                  if (user != null) {
                    await ref
                        .read(budgetRepositoryProvider)
                        .deleteBudget(user.id, progress.budget.id);
                    if (context.mounted) {
                      context.pop();
                      AppToast.show(context, 'Budget deleted');
                    }
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }
}

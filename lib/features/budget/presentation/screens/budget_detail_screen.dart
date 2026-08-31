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
        backgroundColor: AppColors.getBackground(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.getText(context),
            size: AppSizes.r20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
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
                    SizedBox(height: AppSizes.h8),
                    Text(
                      'No transactions yet',
                      style: AppTextStyles.body(
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
    String displayCategory = resolvedCategoryName != null
        ? '${resolvedCategoryName[0].toUpperCase()}${resolvedCategoryName.substring(1)}'
        : 'All Categories';

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
      if (resolvedSubName != null) {
        displayCategory = '$displayCategory ➔ $resolvedSubName';
      }
    }

    final budgetName =
        (progress.budget.name.isNotEmpty &&
            progress.budget.name != 'Budget' &&
            progress.budget.name != 'Category Budget' &&
            progress.budget.name != 'Overall Budget')
        ? progress.budget.name
        : (resolvedSubName != null
              ? '$resolvedSubName Budget'
              : (progress.budget.categoryId != null
                    ? '$displayCategory Budget'
                    : 'Overall Budget'));

    String formatCompact(double value) {
      if (value >= 1000 && value < 100000) {
        return '₹${(value / 1000).toStringAsFixed(value % 1000 == 0 ? 0 : 2)}K';
      } else if (value >= 100000 && value < 10000000) {
        return '₹${(value / 100000).toStringAsFixed(value % 100000 == 0 ? 0 : 2)}L';
      } else if (value >= 10000000) {
        return '₹${(value / 10000000).toStringAsFixed(value % 10000000 == 0 ? 0 : 2)}Cr';
      }
      return '₹${value.toStringAsFixed(0)}';
    }

    String formattedDateRange = dateRange;
    if (progress.periodStart != null && progress.periodEnd != null) {
      if (progress.periodStart!.year == progress.periodEnd!.year) {
        formattedDateRange =
            '${DateFormat('MMM d').format(progress.periodStart!)} - ${DateFormat('MMM d, yyyy').format(progress.periodEnd!)}';
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSizes.w16),
          child: Text(
            budgetName,
            style: AppTextStyles.subHeading(
              context,
            ).copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(height: AppSizes.h12),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSizes.w16),
          child: Row(
            children: [
              _buildPill(context, displayPeriod),
              SizedBox(width: AppSizes.w8),
              _buildPill(context, displayCategory),
            ],
          ),
        ),
        SizedBox(height: AppSizes.h16),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSizes.w16),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _buildProgressCard(context, progress, formatCompact),
                ),
                SizedBox(width: AppSizes.w8),
                Expanded(
                  child: _buildTimelineCard(
                    context,
                    formattedDateRange,
                    daysLeft,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: AppSizes.h8),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSizes.w16),
          child: _buildManageBudgetCard(context, ref, progress),
        ),
      ],
    );
  }

  Widget _buildPill(BuildContext context, String text) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSizes.w12,
        vertical: AppSizes.h8,
      ),
      decoration: BoxDecoration(
        color: AppColors.getTextMuted(context).withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSizes.r20),
      ),
      child: Text(
        text,
        style: AppTextStyles.small(context).copyWith(
          color: AppColors.getText(context),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildProgressCard(
    BuildContext context,
    BudgetProgress progress,
    String Function(double) format,
  ) {
    final percentage = progress.percentage;
    final isOverBudget = progress.isOverBudget;
    final progressColor = isOverBudget ? AppColors.error : AppColors.success;

    return Container(
      padding: EdgeInsets.all(AppSizes.w16),
      decoration: BoxDecoration(
        color: AppColors.getSurfaceContainerLowest(context),
        borderRadius: AppSizes.cardBorderRadius,
        border: AppColors.isDark(context)
            ? null
            : Border.all(color: AppColors.black.withOpacity(0.08), width: 1),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: AppSizes.r(48),
                height: AppSizes.r(48),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: percentage > 1.0 ? 1.0 : percentage,
                      backgroundColor: AppColors.getTextMuted(
                        context,
                      ).withOpacity(0.15),
                      color: progressColor,
                      strokeWidth: 4,
                    ),
                    Center(
                      child: Text(
                        '${(percentage * 100).toInt()}%',
                        style: AppTextStyles.body(context).copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: AppSizes.r12,
                          color: progressColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: AppSizes.h8),
          Text(
            'Budget Progress',
            style: AppTextStyles.body(
              context,
              color: AppColors.getText(context),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: AppSizes.h4),
          Text(
            '${format(progress.spent)} / ${format(progress.budget.amount)}',
            style: AppTextStyles.subHeading(
              context,
              fontWeight: FontWeight.bold,
              color: AppColors.getTextMuted(context),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: AppSizes.h4),
          Text(
            isOverBudget
                ? '${format(progress.spent - progress.budget.amount)} over budget'
                : '${format(progress.remaining)} left',
            style: AppTextStyles.body(context, color: progressColor),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineCard(
    BuildContext context,
    String dateRange,
    int? daysLeft,
  ) {
    return Container(
      padding: EdgeInsets.all(AppSizes.w16),
      decoration: BoxDecoration(
        color: AppColors.getSurfaceContainerLowest(context),
        borderRadius: AppSizes.cardBorderRadius,
        border: AppColors.isDark(context)
            ? null
            : Border.all(color: AppColors.black.withOpacity(0.08), width: 1),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: AppSizes.r(48),
                height: AppSizes.r(48),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.calendar_today_rounded,
                  color: AppColors.white,
                  size: AppSizes.r(24),
                ),
              ),
            ],
          ),
          SizedBox(height: AppSizes.h8),
          Text(
            'Timeline',
            style: AppTextStyles.body(
              context,
              color: AppColors.getText(context),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: AppSizes.h4),
          Text(
            dateRange.isEmpty ? 'Ongoing' : dateRange,
            style: AppTextStyles.subHeading(
              context,
              fontWeight: FontWeight.bold,
              color: AppColors.getTextMuted(context),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: AppSizes.h4),
          Text(
            daysLeft != null ? '$daysLeft days left' : 'Completed',
            style: AppTextStyles.body(
              context,
              color: daysLeft != null && daysLeft <= 3 && daysLeft > 0
                  ? AppColors.warning
                  : daysLeft == 0
                  ? AppColors.getTextMuted(context)
                  : AppColors.primary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildManageBudgetCard(
    BuildContext context,
    WidgetRef ref,
    BudgetProgress progress,
  ) {
    return InkWell(
      onTap: () => _showManageBudgetOptions(context, ref, progress),
      borderRadius: AppSizes.cardBorderRadius,
      child: Container(
        padding: EdgeInsets.all(AppSizes.w8),
        decoration: BoxDecoration(
          color: AppColors.getSurfaceContainerLowest(context),
          borderRadius: AppSizes.cardBorderRadius,
          border: AppColors.isDark(context)
              ? null
              : Border.all(color: AppColors.black.withOpacity(0.08), width: 1),
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
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(AppSizes.r(8)),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.textMuted,
              ),
              child: Icon(
                Icons.settings_outlined,
                color: AppColors.white,
                size: AppSizes.r16,
              ),
            ),
            SizedBox(width: AppSizes.w16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Manage Budget',
                    style: AppTextStyles.body(
                      context,
                    ).copyWith(color: AppColors.getText(context)),
                  ),
                  SizedBox(height: AppSizes.h4),
                  Text(
                    'Edit, stop or delete this budget',
                    style: AppTextStyles.small(
                      context,
                    ).copyWith(color: AppColors.getTextMuted(context)),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.getTextMuted(context),
              size: AppSizes.r24,
            ),
          ],
        ),
      ),
    );
  }

  void _showManageBudgetOptions(
    BuildContext context,
    WidgetRef ref,
    BudgetProgress progress,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.getSurfaceContainerLowest(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.r24)),
      ),
      builder: (BuildContext bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: AppSizes.h16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: AppSizes.w(40),
                    height: AppSizes.h(4),
                    decoration: BoxDecoration(
                      color: AppColors.getTextMuted(context).withOpacity(0.3),
                      borderRadius: BorderRadius.circular(AppSizes.r(2)),
                    ),
                  ),
                ),
                SizedBox(height: AppSizes.h24),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSizes.w24),
                  child: Text(
                    'Manage Budget',
                    style: AppTextStyles.subHeading(
                      context,
                    ).copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(height: AppSizes.h8),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSizes.w24),
                  child: Text(
                    'Choose an action below to modify, stop, or permanently remove this budget from your tracker.',
                    style: AppTextStyles.body(
                      context,
                    ).copyWith(color: AppColors.getTextMuted(context)),
                  ),
                ),
                SizedBox(height: AppSizes.h32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildOptionColumn(
                      context,
                      icon: Icons.delete_outline,
                      color: AppColors.error,
                      label: 'Delete',
                      onTap: () async {
                        Navigator.pop(bottomSheetContext);
                        final shouldDelete = await showDeleteBudgetBottomSheet(
                          context,
                        );
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
                      },
                    ),
                    if (!progress.budget.isStopped)
                      _buildOptionColumn(
                        context,
                        icon: Icons.stop_circle_outlined,
                        color: AppColors.warning,
                        label: 'Stop',
                        onTap: () async {
                          Navigator.pop(bottomSheetContext);
                          final shouldStop = await showStopBudgetBottomSheet(
                            context,
                          );
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
                    if (!progress.budget.isStopped)
                      _buildOptionColumn(
                        context,
                        icon: Icons.edit_outlined,
                        color: AppColors.primary,
                        label: 'Edit',
                        onTap: () {
                          Navigator.pop(bottomSheetContext);
                          context.push(
                            AppRoutes.createBudget,
                            extra: progress.budget,
                          );
                        },
                      ),
                  ],
                ),
                SizedBox(height: AppSizes.h32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOptionColumn(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.r12),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSizes.w12,
          vertical: AppSizes.h8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(AppSizes.r(12)),
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Icon(icon, color: AppColors.white, size: AppSizes.r16),
            ),
            SizedBox(height: AppSizes.h8),
            Text(
              label,
              style: AppTextStyles.body(context).copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.getText(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

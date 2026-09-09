import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_money_tracker/core/constants/app_colors.dart';
import 'package:smart_money_tracker/core/constants/app_sizes.dart';
import 'package:smart_money_tracker/core/constants/app_routes.dart';
import 'package:smart_money_tracker/core/theme/app_text_styles.dart';
import 'package:smart_money_tracker/core/utils/app_toast.dart';
import 'package:smart_money_tracker/core/services/time_service.dart';
import 'package:smart_money_tracker/features/auth/presentation/providers/auth_provider.dart';
import 'package:smart_money_tracker/core/models/budget_model.dart';
import 'package:smart_money_tracker/features/budget/domain/providers/budget_providers.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/providers/transaction_provider.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/widgets/expandable_transaction_card.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/providers/subcategory_provider.dart';
import 'package:smart_money_tracker/core/common/widgets/banner_ad_widget.dart';
import 'package:smart_money_tracker/core/common/widgets/category_icon_widget.dart';
import 'package:smart_money_tracker/core/common/widgets/delete_budget_bottom_sheet.dart';
import 'package:smart_money_tracker/core/common/widgets/stop_budget_bottom_sheet.dart';

import 'package:smart_money_tracker/core/common/widgets/modal_action_sheet.dart';

class BudgetDetailScreen extends HookConsumerWidget {
  final BudgetProgress initialProgress;

  const BudgetDetailScreen({super.key, required this.initialProgress});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch for updates to this specific budget
    final budgetProgressList = ref.watch(budgetProgressProvider);
    final progress = budgetProgressList.firstWhere((p) {
      if (p.budget.id != initialProgress.budget.id) return false;
      if (initialProgress.instance != null) {
        return p.instance?.id == initialProgress.instance?.id ||
            (p.periodStart == initialProgress.periodStart &&
                p.periodEnd == initialProgress.periodEnd);
      }
      return true;
    }, orElse: () => initialProgress);

    // Check local database and fill gaps from Firestore if any for the budget's date range
    final start = progress.periodStart ?? progress.budget.startDate;
    final end =
        progress.periodEnd ?? progress.budget.endDate ?? TimeService.now();

    final isSyncing = useState<bool>(true);

    useEffect(() {
      Future.microtask(() async {
        final userId = ref.read(authStateProvider).value?.id;
        if (userId != null) {
          try {
            final syncStart = start != null
                ? DateTime(start.year, start.month, start.day)
                : TimeService.now().subtract(const Duration(days: 30));
            final syncEnd = DateTime(
              end.year,
              end.month,
              end.day,
              23,
              59,
              59,
              999,
            );
            await ref
                .read(transactionRepositoryProvider)
                .syncDateRange(userId, syncStart, syncEnd);
          } catch (e) {
            debugPrint('Error syncing budget date range: $e');
          } finally {
            if (context.mounted) {
              isSyncing.value = false;
            }
          }
        } else {
          isSyncing.value = false;
        }
      });
      return null;
    }, const []);

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
      body: isSyncing.value
          ? Center(
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.primary,
              ),
            )
          : CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              children: [
                SizedBox(height: AppSizes.h8),
                _buildDetailsSection(context, ref, progress, dateRange),
                SizedBox(height: AppSizes.h16),
                const BannerAdWidget(),
                SizedBox(height: AppSizes.h16),
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
                    ).copyWith(fontWeight: FontWeight.bold),
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
                child: Padding(
                  padding: EdgeInsets.only(
                    top: AppSizes.h(64),
                    bottom: AppSizes.h(40),
                  ),
                  child: Text(
                    'No transactions yet',
                    style: AppTextStyles.body(
                      context,
                      color: AppColors.getTextMuted(context),
                    ),
                  ),
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
    final isOneTime =
        (progress.budget.period == BudgetPeriod.monthly ||
            progress.budget.period == BudgetPeriod.weekly) &&
        !progress.budget.isRecurring;
    final displayPeriod = isOneTime
        ? 'One-time ${periodName[0].toUpperCase()}${periodName.substring(1)}'
        : (progress.budget.isRecurring
              ? '${periodName[0].toUpperCase()}${periodName.substring(1)} (Recurring)'
              : '${periodName[0].toUpperCase()}${periodName.substring(1)}');

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
        progress.budget.name != 'Overall Budget' &&
        !progress.budget.name.endsWith(' Budget');

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
    final txnCount = progress.transactions.length;
    if (progress.budget.isStopped) {
      statusTitle = 'Budget stopped';
      statusSubtitle = 'All tracking is paused';
    } else if (progress.isUpcoming) {
      statusTitle = 'Yet to start';
      statusSubtitle = '$txnCount Transaction${txnCount == 1 ? '' : 's'}';
    } else if (progress.isOverBudget) {
      statusTitle = 'Budget exceeded';
      statusSubtitle = '${formatAmount(progress.remaining.abs())} over limit';
    } else if (progress.isCompleted) {
      statusTitle = 'Budget completed';
      statusSubtitle = 'Period has ended';
    } else {
      statusTitle = 'Budget active';
      statusSubtitle = '$txnCount Transaction${txnCount == 1 ? '' : 's'}';
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
        SizedBox(
          height: AppSizes.h8,
        ), // 2. Centered Category & Subcategory / Custom Name
        Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSizes.w24),
            child: hasCustomName
                ? Column(
                    children: [
                      Text(
                        progress.budget.name,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.subHeading(
                          context,
                        ).copyWith(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: AppSizes.h4),
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: AppSizes.w4,
                        runSpacing: AppSizes.h2,
                        children: [
                          Text(
                            formattedCategory,
                            style: AppTextStyles.body(context).copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.getText(context),
                            ),
                          ),
                          if (resolvedSubName != null &&
                              resolvedSubName.isNotEmpty) ...[
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: AppSizes.r12,
                              color: AppColors.getTextMuted(context),
                            ),
                            Text(
                              resolvedSubName,
                              style: AppTextStyles.body(context).copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.getText(context),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  )
                : Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: AppSizes.w(6),
                    runSpacing: AppSizes.h2,
                    children: [
                      Text(
                        formattedCategory,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.subHeading(context).copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.getText(context),
                        ),
                      ),
                      if (resolvedSubName != null &&
                          resolvedSubName.isNotEmpty) ...[
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: AppSizes.r(14),
                          color: AppColors.getTextMuted(context),
                        ),
                        Text(
                          resolvedSubName,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.subHeading(context).copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.getText(context),
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
        ),
        SizedBox(height: AppSizes.h4),

        // 3. Centered Period
        Center(
          child: Text(
            '$displayPeriod Budget',
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
              color: AppColors.getSurfaceContainerLowest(context),
              borderRadius: AppSizes.cardBorderRadius,
              border: AppColors.isDark(context)
                  ? null
                  : Border.all(
                      color: AppColors.black.withValues(alpha: 0.08),
                      width: 1,
                    ),
              boxShadow: AppColors.isDark(context)
                  ? null
                  : [
                      BoxShadow(
                        color: AppColors.black.withValues(alpha: 0.03),
                        blurRadius: 16,
                        spreadRadius: 0,
                        offset: Offset.zero,
                      ),
                    ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Card Header / Progress Banner
                InkWell(
                  onTap: () => _showManageBudgetOptions(context, ref, progress),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(AppSizes.cardRadius),
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
                              ? AppColors.white.withValues(alpha: 0.1)
                              : AppColors.black.withValues(alpha: 0.08),
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
                              value: formatAmount(progress.limitAmount),
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
                                        ? '$daysLeft'
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
        final isRecurring = progress.budget.isRecurring;
        final isStopped = progress.budget.isStopped;
        final isCompleted = progress.isCompleted;

        // Check if there are multiple recurring instances/periods for this budget
        final allInstances = ref.read(budgetInstancesProvider).value ?? [];
        final budgetProgressList = ref.read(budgetProgressProvider);
        final instancesCount = allInstances
            .where((i) => i.budgetId == progress.budget.id)
            .length;
        final progressCount = budgetProgressList
            .where((p) => p.budget.id == progress.budget.id)
            .length;
        final hasMultipleInstances =
            isRecurring && (instancesCount > 1 || progressCount > 1);

        return ModalActionSheet(
          children: [
            // ── COMPLETED BUDGET ACTIONS (Show ONLY Delete Budget) ──
            if (isCompleted) ...[
              ModalActionItem(
                icon: Icons.delete_outline_rounded,
                title: 'Delete Budget',
                isDestructive: true,
                onTap: () async {
                  Navigator.pop(bottomSheetContext);
                  final shouldDelete = await showDeleteBudgetBottomSheet(
                    context,
                  );
                  if (shouldDelete == true) {
                    final user = ref.read(authStateProvider).value;
                    if (user != null) {
                      if (progress.instance != null) {
                        await ref
                            .read(budgetRepositoryProvider)
                            .deleteBudgetInstance(
                              user.id,
                              progress.budget.id,
                              progress.instance!.id,
                            );
                      } else {
                        await ref
                            .read(budgetRepositoryProvider)
                            .deleteBudget(user.id, progress.budget.id);
                      }
                      if (context.mounted) {
                        context.pop();
                        AppToast.show(context, 'Budget deleted');
                      }
                    }
                  }
                },
              ),
            ],

            // ── ACTIVE SINGLE-PERIOD / NON-RECURRING ACTIONS ──
            if (!isCompleted && (!isRecurring || !hasMultipleInstances)) ...[
              if (!isStopped)
                ModalActionItem(
                  icon: Icons.edit_outlined,
                  title: 'Edit Budget',
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    context.push(
                      AppRoutes.createBudget,
                      extra: {
                        'budget': progress.budget,
                        'instance': null,
                        'isEditingSeries': isRecurring,
                      },
                    );
                  },
                ),
              ModalActionItem(
                icon: Icons.delete_outline_rounded,
                title: 'Delete Budget',
                isDestructive: true,
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

            // ── ACTIVE MULTI-PERIOD RECURRING BUDGET ACTIONS ──
            if (!isCompleted && isRecurring && hasMultipleInstances) ...[
              if (!isStopped) ...[
                ModalActionItem(
                  icon: Icons.edit_calendar_outlined,
                  title: 'Edit This Period',
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    context.push(
                      AppRoutes.createBudget,
                      extra: {
                        'budget': progress.budget,
                        'instance': progress.instance,
                        'isEditingSeries': false,
                      },
                    );
                  },
                ),
                ModalActionItem(
                  icon: Icons.tune_rounded,
                  title: 'Edit Recurring Series',
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    context.push(
                      AppRoutes.createBudget,
                      extra: {
                        'budget': progress.budget,
                        'instance': null,
                        'isEditingSeries': true,
                      },
                    );
                  },
                ),
                ModalActionItem(
                  icon: Icons.pause_circle_outline_rounded,
                  title: 'Stop Recurring Budget',
                  onTap: () async {
                    Navigator.pop(bottomSheetContext);
                    final shouldStop = await showStopBudgetBottomSheet(context);
                    if (shouldStop == true) {
                      final user = ref.read(authStateProvider).value;
                      if (user != null) {
                        final updatedBudget = progress.budget.copyWith(
                          isStopped: true,
                        );
                        await ref
                            .read(budgetRepositoryProvider)
                            .saveBudget(user.id, updatedBudget);
                        if (context.mounted) {
                          AppToast.show(context, 'Recurring budget stopped');
                        }
                      }
                    }
                  },
                ),
              ],
              if (progress.instance != null)
                ModalActionItem(
                  icon: Icons.delete_outline_rounded,
                  title: 'Delete This Period',
                  isDestructive: true,
                  onTap: () async {
                    Navigator.pop(bottomSheetContext);
                    final shouldDelete = await showDeleteBudgetBottomSheet(
                      context,
                    );
                    if (shouldDelete == true) {
                      final user = ref.read(authStateProvider).value;
                      if (user != null && progress.instance != null) {
                        await ref
                            .read(budgetRepositoryProvider)
                            .deleteBudgetInstance(
                              user.id,
                              progress.budget.id,
                              progress.instance!.id,
                            );
                        if (context.mounted) {
                          context.pop();
                          AppToast.show(context, 'Period budget deleted');
                        }
                      }
                    }
                  },
                ),
              ModalActionItem(
                icon: Icons.delete_forever_outlined,
                title: 'Delete Entire Series',
                isDestructive: true,
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
                          .deleteBudget(user.id, progress.budget.id);
                      if (context.mounted) {
                        context.pop();
                        AppToast.show(
                          context,
                          'Entire recurring series deleted',
                        );
                      }
                    }
                  }
                },
              ),
            ],
          ],
        );
      },
    );
  }
}

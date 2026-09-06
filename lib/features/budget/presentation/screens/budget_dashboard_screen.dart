import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_money_tracker/core/constants/app_colors.dart';
import 'package:smart_money_tracker/core/constants/app_sizes.dart';
import 'package:smart_money_tracker/core/constants/app_routes.dart';
import 'package:smart_money_tracker/features/budget/domain/providers/budget_providers.dart';
import 'package:smart_money_tracker/features/budget/presentation/widgets/budget_progress_card.dart';
import 'package:smart_money_tracker/features/auth/presentation/providers/auth_provider.dart';
import 'package:smart_money_tracker/core/theme/app_text_styles.dart';
import 'package:intl/intl.dart';

class BudgetDashboardScreen extends ConsumerWidget {
  const BudgetDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetProgressList = ref.watch(budgetProgressProvider);
    final isLoading = ref.watch(budgetsProvider).isLoading;

    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.getText(context),
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Budgets',
          style: AppTextStyles.subHeading(
            context,
            color: AppColors.getText(context),
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.getBackground(context),
        elevation: 0,
      ),
      body: isLoading && budgetProgressList.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : budgetProgressList.isEmpty
          ? _buildEmptyState(context)
          : Builder(
              builder: (context) {
                final Map<String, List<BudgetProgress>> grouped = {};
                for (var progress in budgetProgressList) {
                  final date =
                      progress.periodEnd ??
                      progress.periodStart ??
                      DateTime.now();
                  final label = DateFormat('MMMM yyyy').format(date);
                  if (!grouped.containsKey(label)) {
                    grouped[label] = [];
                  }
                  grouped[label]!.add(progress);
                }

                final keys = grouped.keys.toList();

                return ListView.builder(
                  itemCount: keys.length,
                  padding: EdgeInsets.only(bottom: AppSizes.h(80)),
                  itemBuilder: (context, index) {
                    final label = keys[index];
                    final items = grouped[label]!;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(
                            left: AppSizes.w16,
                            right: AppSizes.w16,
                            top: index == 0 ? AppSizes.h16 : AppSizes.h24,
                            bottom: AppSizes.h12,
                          ),
                          child: Text(
                            label,
                            style: AppTextStyles.subHeading(
                              context,
                              color: AppColors.getText(context),
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSizes.w16,
                          ),
                          child: Wrap(
                            spacing: AppSizes.w8,
                            runSpacing: AppSizes.h8,
                            children: items.map((progress) {
                              return LayoutBuilder(
                                builder: (context, constraints) {
                                  // The Wrap doesn't constrain child width, we must set it.
                                  // Total width available for Wrap is MediaQuery width - 32 (padding).
                                  // We want 2 columns, so subtract spacing (AppSizes.w8) and divide by 2.
                                  final double totalWidth =
                                      MediaQuery.of(context).size.width -
                                      (AppSizes.w16 * 2);
                                  final double itemWidth =
                                      (totalWidth - AppSizes.w8) / 2;

                                  return SizedBox(
                                    width: itemWidth,
                                    child: BudgetProgressCard(
                                      progress: progress,
                                      onTap: () {
                                        context.push(
                                          AppRoutes.budgetDetail,
                                          extra: progress,
                                        );
                                      },
                                    ),
                                  );
                                },
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
      floatingActionButton: budgetProgressList.isEmpty
          ? null
          : FloatingActionButton(
              onPressed: () {
                context.push('/create-budget');
              },
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add, color: AppColors.white),
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.savings_rounded,
            size: AppSizes.r(80),
            color: AppColors.getTextMuted(context).withOpacity(0.5),
          ),
          SizedBox(height: AppSizes.h(16)),
          Text(
            'No budgets yet',
            style: AppTextStyles.subHeading(
              context,
              fontWeight: FontWeight.bold,
              color: AppColors.getText(context),
            ),
          ),
          SizedBox(height: AppSizes.h8),
          Text(
            'Create a budget to start tracking your spending.',
            style: AppTextStyles.body(
              context,
              color: AppColors.getTextMuted(context),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSizes.h24),
          GestureDetector(
            onTap: () {
              context.push('/create-budget');
            },
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppSizes.w(24),
                vertical: AppSizes.h(10),
              ),
              decoration: BoxDecoration(
                color: AppColors.getTextMuted(
                  context,
                ).withValues(alpha: 0.15),
                borderRadius: AppSizes.cardBorderRadius,
              ),
              child: Text(
                'Create Budget',
                style: AppTextStyles.body(
                  context,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_money_tracker/core/constants/app_colors.dart';
import 'package:smart_money_tracker/core/constants/app_sizes.dart';
import 'package:smart_money_tracker/core/theme/app_text_styles.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/screens/income_screen.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/screens/expense_screen.dart';

class HistorySummaryCard extends StatelessWidget {
  final String selectedCategory;
  final String selectedSubcategory;
  final double totalSpent;
  final double totalIncome;
  final int incomeCount;
  final int expenseCount;
  final DateTimeRange? dateRange;

  const HistorySummaryCard({
    super.key,
    required this.selectedCategory,
    required this.selectedSubcategory,
    required this.totalSpent,
    required this.totalIncome,
    this.incomeCount = 0,
    this.expenseCount = 0,
    this.dateRange,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    // Outer card background — dark card like screenshot

    return Row(
      children: [
        // Income Tile
        Expanded(
          child: _SummaryTile(
            label: 'Income',
            amount: totalIncome,
            count: incomeCount,
            icon: Icons.account_balance_wallet_rounded,
            accentColor: AppColors.success,
            bgColor: isDark
                ? AppColors.success.withOpacity(0.13)
                : AppColors.success.withOpacity(0.08),
            onTap: () => context.push('/income', extra: dateRange),
            isDark: isDark,
          ),
        ),
        SizedBox(width: AppSizes.w12),
        // Expense Tile
        Expanded(
          child: _SummaryTile(
            label: 'Expense',
            amount: totalSpent,
            count: expenseCount,
            icon: Icons.account_balance_wallet_rounded,
            accentColor: AppColors.error,
            bgColor: isDark
                ? AppColors.error.withOpacity(0.13)
                : AppColors.error.withOpacity(0.07),
            onTap: () => context.push('/expense', extra: dateRange),
            isDark: isDark,
          ),
        ),
      ],
    );
  }
}

// ── Private Tile Widget ──────────────────────────────────────────────────────
class _SummaryTile extends StatelessWidget {
  final String label;
  final double amount;
  final int count;
  final IconData icon;
  final Color accentColor;
  final Color bgColor;
  final VoidCallback onTap;
  final bool isDark;

  const _SummaryTile({
    required this.label,
    required this.amount,
    required this.count,
    required this.icon,
    required this.accentColor,
    required this.bgColor,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppSizes.cardBorderRadius,
        child: Container(
          padding: EdgeInsets.all(AppSizes.w12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: AppSizes.cardBorderRadius,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top Row: icon circle + label + "..." ──────────────
              Row(
                children: [
                  // Icon circle
                  Container(
                    padding: EdgeInsets.all(AppSizes.r8),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.18),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: accentColor, size: AppSizes.r12),
                  ),
                  SizedBox(width: AppSizes.w8),
                  // Label
                  Expanded(
                    child: Text(
                      label,
                      style: AppTextStyles.body(
                        context,
                        color: isDark
                            ? AppColors.textDark
                            : AppColors.textLight,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  // "..." menu
                ],
              ),

              SizedBox(height: AppSizes.h12),

              // ── Large Amount ──────────────────────────────────────
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  '₹${AppColors.formatShortAmount(amount)}',
                  style: AppTextStyles.subHeading(
                    context,
                    color: accentColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
              ),

              SizedBox(height: AppSizes.h8),

              // ── Divider line ─────────────────────────────────────
              Divider(
                color: accentColor.withOpacity(0.15),
                thickness: 1,
                height: 1,
              ),

              SizedBox(height: AppSizes.h8),

              // ── Bottom Row: calendar icon + count ────────────────
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    color: accentColor.withOpacity(0.7),
                    size: AppSizes.r8,
                  ),
                  SizedBox(width: AppSizes.w4),
                  Text(
                    '$count ${count == 1 ? 'Transaction' : 'Transactions'}',
                    style: AppTextStyles.small(
                      context,
                      color: isDark
                          ? AppColors.textDark
                          : AppColors.textMutedLight,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

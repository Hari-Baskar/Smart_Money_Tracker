import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:smart_money_tracker/core/constants/app_colors.dart';
import 'package:smart_money_tracker/core/constants/app_sizes.dart';
import 'package:smart_money_tracker/core/theme/app_text_styles.dart';

class HistorySummaryCard extends StatelessWidget {
  final String selectedCategory;
  final String selectedSubcategory;
  final double totalSpent;
  final double totalIncome;

  const HistorySummaryCard({
    super.key,
    required this.selectedCategory,
    required this.selectedSubcategory,
    required this.totalSpent,
    required this.totalIncome,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: AppSizes.h12),
      padding: EdgeInsets.all(AppSizes.r16),
      decoration: BoxDecoration(
        color: AppColors.getSurfaceContainerLowest(context),
        borderRadius: BorderRadius.circular(AppSizes.r20),
        boxShadow: [
          BoxShadow(
            color: AppColors.isDark(context)
                ? AppColors.black.withOpacity(0.25)
                : AppColors.black.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: AppColors.isDark(context)
              ? AppColors.white.withOpacity(0.06)
              : AppColors.primary.withOpacity(0.08),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Spending Card
          Expanded(
            child: Container(
              padding: EdgeInsets.all(AppSizes.r16),
              decoration: BoxDecoration(
                color: AppColors.isDark(context)
                    ? AppColors.error.withOpacity(0.06)
                    : const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(AppSizes.r16),
                border: Border.all(
                  color: AppColors.error.withOpacity(
                    AppColors.isDark(context) ? 0.2 : 0.08,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(AppSizes.r8),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.trending_up_rounded,
                          color: AppColors.error,
                          size: AppSizes.r16,
                        ),
                      ),
                      SizedBox(width: AppSizes.w8),
                      Text(
                        'Spending',
                        style: AppTextStyles.small(
                          context,
                          color: AppColors.getTextMuted(context),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppSizes.h12),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '₹${AppColors.formatShortAmount(totalSpent)}',
                      style: AppTextStyles.display(
                        context,
                        color: AppColors.error,
                        fontWeight: FontWeight.bold,
                        fontSize: 20.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: AppSizes.w12),
          // Income Card
          Expanded(
            child: Container(
              padding: EdgeInsets.all(AppSizes.r16),
              decoration: BoxDecoration(
                color: AppColors.isDark(context)
                    ? AppColors.success.withOpacity(0.06)
                    : const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(AppSizes.r16),
                border: Border.all(
                  color: AppColors.success.withOpacity(
                    AppColors.isDark(context) ? 0.2 : 0.08,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(AppSizes.r8),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.trending_down_rounded,
                          color: AppColors.success,
                          size: AppSizes.r16,
                        ),
                      ),
                      SizedBox(width: AppSizes.w8),
                      Text(
                        'Income',
                        style: AppTextStyles.small(
                          context,
                          color: AppColors.getTextMuted(context),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppSizes.h12),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '₹${AppColors.formatShortAmount(totalIncome)}',
                      style: AppTextStyles.display(
                        context,
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                        fontSize: 20.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

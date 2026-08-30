import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:smart_money_tracker/core/constants/app_strings.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_sizes.dart';

class DisclosureHeader extends StatelessWidget {
  const DisclosureHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        SizedBox(height: AppSizes.h24),
        // Beautiful Animated Shield Icon with pulse or zoom
        Center(
          child: ZoomIn(
            duration: const Duration(milliseconds: 600),
            child: Container(
              padding: EdgeInsets.all(AppSizes.r24),
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(isDark ? 0.2 : 0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Icon(
                Icons.security_rounded,
                color: AppColors.white,
                size: AppSizes.r(56),
              ),
            ),
          ),
        ),
        SizedBox(height: AppSizes.h24),
        // Title
        FadeInDown(
          from: 15,
          duration: const Duration(milliseconds: 500),
          child: Text(
            'SMS Permission Required',
            style: AppTextStyles.heading(
              context,
            ).copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        SizedBox(height: AppSizes.h8),
        // Descriptions
        FadeInUp(
          from: 15,
          duration: const Duration(milliseconds: 600),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSizes.w8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Google Play Policy compliance: Prominent disclosure must clearly explain
                // what data is accessed (transactional SMS) and how it is used (categorization and insights).
                Text(
                  '${AppStrings.baseAppName} automatically detects and categorizes financial transactions from bank, UPI, wallet, and credit card SMS messages. All SMS processing is performed locally on your device. Personal conversations, OTPs, and non-financial messages are ignored and never processed. SMS access is a core feature required for automatic expense tracking.',
                  style: AppTextStyles.small(context),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppSizes.h12),
                Container(
                  padding: EdgeInsets.all(AppSizes.r12),
                  decoration: BoxDecoration(
                    color: AppColors.getSurface(context),
                    borderRadius: AppSizes.boxBorderRadius,
                    border: Border.all(
                      color: AppColors.isDark(context)
                          ? AppColors.surfaceContainerDark
                          : AppColors.surfaceContainerLight,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.black.withOpacity(
                          AppColors.isDark(context) ? 0.2 : 0.04,
                        ),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.security_rounded,
                            color: AppColors.success,
                            size: AppSizes.r16,
                          ),
                          SizedBox(width: AppSizes.w8),
                          Expanded(
                            child: Text(
                              'We do NOT collect personal conversations or OTP messages.',
                              style: AppTextStyles.small(context).copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.success,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: AppSizes.h8),
                      Row(
                        children: [
                          Icon(
                            Icons.verified_user_rounded,
                            color: AppColors.success,
                            size: AppSizes.r16,
                          ),
                          SizedBox(width: AppSizes.w8),
                          Expanded(
                            child: Text(
                              'Your data is never sold to third parties.',
                              style: AppTextStyles.small(context).copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.success,
                              ),
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
}

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
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(height: AppSizes.h24),
        // Beautiful Animated Shield Icon with pulse or zoom
        ZoomIn(
          duration: const Duration(milliseconds: 600),
          child: Container(
            padding: EdgeInsets.all(AppSizes.r24),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(isDark ? 0.05 : 0.08),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(
              Icons.security_rounded,
              color: AppColors.primary,
              size: AppSizes.r(56),
            ),
          ),
        ),
        SizedBox(height: AppSizes.h24),
        // Title
        FadeInDown(
          from: 15,
          duration: const Duration(milliseconds: 500),
          child: Text(
            'SMS & Notification Permissions Required',
            style: AppTextStyles.heading(context).copyWith(fontWeight: FontWeight.w800, fontSize: 24.sp),
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(height: AppSizes.h16),
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
                  '${AppStrings.baseAppName} automatically detects and categorizes financial transactions from bank, UPI, wallet, and credit card SMS messages. Transaction-related SMS messages and financial transaction notifications may be securely transmitted to our cloud-based processing services, which utilize Google Gemini AI for transaction extraction and categorization. Personal conversations, OTPs, and non-financial messages are ignored and never processed. SMS access is a core feature required for automatic expense tracking.',
                  style: AppTextStyles.body(context).copyWith(height: 1.5, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppSizes.h12),
                Container(
                  padding: EdgeInsets.all(AppSizes.r12),
                  decoration: BoxDecoration(
                    color: AppColors.getSurfaceContainer(
                      context,
                    ).withOpacity(0.5),
                    borderRadius: AppSizes.boxBorderRadius,
                    border: Border.all(
                      color: AppColors.getSurfaceContainer(context),
                      width: 1,
                    ),
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

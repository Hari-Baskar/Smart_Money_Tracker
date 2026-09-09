import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_money_tracker/core/constants/app_colors.dart';
import 'package:smart_money_tracker/core/constants/app_routes.dart';
import 'package:smart_money_tracker/core/constants/app_sizes.dart';
import 'package:smart_money_tracker/core/theme/app_text_styles.dart';
import 'package:smart_money_tracker/core/common/widgets/primary_button.dart';

Future<void> showEnableSmsScannerModal(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (bottomSheetContext) {
      final isDark = AppColors.isDark(bottomSheetContext);
      return Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSizes.r24),
          ),
        ),
        padding: EdgeInsets.fromLTRB(
          AppSizes.w24,
          AppSizes.h12,
          AppSizes.w24,
          AppSizes.h24,
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: AppSizes.w(48),
                  height: AppSizes.h4,
                  margin: EdgeInsets.only(bottom: AppSizes.h20),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.white.withValues(alpha: 0.2)
                        : AppColors.black.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppSizes.r(2)),
                  ),
                ),
              ),

              // Title
              Text(
                'SMS Scanner Disabled',
                style: AppTextStyles.subHeading(bottomSheetContext).copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.getText(bottomSheetContext),
                ),
              ),
              SizedBox(height: AppSizes.h12),

              // Description
              Text(
                'SMS permission and auto-sync are required to scan transaction alerts from your bank SMS messages.\n\n'
                'Please enable the SMS scanner in Settings to use this feature.',
                style: AppTextStyles.body(bottomSheetContext).copyWith(
                  color: AppColors.getTextMuted(bottomSheetContext),
                  height: 1.5,
                ),
              ),
              SizedBox(height: AppSizes.h24),

              // Action Button
              PrimaryButton(
                text: 'Go to Settings',
                onPressed: () {
                  Navigator.pop(bottomSheetContext);
                  context.push(AppRoutes.settings);
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

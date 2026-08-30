import 'package:flutter/material.dart';
import 'package:smart_money_tracker/core/theme/app_text_styles.dart';
import 'package:smart_money_tracker/core/constants/app_colors.dart';
import 'package:smart_money_tracker/core/constants/app_sizes.dart';
import 'package:smart_money_tracker/core/common/widgets/primary_button.dart';

Future<bool?> showStopBudgetBottomSheet(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.r24)),
    ),
    builder: (context) => SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSizes.w16,
          vertical: AppSizes.h24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(AppSizes.w12),
              decoration: BoxDecoration(
                color: AppColors.warning,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.stop_circle_outlined,
                color: AppColors.white,
                size: AppSizes.r24,
              ),
            ),
            SizedBox(height: AppSizes.h16),
            Text(
              'Stop Budget',
              style: AppTextStyles.heading(context),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSizes.h8),
            Text(
              'Are you sure you want to stop this budget? Once stopped, it cannot be restarted or resumed. It will keep its historical record but stop tracking future transactions.',
              style: AppTextStyles.body(context),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSizes.h24),
              Row(
                children: [
                  Expanded(
                    child: PrimaryButton(
                      text: 'Cancel',
                      isOutlined: true,
                      isExpanded: false,
                      onPressed: () => Navigator.of(context).pop(false),
                      foregroundColor: AppColors.getTextMuted(context),
                      borderColor: AppColors.getTextMuted(context).withValues(alpha: 0.3),
                      borderWidth: 0.5,
                    ),
                  ),
                  SizedBox(width: AppSizes.w12),
                  Expanded(
                    child: PrimaryButton(
                      text: 'Stop',
                      isExpanded: false,
                      backgroundColor: AppColors.warning,
                      onPressed: () => Navigator.of(context).pop(true),
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

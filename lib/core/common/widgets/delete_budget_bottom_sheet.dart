import 'package:flutter/material.dart';
import 'package:smart_money_tracker/core/theme/app_text_styles.dart';
import 'package:smart_money_tracker/core/constants/app_colors.dart';
import 'package:smart_money_tracker/core/constants/app_sizes.dart';
import 'package:smart_money_tracker/core/common/widgets/primary_button.dart';

Future<bool?> showDeleteBudgetBottomSheet(BuildContext context) {
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: AppSizes.w(40),
                height: AppSizes.h4,
                margin: EdgeInsets.only(bottom: AppSizes.h16),
                decoration: BoxDecoration(
                  color: AppColors.getTextMuted(context).withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(AppSizes.r100),
                ),
              ),
            ),
            Text(
              'Delete Budget',
              style: AppTextStyles.subHeading(context).copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: AppSizes.h8),
            Text(
              'Are you sure you want to delete this budget?',
              style: AppTextStyles.body(context),
            ),
            SizedBox(height: AppSizes.h24),
              Row(
                children: [
                  Expanded(
                    child: PrimaryButton(
                      text: 'Delete Budget',
                      isExpanded: true,
                      backgroundColor: AppColors.error,
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

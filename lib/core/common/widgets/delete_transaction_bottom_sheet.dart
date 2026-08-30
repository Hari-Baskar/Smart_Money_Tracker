import 'package:flutter/material.dart';
import 'package:smart_money_tracker/core/theme/app_text_styles.dart';
import 'package:smart_money_tracker/core/constants/app_colors.dart';
import 'package:smart_money_tracker/core/constants/app_sizes.dart';
import 'package:smart_money_tracker/core/common/widgets/primary_button.dart';

Future<bool?> showDeleteTransactionBottomSheet(BuildContext context, {bool isPermanent = false}) {
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
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.delete_outline_rounded,
                color: AppColors.white,
                size: AppSizes.r24,
              ),
            ),
            SizedBox(height: AppSizes.h16),
            Text(
              isPermanent ? 'Delete Permanently' : 'Delete Transaction',
              style: AppTextStyles.heading(context),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSizes.h8),
            Text(
              isPermanent 
                  ? 'Are you sure you want to permanently delete this transaction? This action cannot be undone.'
                  : 'Are you sure you want to delete this transaction? It will be moved to Manage Transactions.',
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
                      text: 'Delete',
                      isExpanded: false,
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

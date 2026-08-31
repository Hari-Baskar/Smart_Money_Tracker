import 'package:flutter/material.dart';
import 'package:smart_money_tracker/core/theme/app_text_styles.dart';
import 'package:smart_money_tracker/core/constants/app_colors.dart';
import 'package:smart_money_tracker/core/constants/app_sizes.dart';

Future<bool?> showDeleteTransactionDialog(BuildContext context, {bool isPermanent = false}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.r24),
      ),
      title: Text(
        isPermanent ? 'Delete Permanently' : 'Delete Transaction',
        style: AppTextStyles.subHeading(context).copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Text(
        isPermanent 
            ? 'Are you sure you want to permanently delete this transaction? This action cannot be undone.'
            : 'Are you sure you want to delete this transaction? It will be moved to Manage Transactions.',
        style: AppTextStyles.body(context),
      ),
      actionsPadding: EdgeInsets.only(
        right: AppSizes.w16,
        left: AppSizes.w16,
        bottom: AppSizes.h16,
        top: AppSizes.h8,
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: AppSizes.h12),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppSizes.cardBorderRadius,
                  ),
                ),
                child: Text('Cancel', style: AppTextStyles.body(context)),
              ),
            ),
            SizedBox(width: AppSizes.w12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: AppColors.white,
                  padding: EdgeInsets.symmetric(vertical: AppSizes.h12),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppSizes.cardBorderRadius,
                  ),
                ),
                child: Text(
                  'Delete',
                  style: AppTextStyles.body(
                    context,
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

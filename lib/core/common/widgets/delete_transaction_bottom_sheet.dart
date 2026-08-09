import 'package:flutter/material.dart';
import 'package:smart_money_tracker/core/theme/app_text_styles.dart';
import 'package:smart_money_tracker/core/constants/app_colors.dart';
import 'package:smart_money_tracker/core/constants/app_sizes.dart';

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
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.delete_outline_rounded,
                color: AppColors.error,
                size: AppSizes.r32,
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
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: AppSizes.h12),
                      side: BorderSide(color: Theme.of(context).colorScheme.outline),
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
                      style: AppTextStyles.body(context, color: AppColors.white),
                    ),
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

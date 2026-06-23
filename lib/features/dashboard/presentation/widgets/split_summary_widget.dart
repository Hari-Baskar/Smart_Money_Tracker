import 'package:flutter/material.dart';
import 'package:smart_money_tracker/core/constants/app_colors.dart';
import 'package:smart_money_tracker/core/constants/app_sizes.dart';
import 'package:smart_money_tracker/core/models/transaction_model.dart';
import 'package:smart_money_tracker/core/theme/app_text_styles.dart';

class SplitSummaryWidget extends StatelessWidget {
  final ValueNotifier<List<TransactionSplit>> splits;
  final TextEditingController amountController;

  const SplitSummaryWidget({
    super.key,
    required this.splits,
    required this.amountController,
  });

  @override
  Widget build(BuildContext context) {
    final totalSplit = splits.value.fold(0.0, (sum, item) => sum + item.amount);
    final totalAmount = double.tryParse(amountController.text) ?? 0.0;
    final remaining = totalAmount - totalSplit;
    final isMatched = remaining.abs() < 0.01;
    final isExceeded = remaining < -0.01;

    return Container(
      margin: EdgeInsets.only(top: AppSizes.h16),
      padding: EdgeInsets.all(AppSizes.r16),
      decoration: BoxDecoration(
        color: isMatched
            ? AppColors.success.withOpacity(0.05)
            : isExceeded
            ? AppColors.error.withOpacity(0.1)
            : AppColors.error.withOpacity(0.05),
        borderRadius: AppSizes.boxBorderRadius,
        border: Border.all(
          color: isMatched
              ? AppColors.success.withOpacity(0.2)
              : isExceeded
              ? AppColors.error
              : AppColors.error.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isMatched
                    ? 'Splits Matched'
                    : isExceeded
                    ? 'Amount Exceeded!'
                    : 'Remaining to Split',
                style: AppTextStyles.small(context, color: isMatched ? AppColors.success : AppColors.error),
              ),
              Text(
                isMatched ? '₹$totalSplit' : '₹${remaining.toStringAsFixed(2)}',
                style: AppTextStyles.body(context, color: isMatched ? AppColors.success : AppColors.error),
              ),
            ],
          ),
          if (isExceeded) ...[
            SizedBox(height: AppSizes.h8),
            Text(
              'Your split total (₹${totalSplit.toStringAsFixed(2)}) is more than the original amount (₹${totalAmount.toStringAsFixed(2)}). Please reduce the split amounts.',
              style: AppTextStyles.small(context, color: AppColors.error),
            ),
          ],
        ],
      ),
    );
  }
}

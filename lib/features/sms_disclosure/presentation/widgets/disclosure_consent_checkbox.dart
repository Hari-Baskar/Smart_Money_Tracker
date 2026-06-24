import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../providers/sms_disclosure_provider.dart';
import 'package:smart_money_tracker/core/constants/app_strings.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_sizes.dart';

class DisclosureConsentCheckbox extends ConsumerWidget {
  const DisclosureConsentCheckbox({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(smsDisclosureNotifierProvider);
    final notifier = ref.read(smsDisclosureNotifierProvider.notifier);

    return InkWell(
      onTap: () {
        notifier.toggleCheckbox(!state.isCheckboxChecked);
      },
      borderRadius: AppSizes.boxBorderRadius,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: AppSizes.h8, horizontal: AppSizes.w4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: AppSizes.r24,
              height: AppSizes.r24,
              child: Checkbox(
                value: state.isCheckboxChecked,
                onChanged: (val) {
                  notifier.toggleCheckbox(val ?? false);
                },
                activeColor: AppColors.primary,
                checkColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: AppSizes.boxBorderRadius,
                ),
                side: BorderSide(
                  color: state.isCheckboxChecked
                      ? AppColors.primary
                      : AppColors.getTextMuted(context).withOpacity(0.6),
                  width: 1.5,
                ),
              ),
            ),
            SizedBox(width: AppSizes.w12),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: AppSizes.h2),
                child: Text(
                  'I consent to ${AppStrings.baseAppName} accessing transaction-related SMS messages and financial payment notifications and securely transmitting relevant transaction data to cloud-based processing services that utilize a smart AI engine for expense tracking and transaction categorization.',
                  style: AppTextStyles.body(context).copyWith(
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                    color: state.isCheckboxChecked
                        ? AppColors.primary
                        : AppColors.getText(context),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

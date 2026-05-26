import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../providers/sms_disclosure_provider.dart';
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
      borderRadius: BorderRadius.circular(AppSizes.r12),
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
                  borderRadius: BorderRadius.circular(6.r),
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
                padding: EdgeInsets.only(top: 2.h),
                child: Text(
                  'I understand and consent to SMS access for transaction tracking',
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

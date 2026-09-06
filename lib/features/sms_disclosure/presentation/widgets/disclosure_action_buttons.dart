import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../providers/sms_disclosure_provider.dart';
import '../../../../core/constants/app_colors.dart';
import 'package:smart_money_tracker/core/theme/app_text_styles.dart';
import 'package:smart_money_tracker/core/common/widgets/primary_button.dart';
import '../../../../core/constants/app_sizes.dart';

class DisclosureActionButtons extends ConsumerWidget {
  final VoidCallback onContinue;
  final VoidCallback onNotNow;

  const DisclosureActionButtons({
    super.key,
    required this.onContinue,
    required this.onNotNow,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(smsDisclosureNotifierProvider);
    final notifier = ref.read(smsDisclosureNotifierProvider.notifier);

    final isConsentEnabled = state.isCheckboxChecked;

    return Column(
      children: [
        // Small consent text above the Continue button as required by Google Play policy guidelines.
        // It provides high transparency, detailing the affirmative consent action.
        Padding(
          padding: EdgeInsets.only(bottom: AppSizes.h12),
          child: Text(
            'By tapping Continue, you consent to the collection and secure processing of transaction-related SMS messages for automated expense tracking, categorization, and financial insights.',
            style: AppTextStyles.small(
              context,
              color: AppColors.getTextMuted(context),
            ).copyWith(height: 1.4),
            textAlign: TextAlign.center,
          ),
        ),
        // Continue button
        PrimaryButton(
          text: 'Continue',
          isLoading: state.isLoading,
          onPressed: isConsentEnabled && !state.isLoading && !state.isRejecting
              ? () async {
                  final success = await notifier.acceptConsent();
                  if (success) {
                    onContinue();
                  }
                }
              : null,
          contentPadding: EdgeInsets.symmetric(vertical: AppSizes.h10),
        ),
        SizedBox(height: AppSizes.h12),
        // Not Now button
        PrimaryButton(
          text: 'Not Now',
          isOutlined: true,
          isLoading: state.isRejecting,
          foregroundColor: AppColors.getTextMuted(context),
          borderColor: AppColors.getTextMuted(context).withOpacity(0.3),
          borderWidth: 1.5,
          onPressed: !state.isLoading && !state.isRejecting
              ? () async {
                  await notifier.rejectConsent();
                  onNotNow();
                }
              : null,
          contentPadding: EdgeInsets.symmetric(vertical: AppSizes.h10),
        ),
      ],
    );
  }
}

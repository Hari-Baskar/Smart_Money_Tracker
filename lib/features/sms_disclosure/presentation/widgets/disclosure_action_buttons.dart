import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../providers/sms_disclosure_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
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
            'By tapping Continue, you consent to the collection and secure processing of transaction-related SMS messages and financial transaction notifications for automated expense tracking, categorization, and financial insights.',
            style: AppTextStyles.small(context, color: AppColors.getTextMuted(context)).copyWith(
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        // Continue button
        SizedBox(
          width: double.infinity,
          height: AppSizes.h(50),
          child: ElevatedButton(
            onPressed: isConsentEnabled && !state.isLoading && !state.isRejecting
                ? () async {
                    final success = await notifier.acceptConsent();
                    if (success) {
                      onContinue();
                    }
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.primary.withOpacity(0.3),
              disabledForegroundColor: Colors.white.withOpacity(0.6),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: AppSizes.boxBorderRadius,
              ),
            ),
            child: state.isLoading
                ? SizedBox(
                    width: AppSizes.r20,
                    height: AppSizes.r20,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    'Continue',
                    style: AppTextStyles.body(context).copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        SizedBox(height: AppSizes.h12),
        // Not Now button
        SizedBox(
          width: double.infinity,
          height: AppSizes.h(50),
          child: OutlinedButton(
            onPressed: !state.isLoading && !state.isRejecting
                ? () async {
                    await notifier.rejectConsent();
                    onNotNow();
                  }
                : null,
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: AppColors.getSurfaceContainer(context),
                width: 1.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: AppSizes.boxBorderRadius,
              ),
              foregroundColor: AppColors.getTextMuted(context),
            ),
            child: state.isRejecting
                ? SizedBox(
                    width: AppSizes.r20,
                    height: AppSizes.r20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.getTextMuted(context),
                      ),
                    ),
                  )
                : Text(
                    'Not Now',
                    style: AppTextStyles.body(context).copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.getTextMuted(context),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

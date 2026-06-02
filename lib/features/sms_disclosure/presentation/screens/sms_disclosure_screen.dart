import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../widgets/disclosure_header.dart';
import '../widgets/disclosure_bullet_points.dart';
import '../widgets/disclosure_consent_checkbox.dart';
import '../widgets/disclosure_action_buttons.dart';

class SmsDisclosureScreen extends HookConsumerWidget {
  final VoidCallback onContinue;
  final VoidCallback onNotNow;
  final String? privacyPolicyUrl;

  const SmsDisclosureScreen({
    super.key,
    required this.onContinue,
    required this.onNotNow,
    this.privacyPolicyUrl,
  });

  Future<void> _handlePrivacyPolicyTap(BuildContext context) async {
    if (privacyPolicyUrl != null && privacyPolicyUrl!.isNotEmpty) {
      final uri = Uri.parse(privacyPolicyUrl!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    }

    // Fallback: Show a premium bottom sheet with the full privacy policy
    if (context.mounted) {
      _showPrivacyPolicyBottomSheet(context);
    }
  }

  void _showPrivacyPolicyBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.getSurface(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.boxRadius)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSizes.w24),
              child: Column(
                children: [
                  // Handlebar indicator
                  SizedBox(height: AppSizes.h12),
                  Container(
                    width: AppSizes.w(40),
                    height: AppSizes.h(4),
                    decoration: BoxDecoration(
                      color: AppColors.getSurfaceContainer(context),
                      borderRadius: AppSizes.boxBorderRadius,
                    ),
                  ),
                  SizedBox(height: AppSizes.h20),
                  // Sheet header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Privacy Policy',
                        style: AppTextStyles.heading(context),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Container(
                          padding: EdgeInsets.all(AppSizes.r(4)),
                          decoration: BoxDecoration(
                            color: AppColors.getSurfaceContainer(context),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            size: AppSizes.r(18),
                            color: AppColors.getText(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  SizedBox(height: AppSizes.h12),
                  // Privacy Policy Text
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      physics: const BouncingScrollPhysics(),
                      children: [
                        Text(
                          AppStrings.privacyPolicyContent,
                          style: AppTextStyles.body(context).copyWith(
                            height: 1.6,
                            color: AppColors.getText(context),
                          ),
                        ),
                        SizedBox(height: AppSizes.h32),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      AppSizes.w24,
                      AppSizes.h16,
                      AppSizes.w24,
                      AppSizes.h24,
                    ),
                    child: Column(
                      children: [
                        // Header Details
                        const DisclosureHeader(),

                        SizedBox(height: AppSizes.h24),

                        // Beautiful Bullet Points Details
                        const DisclosureBulletPoints(),

                        // Push everything remaining down
                        const Spacer(),

                        SizedBox(height: AppSizes.h16),

                        // Checkbox section
                        FadeInUp(
                          delay: const Duration(milliseconds: 350),
                          duration: const Duration(milliseconds: 400),
                          child: const DisclosureConsentCheckbox(),
                        ),

                        SizedBox(height: AppSizes.h16),

                        // Action buttons Continue / Not Now
                        FadeInUp(
                          delay: const Duration(milliseconds: 450),
                          duration: const Duration(milliseconds: 400),
                          child: DisclosureActionButtons(
                            onContinue: onContinue,
                            onNotNow: onNotNow,
                          ),
                        ),

                        SizedBox(height: AppSizes.h16),

                        // Privacy Policy Clickable Text
                        FadeInUp(
                          delay: const Duration(milliseconds: 550),
                          duration: const Duration(milliseconds: 400),
                          child: GestureDetector(
                            onTap: () => _handlePrivacyPolicyTap(context),
                            child: Text(
                              'Privacy Policy',
                              style: AppTextStyles.small(context).copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                                decorationColor: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

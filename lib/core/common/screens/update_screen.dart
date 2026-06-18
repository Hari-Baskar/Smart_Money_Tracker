import 'package:flutter/material.dart';
import 'package:smart_money_tracker/core/constants/app_colors.dart';
import 'package:smart_money_tracker/core/constants/app_sizes.dart';
import 'package:smart_money_tracker/core/constants/app_strings.dart';
import 'package:smart_money_tracker/core/theme/app_text_styles.dart';
import 'package:animate_do/animate_do.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateScreenArgs {
  final String currentVersion;
  final String newVersion;
  final bool isMandatory;
  final String? releaseNotes;
  final String? updateUrl;

  UpdateScreenArgs({
    required this.currentVersion,
    required this.newVersion,
    required this.isMandatory,
    this.releaseNotes,
    this.updateUrl,
  });
}

class UpdateScreen extends StatelessWidget {
  final UpdateScreenArgs args;

  const UpdateScreen({super.key, required this.args});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !args.isMandatory,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(AppSizes.w24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(flex: 2),
                FadeInDown(
                  child: Center(
                    child: Container(
                      padding: EdgeInsets.all(AppSizes.w24),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.05),
                        shape: BoxShape.circle,
                      ),
                      child: Image.asset(
                        AppStrings.appIconPath,
                        width: AppSizes.screenWidth * 0.35,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: AppSizes.h32),
                FadeInUp(
                  delay: const Duration(milliseconds: 100),
                  child: Text(
                    args.isMandatory
                        ? 'Critical Update Required'
                        : 'New Update Available',
                    style: AppTextStyles.heading(context).copyWith(
                      fontSize: AppSizes.r24,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: AppSizes.h12),
                FadeInUp(
                  delay: const Duration(milliseconds: 200),
                  child: Text(
                    'Version ${args.newVersion} is here! Your current version is ${args.currentVersion}.',
                    style: AppTextStyles.body(
                      context,
                      color: AppColors.getTextMuted(context),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const Spacer(flex: 3),
                FadeInUp(
                  delay: const Duration(milliseconds: 400),
                  child: args.isMandatory
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ElevatedButton(
                              onPressed: _launchURL,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: AppColors.white,
                                padding: EdgeInsets.symmetric(
                                    vertical: AppSizes.h16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: AppSizes.cardBorderRadius,
                                ),
                              ),
                              child: Text(
                                'Update Now',
                                style: AppTextStyles.body(
                                  context,
                                  color: AppColors.white,
                                ),
                              ),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(
                                      vertical: AppSizes.h16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: AppSizes.cardBorderRadius,
                                  ),
                                  side: BorderSide(
                                    color: Theme.of(context).colorScheme.outline,
                                  ),
                                ),
                                child: Text(
                                  'Later',
                                  style: AppTextStyles.body(
                                    context,
                                    color: AppColors.getTextMuted(context),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: AppSizes.w16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _launchURL,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: AppColors.white,
                                  padding: EdgeInsets.symmetric(
                                      vertical: AppSizes.h16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: AppSizes.cardBorderRadius,
                                  ),
                                ),
                                child: Text(
                                  'Update',
                                  style: AppTextStyles.body(
                                    context,
                                    color: AppColors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _launchURL() async {
    final url =
        args.updateUrl ??
        'https://play.google.com/store/apps/details?id=com.smart_money_tracker';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

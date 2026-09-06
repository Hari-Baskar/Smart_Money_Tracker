import 'package:flutter/material.dart';
import 'package:smart_money_tracker/core/constants/app_colors.dart';
import 'package:smart_money_tracker/core/constants/app_sizes.dart';
import 'package:smart_money_tracker/core/constants/app_strings.dart';
import 'package:smart_money_tracker/core/theme/app_text_styles.dart';
import 'package:animate_do/animate_do.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:smart_money_tracker/core/common/widgets/primary_button.dart';

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
                      padding: EdgeInsets.all(AppSizes.w16),
                      decoration: BoxDecoration(
                        color: args.isMandatory
                            ? AppColors.error
                            : AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        args.isMandatory
                            ? Icons.warning_rounded
                            : Icons.system_update_rounded,
                        size: AppSizes.screenWidth * 0.1,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: AppSizes.h16),
                FadeInUp(
                  delay: const Duration(milliseconds: 100),
                  child: Text(
                    args.isMandatory
                        ? 'Critical Update Required'
                        : 'New Update Available',
                    style: AppTextStyles.subHeading(
                      context,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: AppSizes.h8),
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
                            PrimaryButton(
                              text: 'Update Now',
                              onPressed: _launchURL,
                              contentPadding: EdgeInsets.symmetric(
                                vertical: AppSizes.h10,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: PrimaryButton(
                                text: 'Later',
                                isOutlined: true,
                                foregroundColor: AppColors.getTextMuted(
                                  context,
                                ),
                                borderColor: Theme.of(
                                  context,
                                ).colorScheme.outline,
                                onPressed: () => Navigator.pop(context),
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: AppSizes.h10,
                                ),
                              ),
                            ),
                            SizedBox(width: AppSizes.w16),
                            Expanded(
                              child: PrimaryButton(
                                text: 'Update',
                                onPressed: _launchURL,
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: AppSizes.h10,
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

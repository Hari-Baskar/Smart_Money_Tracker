import 'package:flutter/material.dart';
import 'package:smart_money_tracker/core/constants/app_colors.dart';
import 'package:smart_money_tracker/core/constants/app_sizes.dart';
import 'package:smart_money_tracker/core/theme/app_text_styles.dart';
import 'package:animate_do/animate_do.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class UpdateDialog extends StatelessWidget {
  final String currentVersion;
  final String newVersion;
  final bool isMandatory;
  final String? releaseNotes;
  final String? updateUrl;

  const UpdateDialog({
    super.key,
    required this.currentVersion,
    required this.newVersion,
    required this.isMandatory,
    this.releaseNotes,
    this.updateUrl,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !isMandatory,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
        child: FadeInUp(
          duration: const Duration(milliseconds: 400),
          child: Container(
            padding: EdgeInsets.all(AppSizes.h16),
            decoration: BoxDecoration(
              color: AppColors.getSurface(context),
              borderRadius: BorderRadius.circular(AppSizes.r24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80.w,
                  height: 80.w,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.system_update,
                    color: AppColors.primary,
                    size: 40.w,
                  ),
                ),
                SizedBox(height: AppSizes.h24),
                Text(
                  isMandatory
                      ? 'Critical Update Available'
                      : 'Update Available',
                  style: AppTextStyles.headline(
                    context,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppSizes.h8),
                Text(
                  'A new version ($newVersion) is available. Your current version is $currentVersion.',
                  style: AppTextStyles.body(
                    context,
                    color: AppColors.getTextMuted(context),
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: AppSizes.h24),
                Row(
                  children: [
                    if (!isMandatory)
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Later',
                            style: AppTextStyles.body(
                              context,
                              color: AppColors.getTextMuted(context),
                            ),
                          ),
                        ),
                      ),
                    if (!isMandatory) SizedBox(width: AppSizes.h16),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _launchURL,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSizes.r12),
                          ),
                        ),
                        child: Text(
                          'Update Now',
                          style: AppTextStyles.body(
                            context,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
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
        updateUrl ??
        'https://play.google.com/store/apps/details?id=com.hari.expense_tracker'; // Fallback
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_sizes.dart';

class DisclosureBulletPoints extends StatelessWidget {
  const DisclosureBulletPoints({super.key});

  @override
  Widget build(BuildContext context) {
    final bullets = [
      _BulletItem(
        icon: Icons.receipt_long_rounded,
        iconColor: AppColors.primary,
        title: 'Only Transaction SMS Processed',
        description: 'We scan and process only official bank, UPI, credit card, and transactional SMS messages.',
      ),
      _BulletItem(
        icon: Icons.phonelink_lock_rounded,
        iconColor: AppColors.primary,
        title: 'Zero OTP Collection',
        description: 'All one-time-passwords (OTPs) and critical auth codes are strictly ignored and never processed.',
      ),
      _BulletItem(
        icon: Icons.chat_bubble_outline_rounded,
        iconColor: AppColors.primary,
        title: 'No Personal Chat Scans',
        description: 'Your personal, private conversation text messages are completely skipped and never accessed.',
      ),
      _BulletItem(
        icon: Icons.lock_outline_rounded,
        iconColor: AppColors.success,
        title: 'Data is Never Sold',
        description: 'We enforce bank-level security. We never rent, share, or sell your financial data to anyone.',
      ),
    ];

    return Column(
      children: List.generate(bullets.length, (index) {
        final bullet = bullets[index];
        return FadeInLeft(
          delay: Duration(milliseconds: 100 * index),
          duration: const Duration(milliseconds: 400),
          child: Container(
            margin: EdgeInsets.only(bottom: AppSizes.h12),
            padding: EdgeInsets.all(AppSizes.r12),
            decoration: BoxDecoration(
              color: AppColors.getSurfaceContainerLowest(context),
              borderRadius: BorderRadius.circular(AppSizes.r16),
              border: Border.all(
                color: AppColors.getSurfaceContainer(context),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.15 : 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(AppSizes.r8),
                  decoration: BoxDecoration(
                    color: bullet.iconColor.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    bullet.icon,
                    color: bullet.iconColor,
                    size: AppSizes.r(18),
                  ),
                ),
                SizedBox(width: AppSizes.w12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bullet.title,
                        style: AppTextStyles.body(context).copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: AppSizes.h4),
                      Text(
                        bullet.description,
                        style: AppTextStyles.small(context, color: AppColors.getTextMuted(context)).copyWith(
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _BulletItem {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;

  _BulletItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
  });
}

import 'package:smart_money_tracker/core/constants/app_colors.dart';
import 'package:smart_money_tracker/core/theme/app_text_styles.dart';
import 'package:smart_money_tracker/core/services/sms_service.dart';
import 'package:smart_money_tracker/core/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PermissionDisclosureScreen extends HookConsumerWidget {
  const PermissionDisclosureScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final smsGranted = useState(false);
    final notificationsGranted = useState(false);
    final isMounted = useIsMounted();

    Future<void> grantSms() async {
      final granted = await SmsService().requestPermissions();
      if (isMounted()) smsGranted.value = granted;
    }

    Future<void> grantNotifications() async {
      await NotificationService.initialize();
      if (isMounted()) notificationsGranted.value = true;
    }

    Future<void> complete() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('permissions_disclosed', true);
      if (isMounted()) context.go('/dashboard');
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(32.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 48.h),
              Icon(
                Icons.security_rounded,
                color: AppColors.primary,
                size: 64.r,
              ),
              SizedBox(height: 32.h),
              Text(
                'Data Transparency & Privacy',
                style: AppTextStyles.display(context),
              ),
              SizedBox(height: 16.h),
              Text(
                'To automatically track your expenses, our "Smart Detection" system needs to read transaction alerts. Your financial data never leaves your device except to sync with your private cloud account.',
                style: AppTextStyles.body(context, color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              SizedBox(height: 40.h),

              _buildPermissionTile(
                context,
                title: 'SMS Access',
                description:
                    'Used to detect bank debits, credit card swipes, and ATM withdrawals.',
                icon: Icons.sms_rounded,
                isGranted: smsGranted.value,
                onTap: grantSms,
              ),

              SizedBox(height: 20.h),

              _buildPermissionTile(
                context,
                title: 'Notification Access',
                description:
                    'Required for UPI apps (GPay, PhonePe) that don\'t send SMS.',
                icon: Icons.notifications_active_rounded,
                isGranted: notificationsGranted.value,
                onTap: grantNotifications,
              ),
              SizedBox(height: 40.h),
              SizedBox(
                width: double.infinity,
                height: 56.h,
                child: ElevatedButton(
                  onPressed: complete,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'I Understand & Continue',
                    style: AppTextStyles.body(
                      context,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              Center(
                child: Text(
                  'You can change these in Settings anytime.',
                  style: AppTextStyles.small(
                    context,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionTile(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required bool isGranted,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: isGranted ? AppColors.success : Theme.of(context).colorScheme.surfaceVariant,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              color: isGranted
                  ? AppColors.success.withOpacity(0.1)
                  : AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isGranted ? AppColors.success : AppColors.primary,
              size: 20.r,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.body(
                    context,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  description,
                  style: AppTextStyles.small(
                    context,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onTap,
            icon: Icon(
              isGranted
                  ? Icons.check_circle_rounded
                  : Icons.add_circle_outline_rounded,
              color: isGranted ? AppColors.success : AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_money_tracker/core/constants/app_colors.dart';
import 'package:smart_money_tracker/core/constants/app_sizes.dart';
import 'package:smart_money_tracker/core/theme/app_text_styles.dart';
import 'package:smart_money_tracker/features/auth/presentation/providers/auth_provider.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/providers/settings_provider.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/screens/selection_setting_screen.dart';
import 'package:smart_money_tracker/core/utils/app_toast.dart';
import 'package:smart_money_tracker/core/services/notification_service.dart';
import 'package:smart_money_tracker/core/common/widgets/banner_ad_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/providers/transaction_provider.dart';
import 'package:smart_money_tracker/core/services/analytics_service.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:smart_money_tracker/core/services/security_service.dart';
import 'package:smart_money_tracker/core/services/app_review_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:smart_money_tracker/core/constants/app_toast_messages.dart';

class SettingsScreen extends HookConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requireAppLockOnLaunch = useState(true);
    final isDailyReminderEnabled = useState(true);
    final dailyReminderTime = useState(const TimeOfDay(hour: 21, minute: 0));

    useEffect(() {
      AnalyticsService.logScreenView('SettingsScreen');
      ref.read(securityServiceProvider).isAppLockEnabledOnLaunch().then((val) {
        if (context.mounted) requireAppLockOnLaunch.value = val;
      });
      SharedPreferences.getInstance().then((prefs) {
        if (context.mounted) {
          isDailyReminderEnabled.value =
              prefs.getBool('is_daily_reminder_enabled') ?? true;
          dailyReminderTime.value = TimeOfDay(
            hour: prefs.getInt('daily_reminder_time_hour') ?? 21,
            minute: prefs.getInt('daily_reminder_time_minute') ?? 0,
          );
        }
      });
      return null;
    }, const []);

    final settings = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AppBar(
        backgroundColor: AppColors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Theme.of(context).colorScheme.onBackground,
            size: AppSizes.r20,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text('Settings', style: AppTextStyles.heading(context)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppSizes.w12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Title
            Padding(
              padding: EdgeInsets.only(left: AppSizes.w4, bottom: AppSizes.h8),
              child: Text(
                'Preferences',
                style: AppTextStyles.body(
                  context,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),

            // Appearance Preference Card
            if (false) ...[
              Container(
                decoration: BoxDecoration(
                  color: AppColors.getSurface(context),
                  borderRadius: AppSizes.cardBorderRadius,
                  border: Border.all(
                    color: AppColors.isDark(context)
                        ? AppColors.surfaceContainerDark
                        : AppColors.surfaceContainerLight,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.black.withOpacity(
                        AppColors.isDark(context) ? 0.2 : 0.04,
                      ),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: SwitchListTile(
                  value: settings.themeMode == 'dark',
                  onChanged: (val) {
                    ref.read(settingsProvider.notifier).setThemeMode(val ? 'dark' : 'light');
                  },
                  secondary: Icon(
                    settings.themeMode == 'dark'
                        ? Icons.dark_mode_rounded
                        : Icons.light_mode_rounded,
                    color: AppColors.primary,
                    size: AppSizes.h24,
                  ),
                  title: Text('Appearance', style: AppTextStyles.body(context)),
                  subtitle: Text(
                    settings.themeMode == 'dark' ? 'Dark Mode' : 'Light Mode',
                    style: AppTextStyles.small(context),
                  ),
                  activeColor: AppColors.primary,
                ),
              ),
              SizedBox(height: AppSizes.h12),
            ],

            // Permissions Preference Card
            Container(
              decoration: BoxDecoration(
                color: AppColors.getSurface(context),
                borderRadius: AppSizes.cardBorderRadius,
                border: Border.all(
                  color: AppColors.isDark(context)
                      ? AppColors.surfaceContainerDark
                      : AppColors.surfaceContainerLight,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withOpacity(
                      AppColors.isDark(context) ? 0.2 : 0.04,
                    ),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListTile(
                onTap: () => context.push('/app-permissions'),
                leading: Icon(
                  Icons.security_rounded,
                  color: AppColors.primary,
                  size: AppSizes.h24,
                ),
                title: Text(
                  'App Permissions',
                  style: AppTextStyles.body(context),
                ),
                subtitle: Text(
                  'Manage biometric access',
                  style: AppTextStyles.small(context),
                ),
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  size: AppSizes.h24,
                ),
              ),
            ),

            SizedBox(height: AppSizes.h12),

            // App Lock Preference Card
            Container(
              decoration: BoxDecoration(
                color: AppColors.getSurface(context),
                borderRadius: AppSizes.cardBorderRadius,
                border: Border.all(
                  color: AppColors.isDark(context)
                      ? AppColors.surfaceContainerDark
                      : AppColors.surfaceContainerLight,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withOpacity(
                      AppColors.isDark(context) ? 0.2 : 0.04,
                    ),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: SwitchListTile(
                value: requireAppLockOnLaunch.value,
                onChanged: (val) async {
                  final securityService = ref.read(securityServiceProvider);

                  if (val) {
                    // Verify biometrics before enabling
                    final success = await securityService
                        .authenticateWithBiometrics(
                          'Verify to enable App Lock',
                        );
                    if (!success) {
                      if (context.mounted) {
                        AppToast.show(
                          context,
                          'Authentication failed. App Lock not enabled.',
                          isError: true,
                        );
                      }
                      return;
                    }
                  }

                  requireAppLockOnLaunch.value = val;
                  await securityService.setAppLockEnabledOnLaunch(val);

                  final user = ref.read(authRepositoryProvider).currentUser;
                  if (user != null) {
                    await ref.read(authRepositoryProvider).saveUserSettings(
                      user.id,
                      {'require_app_lock_on_launch': val},
                    );
                  }
                },
                secondary: Icon(
                  Icons.lock_rounded,
                  color: AppColors.primary,
                  size: AppSizes.h24,
                ),
                title: Text('App Lock', style: AppTextStyles.body(context)),
                subtitle: Text(
                  'Require authentication on launch',
                  style: AppTextStyles.small(context),
                ),
                activeColor: AppColors.primary,
              ),
            ),

            SizedBox(height: AppSizes.h12),

            // Daily Reminder Preference Card
            Container(
              decoration: BoxDecoration(
                color: AppColors.getSurface(context),
                borderRadius: AppSizes.cardBorderRadius,
                border: Border.all(
                  color: AppColors.isDark(context)
                      ? AppColors.surfaceContainerDark
                      : AppColors.surfaceContainerLight,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withOpacity(
                      AppColors.isDark(context) ? 0.2 : 0.04,
                    ),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    value: isDailyReminderEnabled.value,
                    onChanged: (val) async {
                      final prefs = await SharedPreferences.getInstance();

                      if (val) {
                        // Request Android 13+ notification permissions
                        final status = await Permission.notification.request();
                        if (status.isDenied || status.isPermanentlyDenied) {
                          if (context.mounted) {
                            AppToast.show(context, AppToastMessages.permissionRequired, isError: true);
                          }
                          return;
                        }

                        // Request exact alarm permission (Android 14+)
                        if (await Permission.scheduleExactAlarm.isDenied) {
                          final exactAlarmStatus = await Permission.scheduleExactAlarm.request();
                          if (exactAlarmStatus.isDenied && context.mounted) {
                             AppToast.show(context, AppToastMessages.permissionDenied, isError: true);
                          }
                        }
                      }

                      isDailyReminderEnabled.value = val;
                      await prefs.setBool('is_daily_reminder_enabled', val);

                      // Refresh the notification service schedule
                      final todayTransactions = ref.read(todayTransactionsProvider).value ?? [];
                      final hasTransactions = todayTransactions.isNotEmpty;
                      final hasUnknown = todayTransactions.any(
                        (t) => t.category == 'Other' && t.subcategory == 'General',
                      );

                      NotificationService.updateDailyReminderState(
                        hasTransactionsToday: hasTransactions,
                        hasUnknownTransactionsToday: hasUnknown,
                      );
                    },
                    secondary: Icon(
                      Icons.notifications_active_rounded,
                      color: AppColors.primary,
                      size: AppSizes.h24,
                    ),
                    title: Text(
                      'Daily Reminder',
                      style: AppTextStyles.body(context),
                    ),
                    subtitle: Text(
                      'Remind me to log expenses',
                      style: AppTextStyles.small(context),
                    ),
                    activeColor: AppColors.primary,
                  ),
                  if (isDailyReminderEnabled.value)
                    ListTile(
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: dailyReminderTime.value,
                        );
                        if (picked != null) {
                          dailyReminderTime.value = picked;
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setInt(
                            'daily_reminder_time_hour',
                            picked.hour,
                          );
                          await prefs.setInt(
                            'daily_reminder_time_minute',
                            picked.minute,
                          );

                          // Refresh the notification service schedule
                          final todayTransactions = ref.read(todayTransactionsProvider).value ?? [];
                          final hasTransactions = todayTransactions.isNotEmpty;
                          final hasUnknown = todayTransactions.any(
                            (t) => t.category == 'Other' && t.subcategory == 'General',
                          );

                          NotificationService.updateDailyReminderState(
                            hasTransactionsToday: hasTransactions,
                            hasUnknownTransactionsToday: hasUnknown,
                          );
                        }
                      },
                      leading: SizedBox(width: AppSizes.h24), // alignment
                      title: Text(
                        'Reminder Time',
                        style: AppTextStyles.body(context),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            dailyReminderTime.value.format(context),
                            style: AppTextStyles.body(
                              context,
                              color: AppColors.primary,
                            ),
                          ),
                          SizedBox(width: AppSizes.w8),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                            size: AppSizes.h24,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            SizedBox(height: AppSizes.h12),

            // Rate App Preference Card
            Container(
              decoration: BoxDecoration(
                color: AppColors.getSurface(context),
                borderRadius: AppSizes.cardBorderRadius,
                border: Border.all(
                  color: AppColors.isDark(context)
                      ? AppColors.surfaceContainerDark
                      : AppColors.surfaceContainerLight,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withOpacity(
                      AppColors.isDark(context) ? 0.2 : 0.04,
                    ),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListTile(
                onTap: () => AppReviewService().requestManualReview(),
                leading: Icon(
                  Icons.star_rounded,
                  color: AppColors.primary,
                  size: AppSizes.h24,
                ),
                title: Text('Rate App', style: AppTextStyles.body(context)),
                subtitle: Text(
                  'Enjoying the app? Leave a review',
                  style: AppTextStyles.small(context),
                ),
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  size: AppSizes.h24,
                ),
              ),
            ),

            SizedBox(height: AppSizes.h24),

            // Danger Zone Title
            Padding(
              padding: EdgeInsets.only(left: AppSizes.w4, bottom: AppSizes.h8),
              child: Text(
                'Danger Zone',
                style: AppTextStyles.body(context, color: AppColors.error),
              ),
            ),

            // Danger Zone Card
            Container(
              decoration: BoxDecoration(
                color: AppColors.getSurface(context),
                borderRadius: AppSizes.cardBorderRadius,
                border: Border.all(
                  color: AppColors.isDark(context)
                      ? AppColors.surfaceContainerDark
                      : AppColors.surfaceContainerLight,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withOpacity(
                      AppColors.isDark(context) ? 0.3 : 0.08,
                    ),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListTile(
                onTap: () => _showDeleteAccountDialog(context, ref),
                leading: Icon(
                  Icons.delete_forever_rounded,
                  color: AppColors.error,
                  size: AppSizes.h24,
                ),
                title: Text(
                  'Delete Account',
                  style: AppTextStyles.body(context, color: AppColors.error),
                ),
                subtitle: Text(
                  'Permanently delete your profile and transaction history',
                  style: AppTextStyles.small(
                    context,
                    color: AppColors.error.withOpacity(0.7),
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.error.withOpacity(0.5),
                  size: AppSizes.h24,
                ),
              ),
            ),
            SizedBox(height: AppSizes.h24),
            const BannerAdWidget(),
          ],
        ),
      ),
    );
  }

  void _showLoadingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: AppSizes.cardBorderRadius,
          ),
          child: Padding(
            padding: EdgeInsets.all(AppSizes.w24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: AppColors.primary),
                SizedBox(height: AppSizes.h20),
                Text(
                  message,
                  style: AppTextStyles.body(context),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showDeleteAccountDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.r24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + AppSizes.h24,
          left: AppSizes.w24,
          right: AppSizes.w24,
          top: AppSizes.h24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(AppSizes.w16),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.delete_forever_rounded,
                color: AppColors.error,
                size: AppSizes.h32,
              ),
            ),
            SizedBox(height: AppSizes.h20),
            Text('Delete Account', style: AppTextStyles.heading(context)),
            SizedBox(height: AppSizes.h12),
            Text(
              'This action is permanent and will delete all your transactions and profile data. You cannot undo this.',
              style: AppTextStyles.body(context),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSizes.h24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: AppSizes.h12),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppSizes.cardBorderRadius,
                      ),
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    child: Text('Cancel', style: AppTextStyles.body(context)),
                  ),
                ),
                SizedBox(width: AppSizes.w12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: AppColors.white,
                      padding: EdgeInsets.symmetric(vertical: AppSizes.h12),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppSizes.cardBorderRadius,
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Delete Forever',
                      style: AppTextStyles.body(
                        context,
                        color: AppColors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      try {
        AnalyticsService.logEvent('delete_account');
        await ref.read(authNotifierProvider.notifier).deleteAccount();

        // Clear local storage and caches immediately
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        await ref.read(securityServiceProvider).clearAll();
        ref.invalidate(transactionRepositoryProvider);
        ref.invalidate(settingsProvider);

        if (context.mounted) {
          context.go('/login');
        }
      } catch (e) {
        if (context.mounted) {
          AppToast.show(context, _getShortErrorMessage(e), isError: true);
        }
      }
    }
  }

  String _getShortErrorMessage(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'requires-recent-login':
          return 'Re-login is required';
        case 'reauthentication-failed':
          return 'Re-authentication failed';
        case 'reauthentication-cancelled':
          return 'Action cancelled';
        case 'user-mismatch':
          return 'Wrong Google account';
        case 'network-request-failed':
          return 'Network error occurred';
        case 'user-token-expired':
          return 'Session has expired';
        default:
          return 'Deletion failed';
      }
    }
    final message = error.toString().toLowerCase();
    if (message.contains('requires-recent-login')) {
      return 'Re-login is required';
    }
    if (message.contains('user-mismatch') || message.contains('mismatch')) {
      return 'Wrong Google account';
    }
    if (message.contains('cancelled')) {
      return 'Action cancelled';
    }
    if (message.contains('failed')) {
      return 'Re-authentication failed';
    }
    return 'Failed to delete';
  }
}

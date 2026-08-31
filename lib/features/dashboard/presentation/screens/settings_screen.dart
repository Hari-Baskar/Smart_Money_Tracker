import 'package:smart_money_tracker/core/common/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_money_tracker/core/constants/app_colors.dart';
import 'package:smart_money_tracker/core/constants/app_routes.dart';
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
    final prefs = ref.watch(sharedPreferencesProvider);
    final requireAppLockOnLaunch = useState<bool?>(null);
    final isDailyReminderEnabled = useState(
      prefs.getBool('is_daily_reminder_enabled') ?? true,
    );
    final dailyReminderTime = useState(
      TimeOfDay(
        hour: prefs.getInt('daily_reminder_time_hour') ?? 21,
        minute: prefs.getInt('daily_reminder_time_minute') ?? 0,
      ),
    );

    useEffect(() {
      AnalyticsService.logScreenView('SettingsScreen');
      ref.read(securityServiceProvider).isAppLockEnabledOnLaunch().then((val) {
        if (context.mounted) requireAppLockOnLaunch.value = val;
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
        title: Text('Settings', style: AppTextStyles.subHeading(context)),
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
              child: Text('Preferences', style: AppTextStyles.body(context)),
            ),

            // Appearance Preference Card
            Container(
              color: Colors.transparent,
              child: _buildSwitchTile(
                context,
                value: settings.themeMode == 'dark',
                onChanged: (val) {
                  ref
                      .read(settingsProvider.notifier)
                      .setThemeMode(val ? 'dark' : 'light');
                },
                leading: Container(
                  padding: EdgeInsets.all(AppSizes.r8),
                  decoration: const BoxDecoration(
                    color: Colors.purple,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    settings.themeMode == 'dark'
                        ? Icons.dark_mode_rounded
                        : Icons.light_mode_rounded,
                    color: Colors.white,
                    size: AppSizes.r20,
                  ),
                ),
                title: Text('Appearance', style: AppTextStyles.body(context)),
                subtitle: Text(
                  settings.themeMode == 'dark' ? 'Dark Mode' : 'Light Mode',
                  style: AppTextStyles.small(context),
                ),
              ),
            ),

            // Permissions Preference Card
            Container(
              color: Colors.transparent,
              child: _buildListTile(
                context,
                onTap: () => context.push('/app-permissions'),
                leading: Container(
                  padding: EdgeInsets.all(AppSizes.r8),
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.security_rounded,
                    color: Colors.white,
                    size: AppSizes.r20,
                  ),
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

            // App Lock Preference Card
            if (requireAppLockOnLaunch.value == null)
              Padding(
                padding: EdgeInsets.symmetric(vertical: AppSizes.h12),
                child: const Center(child: CircularProgressIndicator()),
              )
            else
              Container(
                color: Colors.transparent,
                child: _buildSwitchTile(
                  context,
                  value: requireAppLockOnLaunch.value!,
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
                  leading: Container(
                    padding: EdgeInsets.all(AppSizes.r8),
                    decoration: const BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.lock_rounded,
                      color: Colors.white,
                      size: AppSizes.r20,
                    ),
                  ),
                  title: Text('App Lock', style: AppTextStyles.body(context)),
                  subtitle: Text(
                    'Require authentication on launch',
                    style: AppTextStyles.small(context),
                  ),
                ),
              ),

            // Daily Reminder Preference Card
            Container(
              color: Colors.transparent,
              child: Column(
                children: [
                  _buildSwitchTile(
                    context,
                    value: isDailyReminderEnabled.value,
                    onChanged: (val) async {
                      final prefs = await SharedPreferences.getInstance();

                      if (val) {
                        // Request Android 13+ notification permissions
                        final status = await Permission.notification.request();
                        if (status.isDenied || status.isPermanentlyDenied) {
                          if (context.mounted) {
                            AppToast.show(
                              context,
                              AppToastMessages.permissionRequired,
                              isError: true,
                            );
                          }
                          return;
                        }

                        // Request exact alarm permission (Android 14+)
                        if (await Permission.scheduleExactAlarm.isDenied) {
                          final exactAlarmStatus = await Permission
                              .scheduleExactAlarm
                              .request();
                          if (exactAlarmStatus.isDenied && context.mounted) {
                            AppToast.show(
                              context,
                              AppToastMessages.permissionDenied,
                              isError: true,
                            );
                          }
                        }
                      }

                      isDailyReminderEnabled.value = val;
                      await prefs.setBool('is_daily_reminder_enabled', val);

                      // Refresh the notification service schedule
                      final todayTransactions =
                          ref.read(todayTransactionsProvider).value ?? [];
                      final hasTransactions = todayTransactions.isNotEmpty;
                      final hasUnknown = todayTransactions.any(
                        (t) =>
                            t.category == 'Other' && t.subcategory == 'General',
                      );

                      NotificationService.updateDailyReminderState(
                        hasTransactionsToday: hasTransactions,
                        hasUnknownTransactionsToday: hasUnknown,
                      );
                    },
                    leading: Container(
                      padding: EdgeInsets.all(AppSizes.r8),
                      decoration: const BoxDecoration(
                        color: Colors.teal,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.notifications_active_rounded,
                        color: Colors.white,
                        size: AppSizes.r20,
                      ),
                    ),
                    title: Text(
                      'Daily Reminder',
                      style: AppTextStyles.body(context),
                    ),
                    subtitle: Text(
                      'Remind me to log expenses',
                      style: AppTextStyles.small(context),
                    ),
                  ),
                  if (isDailyReminderEnabled.value)
                    _buildListTile(
                      context,
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
                          final todayTransactions =
                              ref.read(todayTransactionsProvider).value ?? [];
                          final hasTransactions = todayTransactions.isNotEmpty;
                          final hasUnknown = todayTransactions.any(
                            (t) =>
                                t.category == 'Other' &&
                                t.subcategory == 'General',
                          );

                          NotificationService.updateDailyReminderState(
                            hasTransactionsToday: hasTransactions,
                            hasUnknownTransactionsToday: hasUnknown,
                          );
                        }
                      },
                      leading: SizedBox(width: AppSizes.r24), // alignment
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

            // Rate App Preference Card
            Container(
              color: Colors.transparent,
              child: _buildListTile(
                context,
                onTap: () => AppReviewService().requestManualReview(),
                leading: Container(
                  padding: EdgeInsets.all(AppSizes.r8),
                  decoration: const BoxDecoration(
                    color: Colors.amber,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.star_rounded,
                    color: Colors.white,
                    size: AppSizes.r20,
                  ),
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
              child: Text('Danger Zone', style: AppTextStyles.body(context)),
            ),

            // Danger Zone Card
            Container(
              color: Colors.transparent,
              child: _buildListTile(
                context,
                onTap: () => _showLogoutDialog(context, ref),
                leading: Container(
                  padding: EdgeInsets.all(AppSizes.r8),
                  decoration: const BoxDecoration(
                    color: AppColors.black,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.power_settings_new_rounded,
                    color: AppColors.white,
                    size: AppSizes.r20,
                  ),
                ),
                title: Text(
                  'Sign Out',
                  style: AppTextStyles.body(
                    context,
                    color: AppColors.getText(context),
                  ),
                ),
                subtitle: Text(
                  'Securely sign out of your account',
                  style: AppTextStyles.small(
                    context,
                    color: AppColors.getTextMuted(context),
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  size: AppSizes.h24,
                ),
              ),
            ),
            Container(
              color: Colors.transparent,
              child: _buildListTile(
                context,
                onTap: () => _showDeleteAccountDialog(context, ref),
                leading: Container(
                  padding: EdgeInsets.all(AppSizes.r8),
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.delete_rounded,
                    color: Colors.white,
                    size: AppSizes.r20,
                  ),
                ),
                title: Text(
                  'Delete Account',
                  style: AppTextStyles.body(context),
                ),
                subtitle: Text(
                  'Permanently delete your profile and transaction history',
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
            const BannerAdWidget(),
          ],
        ),
      ),
    );
  }

  Widget _buildListTile(
    BuildContext context, {
    required Widget leading,
    required Widget title,
    Widget? subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: AppSizes.h12),
        child: Row(
          children: [
            leading,
            SizedBox(width: AppSizes.w16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  title,
                  if (subtitle != null) ...[
                    SizedBox(height: AppSizes.h4),
                    subtitle,
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    BuildContext context, {
    required Widget leading,
    required Widget title,
    Widget? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return _buildListTile(
      context,
      leading: leading,
      title: title,
      subtitle: subtitle,
      onTap: () => onChanged(!value),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary,
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
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.delete_rounded,
                color: AppColors.white,
                size: AppSizes.h24,
              ),
            ),
            SizedBox(height: AppSizes.h20),
            Text(
              'Delete Account',
              style: AppTextStyles.subHeading(
                context,
                fontWeight: FontWeight.bold,
              ),
            ),
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
                  child: PrimaryButton(
                    text: 'Cancel',
                    isOutlined: true,
                    foregroundColor: AppColors.getText(context),
                    isExpanded: false,
                    onPressed: () => Navigator.pop(context, false),
                  ),
                ),
                SizedBox(width: AppSizes.w12),
                Expanded(
                  child: PrimaryButton(
                    text: 'Delete Forever',
                    isExpanded: false,
                    onPressed: () => Navigator.pop(context, true),
                    backgroundColor: AppColors.error,
                    foregroundColor: AppColors.white,
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

  Future<void> _showLogoutDialog(BuildContext context, WidgetRef ref) async {
    final shouldLogout = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.r24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.all(AppSizes.w24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sign Out',
                style: AppTextStyles.subHeading(
                  context,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: AppSizes.h12),
              Text(
                'Are you sure you want to securely sign out of your account?',
                style: AppTextStyles.body(context),
              ),
              SizedBox(height: AppSizes.h24),
              Row(
                children: [
                  Expanded(
                    child: PrimaryButton(
                      text: 'Cancel',
                      isOutlined: true,
                      foregroundColor: AppColors.getText(
                        context,
                      ).withValues(alpha: 0.3),
                      isExpanded: false,
                      onPressed: () => Navigator.pop(context, false),
                    ),
                  ),
                  SizedBox(width: AppSizes.w12),
                  Expanded(
                    child: PrimaryButton(
                      text: 'Sign Out',
                      isExpanded: false,
                      onPressed: () => Navigator.pop(context, true),
                      backgroundColor: AppColors.getText(context),
                      foregroundColor: AppColors.getBackground(context),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (shouldLogout == true) {
      AnalyticsService.logEvent('logout');
      await ref.read(authNotifierProvider.notifier).signOut();
      if (context.mounted) {
        context.go(AppRoutes.login);
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

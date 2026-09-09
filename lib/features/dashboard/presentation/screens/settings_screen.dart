import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_money_tracker/core/common/widgets/primary_button.dart';
import 'package:smart_money_tracker/core/constants/app_colors.dart';
import 'package:smart_money_tracker/core/constants/app_routes.dart';
import 'package:smart_money_tracker/core/constants/app_sizes.dart';
import 'package:smart_money_tracker/core/models/transaction_model.dart';
import 'package:smart_money_tracker/core/theme/app_text_styles.dart';
import 'package:smart_money_tracker/features/auth/presentation/providers/auth_provider.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/providers/settings_provider.dart';
import 'package:smart_money_tracker/core/utils/app_toast.dart';
import 'package:smart_money_tracker/core/services/notification_service.dart';
import 'package:smart_money_tracker/core/services/sms_service.dart';
import 'package:smart_money_tracker/core/common/widgets/banner_ad_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/providers/transaction_provider.dart';
import 'package:smart_money_tracker/core/services/analytics_service.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:smart_money_tracker/core/services/security_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:smart_money_tracker/features/sms_disclosure/presentation/providers/sms_disclosure_provider.dart';

class SettingsScreen extends HookConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final requireAppLockOnLaunch = useState<bool?>(null);
    final appVersion = useState<String>('');

    // OS-level permission and feature state
    final isSmsGranted = useState(false);
    final hasConsented = useState(false);
    final isMasterNotifGranted = useState(false);
    final isTxnNotifGranted = useState(true);
    final isDailyNotifGranted = useState(true);
    final isAwaitingSettings = useState(false);

    final isSmsToggled = settings.smsConsentEnabled && isSmsGranted.value;
    final isNotificationToggled = isMasterNotifGranted.value;

    Future<void> checkPermissionStatuses() async {
      if (!context.mounted) return;
      try {
        final smsPermission = await Permission.sms.isGranted;
        final notifStatus =
            await NotificationService.checkOsNotificationStatus();
        final consented = await ref
            .read(smsConsentRepositoryProvider)
            .hasConsented();

        if (context.mounted) {
          isSmsGranted.value = smsPermission;
          isMasterNotifGranted.value = notifStatus.isMasterGranted;
          isTxnNotifGranted.value = notifStatus.isTransactionEnabled;
          isDailyNotifGranted.value = notifStatus.isDailySummaryEnabled;
          hasConsented.value = consented;

          if (notifStatus.isDailySummaryEnabled) {
            final todayTransactions =
                ref.read(todayTransactionsProvider).value ?? [];
            double totalExpense = 0.0;
            double totalIncome = 0.0;
            for (final t in todayTransactions) {
              if (t.type == TransactionType.credit) {
                totalIncome += t.amount;
              } else {
                totalExpense += t.amount;
              }
            }
            await NotificationService.updateDailyReminderState(
              totalIncome: totalIncome,
              totalExpense: totalExpense,
            );
          } else {
            await NotificationService.cancelDailyReminder();
          }

          if (isAwaitingSettings.value && smsPermission) {
            isAwaitingSettings.value = false;
            await ref.read(smsConsentRepositoryProvider).saveConsent(true);
            await ref.read(settingsProvider.notifier).toggleSmsConsent(true);
            final user = ref.read(authRepositoryProvider).currentUser;
            if (user != null) {
              await ref.read(transactionSyncProvider.notifier).sync();
            }
          } else if (isAwaitingSettings.value) {
            isAwaitingSettings.value = false;
          }
        }
      } catch (e) {
        debugPrint('Error checking permissions in settings: $e');
      }
    }

    useEffect(() {
      AnalyticsService.logScreenView('SettingsScreen');
      ref.read(securityServiceProvider).isAppLockEnabledOnLaunch().then((val) {
        if (context.mounted) requireAppLockOnLaunch.value = val;
      });
      PackageInfo.fromPlatform().then((info) {
        if (context.mounted) {
          appVersion.value = 'Version ${info.version}';
        }
      });

      checkPermissionStatuses();
      final observer = _SettingsLifecycleObserver(
        onResume: checkPermissionStatuses,
      );
      WidgetsBinding.instance.addObserver(observer);
      return () => WidgetsBinding.instance.removeObserver(observer);
    }, const []);

    // 1. Handle Transaction SMS Reading toggle
    Future<void> handleSmsToggle(bool enabled) async {
      try {
        final consentRepo = ref.read(smsConsentRepositoryProvider);
        if (enabled) {
          final hasConsentedBefore = await consentRepo.hasConsented();
          if (!hasConsentedBefore) {
            if (context.mounted) {
              final result = await context.push<bool>('/permissions');
              await checkPermissionStatuses();
              if (result != true) {
                return;
              }
            }
          }

          final status = await Permission.sms.status;
          bool smsGrantedResult = false;
          if (status.isGranted) {
            smsGrantedResult = true;
          } else if (status.isPermanentlyDenied) {
            isAwaitingSettings.value = true;
            await openAppSettings();
            return;
          } else {
            smsGrantedResult = await SmsService().requestPermissions();
          }
          isSmsGranted.value = smsGrantedResult;

          if (smsGrantedResult) {
            await ref.read(settingsProvider.notifier).toggleSmsConsent(true);
            await consentRepo.saveConsent(true);
            final user = ref.read(authRepositoryProvider).currentUser;
            if (user != null) {
              await ref.read(transactionSyncProvider.notifier).sync();
            }
          } else {
            await ref.read(settingsProvider.notifier).toggleSmsConsent(false);
          }
        } else {
          await ref.read(settingsProvider.notifier).toggleSmsConsent(false);
        }
        await checkPermissionStatuses();
      } catch (e) {
        debugPrint('Error toggling SMS tracking: $e');
      }
    }

    // 2. Handle Daily Summary Notification toggle
    Future<void> handleNotificationToggle(bool enabled) async {
      try {
        if (enabled) {
          final status = await Permission.notification.status;
          bool notifGrantedResult = false;
          if (status.isGranted) {
            notifGrantedResult = true;
          } else if (status.isPermanentlyDenied) {
            isAwaitingSettings.value = true;
            await openAppSettings();
            return;
          } else {
            final requestStatus = await Permission.notification.request();
            notifGrantedResult = requestStatus.isGranted;
          }

          if (await Permission.scheduleExactAlarm.isDenied) {
            await Permission.scheduleExactAlarm.request();
          }

          isMasterNotifGranted.value = notifGrantedResult;
          if (notifGrantedResult) {
            final todayTransactions =
                ref.read(todayTransactionsProvider).value ?? [];
            double totalExpense = 0.0;
            double totalIncome = 0.0;
            for (final t in todayTransactions) {
              if (t.type == TransactionType.credit) {
                totalIncome += t.amount;
              } else {
                totalExpense += t.amount;
              }
            }
            await NotificationService.updateDailyReminderState(
              totalIncome: totalIncome,
              totalExpense: totalExpense,
            );
          } else {
            isAwaitingSettings.value = true;
            await openAppSettings();
            return;
          }
        } else {
          // Redirect to OS app settings to allow user to turn off notifications in system settings
          isAwaitingSettings.value = true;
          await openAppSettings();
        }
        await checkPermissionStatuses();
      } catch (e) {
        debugPrint('Error toggling notification: $e');
      }
    }

    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AppBar(
        backgroundColor: AppColors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: Theme.of(context).colorScheme.onSurface,
            size: AppSizes.r20,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text('Settings', style: AppTextStyles.subHeading(context)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(vertical: AppSizes.h12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                title: Text(
                  settings.themeMode == 'dark' ? 'Dark Mode' : 'Light Mode',
                  style: AppTextStyles.body(context),
                ),
              ),
            ),
            Divider(height: AppSizes.h16, thickness: 0.5),

            // SMS Reading Preference Card
            Container(
              color: Colors.transparent,
              child: _buildSwitchTile(
                context,
                value: isSmsToggled,
                onChanged: handleSmsToggle,
                title: Text('SMS Reading', style: AppTextStyles.body(context)),
                subtitle: Text(
                  'Automatically tracks transactional bank SMS',
                  style: AppTextStyles.small(
                    context,
                    color: AppColors.getTextMuted(context),
                  ),
                ),
              ),
            ),
            Divider(height: AppSizes.h16, thickness: 0.5),

            // Notifications Preference Card
            Container(
              color: Colors.transparent,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSwitchTile(
                    context,
                    value: isNotificationToggled,
                    onChanged: handleNotificationToggle,
                    title: Text(
                      'Notifications',
                      style: AppTextStyles.body(context),
                    ),
                  ),
                  if (isMasterNotifGranted.value &&
                      (!isTxnNotifGranted.value ||
                          !isDailyNotifGranted.value)) ...[
                    Padding(
                      padding: EdgeInsets.only(
                        left: AppSizes.w16,
                        top: AppSizes.h4,
                        bottom: AppSizes.h4,
                      ),
                      child: Column(
                        children: [
                          if (!isTxnNotifGranted.value)
                            _buildSwitchTile(
                              context,
                              value: isTxnNotifGranted.value,
                              onChanged: (_) async {
                                isAwaitingSettings.value = true;
                                await openAppSettings();
                              },
                              title: Text(
                                'Transactions',
                                style: AppTextStyles.body(context),
                              ),
                            ),
                          if (!isTxnNotifGranted.value &&
                              !isDailyNotifGranted.value)
                            SizedBox(height: AppSizes.h4),
                          if (!isDailyNotifGranted.value)
                            _buildSwitchTile(
                              context,
                              value: isDailyNotifGranted.value,
                              onChanged: (_) async {
                                isAwaitingSettings.value = true;
                                await openAppSettings();
                              },
                              title: Text(
                                'Daily Summary',
                                style: AppTextStyles.body(context),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Divider(height: AppSizes.h16, thickness: 0.5),

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
                  title: Text('App Lock', style: AppTextStyles.body(context)),
                ),
              ),
            if (requireAppLockOnLaunch.value != null)
              Divider(height: AppSizes.h16, thickness: 0.5),

            // Danger Zone Card
            Container(
              color: Colors.transparent,
              child: _buildListTile(
                context,
                onTap: () => _showLogoutDialog(context, ref),
                title: Text(
                  'Sign Out',
                  style: AppTextStyles.body(
                    context,
                    color: AppColors.getText(context),
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  size: AppSizes.h24,
                ),
              ),
            ),
            Divider(height: AppSizes.h16, thickness: 0.5),
            Container(
              color: Colors.transparent,
              child: _buildListTile(
                context,
                onTap: () => _showDeleteAccountDialog(context, ref),
                title: Text(
                  'Delete Account',
                  style: AppTextStyles.body(context),
                ),
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  size: AppSizes.h24,
                ),
              ),
            ),
            Divider(height: AppSizes.h16, thickness: 0.5),
            SizedBox(height: AppSizes.h24),
            if (appVersion.value.isNotEmpty)
              Center(
                child: Text(
                  appVersion.value,
                  style: AppTextStyles.small(
                    context,
                  ).copyWith(color: AppColors.getTextMuted(context)),
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
    required Widget title,
    Widget? subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: AppSizes.h4,
          horizontal: AppSizes.w12,
        ),
        child: Row(
          children: [
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
            ?trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    BuildContext context, {
    required Widget title,
    Widget? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return _buildListTile(
      context,
      title: title,
      subtitle: subtitle,
      onTap: () => onChanged(!value),
      trailing: Transform.scale(
        scale: 0.8,
        child: Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppColors.getText(context),
          activeTrackColor: AppColors.getText(context).withValues(alpha: 0.3),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: AppSizes.w(40),
                height: AppSizes.h4,
                margin: EdgeInsets.only(bottom: AppSizes.h16),
                decoration: BoxDecoration(
                  color: AppColors.getTextMuted(context).withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(AppSizes.r100),
                ),
              ),
            ),
            Text(
              'Delete Account',
              style: AppTextStyles.subHeading(
                context,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: AppSizes.h8),
            Text(
              'This action is permanent and will delete all your transactions and profile data. You cannot undo this.',
              style: AppTextStyles.body(context),
              textAlign: TextAlign.left,
            ),
            SizedBox(height: AppSizes.h24),
            Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    text: 'Delete Forever',
                    isExpanded: true,
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
              Center(
                child: Container(
                  width: AppSizes.w(40),
                  height: AppSizes.h4,
                  margin: EdgeInsets.only(bottom: AppSizes.h16),
                  decoration: BoxDecoration(
                    color: AppColors.getTextMuted(
                      context,
                    ).withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(AppSizes.r100),
                  ),
                ),
              ),
              Text(
                'Sign Out',
                style: AppTextStyles.subHeading(
                  context,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: AppSizes.h8),
              Text(
                'Are you sure you want to securely sign out of your account?',
                style: AppTextStyles.body(context),
              ),
              SizedBox(height: AppSizes.h24),
              Row(
                children: [
                  Expanded(
                    child: PrimaryButton(
                      text: 'Sign Out',
                      isExpanded: true,
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

class _SettingsLifecycleObserver extends WidgetsBindingObserver {
  final Future<void> Function() onResume;

  _SettingsLifecycleObserver({required this.onResume});

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      onResume();
    }
  }
}

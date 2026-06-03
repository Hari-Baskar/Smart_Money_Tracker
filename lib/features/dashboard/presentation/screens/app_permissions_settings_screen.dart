import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:notification_listener_service/notification_listener_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_money_tracker/core/constants/app_colors.dart';
import 'package:smart_money_tracker/core/constants/app_sizes.dart';
import 'package:smart_money_tracker/core/theme/app_text_styles.dart';
import 'package:smart_money_tracker/core/services/sms_service.dart';
import 'package:smart_money_tracker/core/services/notification_service.dart';
import 'package:smart_money_tracker/core/utils/app_toast.dart';
import 'package:smart_money_tracker/features/sms_disclosure/presentation/providers/sms_disclosure_provider.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/providers/transaction_provider.dart';
import 'package:smart_money_tracker/features/auth/presentation/providers/auth_provider.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/providers/settings_provider.dart';

class AppPermissionsSettingsScreen extends HookConsumerWidget {
  const AppPermissionsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMounted = useIsMounted();
    final settings = ref.watch(settingsProvider);

    // OS-level permission statuses
    final isSmsGranted = useState(false);
    final isNotificationGranted = useState(false);
    final hasConsented = useState(false);
    final hasSubmitted = useState(false);

    // Switch toggle states reflect both user settings choice and active OS-level permission status
    final isSmsToggled = settings.smsConsentEnabled && isSmsGranted.value;
    final isNotificationToggled =
        settings.notificationListenerEnabled && isNotificationGranted.value;

    // Loading states for background processing
    final isLoading = useState(true);

    // Helper method to load permission statuses
    Future<void> checkStatus() async {
      if (!isMounted()) return;

      try {
        final smsPermission = await Permission.sms.isGranted;
        final notifPermission =
            await NotificationListenerService.isPermissionGranted();
        final consented = await ref
            .read(smsConsentRepositoryProvider)
            .hasConsented();
        final prefs = await SharedPreferences.getInstance();
        final submitted = prefs.getBool('permissions_disclosed') ?? false;

        if (isMounted()) {
          isSmsGranted.value = smsPermission;
          isNotificationGranted.value = notifPermission;
          hasConsented.value = consented;
          hasSubmitted.value = submitted;
          isLoading.value = false;
        }
      } catch (e) {
        debugPrint('Error loading settings states: $e');
        if (isMounted()) {
          isLoading.value = false;
        }
      }
    }

    // Run check on initialization
    useEffect(() {
      checkStatus();

      // Dynamic lifecycle observer to re-check when returning from system app settings
      final observer = _AppPermissionsLifecycleObserver(onResume: checkStatus);
      WidgetsBinding.instance.addObserver(observer);

      return () {
        WidgetsBinding.instance.removeObserver(observer);
      };
    }, []);

    // 1. Handle Transaction SMS Reading toggle
    Future<void> handleSmsToggle(bool enabled) async {
      try {
        final consentRepo = ref.read(smsConsentRepositoryProvider);

        if (enabled) {
          // Check if they have consented before. If not, show the prominent disclosure consent screen BEFORE asking OS permission
          final hasConsentedBefore = await consentRepo.hasConsented();
          if (!hasConsentedBefore) {
            final prefs = await SharedPreferences.getInstance();
            final submitted = prefs.getBool('permissions_disclosed') ?? false;
            if (!submitted) {
              if (isMounted()) {
                context.push('/permissions');
              }
              return;
            } else {
              // If already submitted, directly save consent to true!
              await consentRepo.saveConsent(true);
            }
          }

          // Request OS runtime SMS permission FIRST before enabling the toggle (dot)
          final status = await Permission.sms.status;
          bool smsGrantedResult = false;
          if (status.isGranted) {
            smsGrantedResult = true;
          } else if (status.isPermanentlyDenied) {
            await openAppSettings();
          } else {
            smsGrantedResult = await SmsService().requestPermissions();
          }
          isSmsGranted.value = smsGrantedResult;

          if (smsGrantedResult) {
            // Set in-app consent flag to true in settings notifier (Riverpod) & repository only after permission is granted
            await ref.read(settingsProvider.notifier).toggleSmsConsent(true);
            await consentRepo.saveConsent(true);

            // Instantly trigger synchronization and scanning
            final authState = ref.read(authStateProvider);
            final userId = authState.value?.id;
            if (userId != null) {
              await ref.read(transactionSyncProvider.notifier).sync();
            }
          } else {
            await ref.read(settingsProvider.notifier).toggleSmsConsent(false);
          }
        } else {
          // User turned it off -> turn off toggle and stop scanning (we do NOT revoke disclosure consent)
          await ref.read(settingsProvider.notifier).toggleSmsConsent(false);
        }
        await checkStatus();
      } catch (e) {
        debugPrint('Error toggling SMS tracking: $e');
      }
    }

    // 2. Handle Payment Notification Listener toggle
    Future<void> handleNotificationToggle(bool enabled) async {
      try {
        if (enabled) {
          // Check if they have consented before. If not, show the prominent disclosure consent screen BEFORE asking OS permission
          final consentRepo = ref.read(smsConsentRepositoryProvider);
          final hasConsentedBefore = await consentRepo.hasConsented();
          if (!hasConsentedBefore) {
            final prefs = await SharedPreferences.getInstance();
            final submitted = prefs.getBool('permissions_disclosed') ?? false;
            if (!submitted) {
              if (isMounted()) {
                context.push('/permissions');
              }
              return;
            } else {
              // If already submitted, directly save consent to true!
              await consentRepo.saveConsent(true);
            }
          }

          // Request OS-level Special Notification Listener permission FIRST before enabling the toggle (dot)
          bool granted =
              await NotificationListenerService.isPermissionGranted();
          if (!granted) {
            granted = await NotificationListenerService.requestPermission();
          }
          isNotificationGranted.value = granted;

          if (granted) {
            await ref
                .read(settingsProvider.notifier)
                .toggleNotificationListener(true);
            await NotificationService.initialize(forceRequest: false);
          } else {
            await ref
                .read(settingsProvider.notifier)
                .toggleNotificationListener(false);
          }
        } else {
          // User turned it off -> turn off listener toggle (we do NOT revoke disclosure consent)
          await ref
              .read(settingsProvider.notifier)
              .toggleNotificationListener(false);
        }
        await checkStatus();
      } catch (e) {
        debugPrint('Error toggling Notification listener: $e');
      }
    }

    Widget buildStatusBadge(bool toggled, bool permissionGranted) {
      if (!toggled) {
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppSizes.w8,
            vertical: AppSizes.h(2),
          ),
          decoration: BoxDecoration(
            color: AppColors.getTextMuted(context).withOpacity(0.12),
            borderRadius: AppSizes.boxBorderRadius,
          ),
          child: Text(
            'Disabled',
            style: AppTextStyles.body(context).copyWith(
              color: AppColors.getTextMuted(context),
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      }

      if (permissionGranted) {
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppSizes.w8,
            vertical: AppSizes.h(2),
          ),
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.12),
            borderRadius: AppSizes.boxBorderRadius,
          ),
          child: Text(
            'Active & Connected',
            style: AppTextStyles.body(
              context,
            ).copyWith(color: AppColors.success, fontWeight: FontWeight.bold),
          ),
        );
      }

      return GestureDetector(
        onTap: () async {
          await openAppSettings();
        },
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppSizes.w8,
            vertical: AppSizes.h(2),
          ),
          decoration: BoxDecoration(
            color: AppColors.error.withOpacity(0.12),
            borderRadius: AppSizes.boxBorderRadius,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Permission Required',
                style: AppTextStyles.body(
                  context,
                ).copyWith(color: AppColors.error, fontWeight: FontWeight.bold),
              ),
              SizedBox(width: AppSizes.w4),
              Icon(
                Icons.open_in_new_rounded,
                color: AppColors.error,
                size: AppSizes.r8,
              ),
            ],
          ),
        ),
      );
    }

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
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('App Permissions', style: AppTextStyles.heading(context)),
        centerTitle: true,
      ),
      body: isLoading.value
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.all(AppSizes.w12),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Explanation Card
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(AppSizes.r16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.06),
                      borderRadius: AppSizes.cardBorderRadius,
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.12),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: AppColors.primary,
                              size: AppSizes.r20,
                            ),
                            SizedBox(width: AppSizes.w8),
                            Text(
                              'Privacy-Focused Controls',
                              style: AppTextStyles.body(
                                context,
                              ).copyWith(color: AppColors.primary),
                            ),
                          ],
                        ),
                        SizedBox(height: AppSizes.h8),
                        Text(
                          'Decide how your transactions are tracked. Turning off these options immediately stops in-app processing, scanning, and listening. All controls are secure and localized.',
                          style: AppTextStyles.small(
                            context,
                          ).copyWith(height: 1.4),
                        ),
                      ],
                    ),
                  ),

                  if (!hasConsented.value) ...[
                    SizedBox(height: AppSizes.h16),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(AppSizes.r16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        borderRadius: AppSizes.cardBorderRadius,
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.gavel_rounded,
                                color: AppColors.primary,
                                size: AppSizes.r20,
                              ),
                              SizedBox(width: AppSizes.w8),
                              Text(
                                'Consent Required',
                                style: AppTextStyles.body(
                                  context,
                                ).copyWith(color: AppColors.primary),
                              ),
                            ],
                          ),
                          SizedBox(height: AppSizes.h8),
                          Text(
                            'To enable SMS and Notification tracking, you must first read and accept our prominent privacy disclosure consent form.',
                            style: AppTextStyles.small(
                              context,
                            ).copyWith(height: 1.4),
                          ),
                          SizedBox(height: AppSizes.h12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () async {
                                await context.push('/permissions');
                                checkStatus();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: AppColors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: AppSizes.boxBorderRadius,
                                ),
                                elevation: 0,
                                padding: EdgeInsets.symmetric(
                                  vertical: AppSizes.h12,
                                ),
                              ),
                              child: Text(
                                'Consent Now',
                                style: AppTextStyles.body(
                                  context,
                                ).copyWith(color: AppColors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  SizedBox(height: AppSizes.h24),

                  // Section Title
                  Padding(
                    padding: EdgeInsets.only(
                      left: AppSizes.w4,
                      bottom: AppSizes.h12,
                    ),
                    child: Text(
                      'TRACKING PREFERENCES',
                      style: AppTextStyles.small(
                        context,
                        color: AppColors.getTextMuted(context),
                      ),
                    ),
                  ),

                  // Permissions Cards
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.getSurfaceContainerLowest(context),
                      borderRadius: AppSizes.boxBorderRadius,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.black.withOpacity(
                            AppColors.isDark(context) ? 0.15 : 0.03,
                          ),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // SMS Switch Tile
                        Padding(
                          padding: EdgeInsets.all(AppSizes.r16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(AppSizes.r8),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(
                                        0.08,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.sms_rounded,
                                      color: AppColors.primary,
                                      size: AppSizes.r20,
                                    ),
                                  ),
                                  SizedBox(width: AppSizes.w12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'SMS Reading',
                                              style: AppTextStyles.body(
                                                context,
                                              ),
                                            ),
                                            Switch.adaptive(
                                              value: isSmsToggled,
                                              onChanged: hasConsented.value
                                                  ? handleSmsToggle
                                                  : null,
                                              activeColor: AppColors.primary,
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: AppSizes.h4),
                                        Text(
                                          'Automatically parse transactional bank, UPI, and credit card SMS messages to record your expenses instantly.',
                                          style: AppTextStyles.small(
                                            context,
                                            color: AppColors.getTextMuted(
                                              context,
                                            ),
                                          ).copyWith(height: 1.4),
                                        ),
                                        SizedBox(height: AppSizes.h12),
                                        buildStatusBadge(
                                          isSmsToggled,
                                          isSmsGranted.value,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSizes.w24,
                          ),
                          child: Divider(
                            height: 1,
                            color: AppColors.getSurfaceContainer(context),
                          ),
                        ),

                        // Notification Listener Switch Tile
                        Padding(
                          padding: EdgeInsets.all(AppSizes.r16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(AppSizes.r8),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(
                                        0.08,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.notifications_active_rounded,
                                      color: AppColors.primary,
                                      size: AppSizes.r20,
                                    ),
                                  ),
                                  SizedBox(width: AppSizes.w12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Notification Listener',
                                              style: AppTextStyles.body(
                                                context,
                                              ),
                                            ),
                                            Switch.adaptive(
                                              value: isNotificationToggled,
                                              onChanged: hasConsented.value
                                                  ? handleNotificationToggle
                                                  : null,
                                              activeColor: AppColors.primary,
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: AppSizes.h4),
                                        Text(
                                          'Detect financial alerts and instantly import transactions from push notifications of payment apps like GPay, PhonePe, Paytm.',
                                          style: AppTextStyles.small(
                                            context,
                                            color: AppColors.getTextMuted(
                                              context,
                                            ),
                                          ).copyWith(height: 1.4),
                                        ),
                                        SizedBox(height: AppSizes.h12),
                                        buildStatusBadge(
                                          isNotificationToggled,
                                          isNotificationGranted.value,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _AppPermissionsLifecycleObserver extends WidgetsBindingObserver {
  final Future<void> Function() onResume;

  _AppPermissionsLifecycleObserver({required this.onResume});

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      onResume();
    }
  }
}

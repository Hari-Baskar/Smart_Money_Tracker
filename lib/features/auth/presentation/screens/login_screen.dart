import 'package:smart_money_tracker/core/constants/app_colors.dart';
import 'package:smart_money_tracker/core/services/security_service.dart';
import 'package:smart_money_tracker/core/theme/app_text_styles.dart';
import 'package:smart_money_tracker/core/constants/app_sizes.dart';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter/gestures.dart';
import 'package:smart_money_tracker/core/constants/app_strings.dart';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:smart_money_tracker/features/auth/presentation/providers/auth_provider.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/providers/transaction_provider.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/providers/restore_provider.dart';

class LoginScreen extends HookConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMounted = useIsMounted();
    final isGoogleLoading = useState(false);
    final isGuestLoading = useState(false);
    final isLoading = isGoogleLoading.value || isGuestLoading.value;

    Future<void> handlePostLoginNavigation() async {
      final user = ref.read(authStateProvider).value;
      if (user != null && !user.isAnonymous) {
        var settings = await ref
            .read(authRepositoryProvider)
            .getUserSettings(user.id);

        // 0. Ensure PIN is created
        final securityService = ref.read(securityServiceProvider);
        final localPin = await securityService.getLocalPin();

        if (settings == null || !settings.containsKey('pin_hash')) {
          bool created = false;
          if (isMounted()) {
            created = await context.push<bool>('/create-pin') ?? false;
          }
          if (!created) {
            await ref.read(authNotifierProvider.notifier).signOut();
            return;
          }
          // Refresh settings after creation
          settings = await ref
              .read(authRepositoryProvider)
              .getUserSettings(user.id);
        } else if (localPin == null) {
          // New device or cleared data: Must verify existing cloud PIN
          String? verifiedPin;
          if (isMounted()) {
            verifiedPin = await context.push<String?>(
              '/verify-pin',
              extra: {'targetHash': settings['pin_hash']},
            );
          }
          if (verifiedPin == null) {
            await ref.read(authNotifierProvider.notifier).signOut();
            return;
          }
          final require = settings['require_pin_on_launch'] as bool? ?? true;
          await securityService.saveLocalPin(verifiedPin, require);
        }

        // 1. Device Locking Check
        final deviceInfo = DeviceInfoPlugin();
        String? currentDeviceId;
        String? currentDeviceName;

        if (Platform.isAndroid) {
          final androidInfo = await deviceInfo.androidInfo;
          currentDeviceId = androidInfo.id;
          currentDeviceName =
              '${androidInfo.manufacturer} ${androidInfo.model}';
        } else if (Platform.isIOS) {
          final iosInfo = await deviceInfo.iosInfo;
          currentDeviceId = iosInfo.identifierForVendor;
          currentDeviceName = iosInfo.name;
        }

        if (settings != null && settings.containsKey('active_device_id')) {
          final activeDeviceId = settings['active_device_id'] as String?;
          final activeDeviceName = settings['active_device_name'] as String?;

          if (activeDeviceId != null && activeDeviceId != currentDeviceId) {
            bool forceLogin = false;
            if (isMounted()) {
              forceLogin =
                  await context.push<bool>(
                    '/force-logout',
                    extra: activeDeviceName,
                  ) ??
                  false;
            }

            if (forceLogin) {
              final pinHash = settings['pin_hash'] as String?;
              if (pinHash != null) {
                String? pinResult;
                if (isMounted()) {
                  pinResult = await context.push<String?>(
                    '/verify-pin',
                    extra: {'targetHash': pinHash},
                  );
                }
                if (pinResult == null) {
                  forceLogin = false;
                }
              }
            }

            if (!forceLogin) {
              await ref.read(authNotifierProvider.notifier).signOut();
              return; // Abort login
            }
          }
        }

        // 2. Update device lock if force logged in or first time
        if (currentDeviceId != null) {
          await ref.read(authRepositoryProvider).saveUserSettings(user.id, {
            'active_device_id': currentDeviceId,
            'active_device_name': currentDeviceName,
          });
        }

        // 3. Update local prefs from settings
        if (settings != null) {
          final prefs = await SharedPreferences.getInstance();
          if (settings.containsKey('permissions_disclosed')) {
            await prefs.setBool(
              'permissions_disclosed',
              settings['permissions_disclosed'] as bool,
            );
          }
          if (settings.containsKey('sms_consent')) {
            await prefs.setBool('sms_consent', settings['sms_consent'] as bool);
          }
        }

        // 4. Sync / Restore check
        final localCount = await ref
            .read(transactionRepositoryProvider)
            .getLocalTransactionCount(user.id);
        final remoteCount = await ref
            .read(transactionRepositoryProvider)
            .getRemoteTransactionCount(user.id);

        if (localCount == 0 && remoteCount > 0) {
          await ref
              .read(restoreNotifierProvider.notifier)
              .setRestoreCount(remoteCount);
          if (isMounted()) context.go('/sync-disclosure');
          return;
        } else if (remoteCount > localCount) {
          // Delta Sync silently in background
          ref
              .read(transactionRepositoryProvider)
              .restoreTransactions(user.id)
              .catchError((e) {
                print('Error during background delta sync: $e');
              });
        }
      }

      final prefs = await SharedPreferences.getInstance();
      final disclosed = prefs.getBool('permissions_disclosed') ?? false;
      if (isMounted()) {
        if (!disclosed) {
          context.go('/permissions');
        } else {
          context.go('/dashboard');
        }
      }
    }

    Future<void> loginWithGoogle() async {
      isGoogleLoading.value = true;
      try {
        final success = await ref
            .read(authNotifierProvider.notifier)
            .signInWithGoogle();
        if (!success) return;

        await handlePostLoginNavigation();
      } catch (e) {
        if (isMounted()) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(e.toString())));
        }
      } finally {
        if (isMounted()) isGoogleLoading.value = false;
      }
    }

    final termsRecognizer = useMemoized(
      () => TapGestureRecognizer()
        ..onTap = () {
          context.push(
            '/settings-detail',
            extra: {
              'title': 'Terms & Conditions',
              'content': AppStrings.termsAndConditionsContent,
            },
          );
        },
    );

    final privacyRecognizer = useMemoized(
      () => TapGestureRecognizer()
        ..onTap = () {
          context.push(
            '/settings-detail',
            extra: {
              'title': 'Privacy Policy',
              'content': AppStrings.privacyPolicyContent,
            },
          );
        },
    );

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: AppSizes.w32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 3),
              FadeInDown(
                duration: const Duration(milliseconds: 1000),
                child: Image.asset(
                  AppStrings.appIconPath,

                  width: AppSizes.screenWidth * 0.4,
                ),
              ),

              FadeInDown(
                delay: const Duration(milliseconds: 200),
                child: Text(
                  AppStrings.baseAppName,
                  style: AppTextStyles.heading(
                    context,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  ),
                ),
              ),
              SizedBox(height: AppSizes.h8),
              FadeInDown(
                delay: const Duration(milliseconds: 400),
                child: Text(
                  'Master your finances with intelligence and ease.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body(
                    context,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const Spacer(flex: 3),
              FadeInUp(
                delay: const Duration(milliseconds: 600),
                child: Column(
                  children: [
                    Text(
                      'Sign in to get started',
                      style: AppTextStyles.body(
                        context,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(height: AppSizes.h24),
                    SizedBox(
                      width: double.infinity,

                      child: ElevatedButton(
                        onPressed: isLoading ? null : loginWithGoogle,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.white,
                          foregroundColor: AppColors.black,
                          elevation: 2,
                          shadowColor: AppColors.black.withOpacity(0.07),
                          shape: RoundedRectangleBorder(
                            borderRadius: AppSizes.boxBorderRadius,
                            side: BorderSide(
                              color: AppColors.textMuted,
                              width: 1,
                            ),
                          ),
                        ),
                        child: isGoogleLoading.value
                            ? SizedBox(
                                height: AppSizes.r24,
                                width: AppSizes.r24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: AppColors.primary,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    'assets/images/google.png',
                                    height: AppSizes.r24,
                                    width: AppSizes.r24,
                                  ),
                                  SizedBox(width: AppSizes.w16),
                                  Text(
                                    'Continue with Google',
                                    style: AppTextStyles.body(
                                      context,
                                      color: AppColors.black,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    SizedBox(height: AppSizes.h16),
                  ],
                ),
              ),
              const Spacer(flex: 1),
              FadeInUp(
                delay: const Duration(milliseconds: 800),
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: AppTextStyles.small(
                      context,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurfaceVariant.withOpacity(0.6),
                    ),
                    children: [
                      TextSpan(
                        text: 'By continuing, you agree to our ',
                        style: AppTextStyles.body(context),
                      ),
                      TextSpan(
                        text: 'Terms & Conditions',
                        style: AppTextStyles.body(
                          context,
                          color: AppColors.primary,
                        ).copyWith(decoration: TextDecoration.underline),
                        recognizer: termsRecognizer,
                      ),
                      TextSpan(
                        text: ' and ',
                        style: AppTextStyles.body(context),
                      ),
                      TextSpan(
                        text: 'Privacy Policy',
                        style: AppTextStyles.body(
                          context,
                          color: AppColors.primary,
                        ).copyWith(decoration: TextDecoration.underline),
                        recognizer: privacyRecognizer,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: AppSizes.h24),
            ],
          ),
        ),
      ),
    );
  }
}

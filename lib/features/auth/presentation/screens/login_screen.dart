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
import 'package:firebase_auth/firebase_auth.dart';

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
        final securityService = ref.read(securityServiceProvider);
        final deviceInfo = DeviceInfoPlugin();
        final firebaseUser = FirebaseAuth.instance.currentUser;

        // Fast-path for brand new users to skip network checks
        final isNewUser =
            firebaseUser != null &&
            firebaseUser.metadata.creationTime != null &&
            firebaseUser.metadata.lastSignInTime != null &&
            firebaseUser.metadata.creationTime!
                    .difference(firebaseUser.metadata.lastSignInTime!)
                    .inSeconds
                    .abs() <
                5;

        // Perform ALL network and local I/O concurrently!
        final results = await Future.wait([
          isNewUser
              ? Future.value(null)
              : ref.read(authRepositoryProvider).getUserSettings(user.id),
          ref
              .read(transactionRepositoryProvider)
              .getLocalTransactionCount(user.id),
          isNewUser
              ? Future.value(0)
              : ref
                    .read(transactionRepositoryProvider)
                    .getRemoteTransactionCount(user.id),
          Platform.isAndroid ? deviceInfo.androidInfo : Future.value(null),
          Platform.isIOS ? deviceInfo.iosInfo : Future.value(null),
          SharedPreferences.getInstance(),
        ]);

        var settings = results[0] as Map<String, dynamic>?;
        final localCount = results[1] as int;
        final remoteCount = results[2] as int;
        final androidInfo = results[3] as AndroidDeviceInfo?;
        final iosInfo = results[4] as IosDeviceInfo?;
        final prefs = results[5] as SharedPreferences;

        String? currentDeviceId;
        String? currentDeviceName;

        if (androidInfo != null) {
          currentDeviceId = androidInfo.id;
          currentDeviceName =
              '${androidInfo.manufacturer} ${androidInfo.model}';
        } else if (iosInfo != null) {
          currentDeviceId = iosInfo.identifierForVendor;
          currentDeviceName = iosInfo.name;
        }

        // 1. Device Locking Check
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

            if (!forceLogin) {
              await ref.read(authNotifierProvider.notifier).signOut();
              return; // Abort login
            }
          }
        }

        // 2. Update device lock if force logged in or first time (Fire and forget!)
        if (currentDeviceId != null) {
          ref.read(authRepositoryProvider).saveUserSettings(user.id, {
            'active_device_id': currentDeviceId,
            'active_device_name': currentDeviceName,
          });
        }

        // 3. Update local prefs from settings (Fire and forget!)
        if (settings != null) {
          if (settings.containsKey('permissions_disclosed')) {
            prefs.setBool(
              'permissions_disclosed',
              settings['permissions_disclosed'] as bool,
            );
          }
          if (settings.containsKey('sms_consent')) {
            prefs.setBool('sms_consent', settings['sms_consent'] as bool);
          }
        }

        // 4. Sync / Restore check
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

        final disclosed = prefs.getBool('permissions_disclosed') ?? false;
        if (isMounted()) {
          if (!disclosed) {
            context.go('/permissions');
          } else {
            context.go('/dashboard');
          }
        }
      } else {
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
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.background,
              AppColors.getSurfaceContainerLowest(context),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              // Top illustration / logo area
              FadeInDown(
                duration: const Duration(milliseconds: 800),
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
              SizedBox(height: AppSizes.h32),
              FadeInUp(
                delay: const Duration(milliseconds: 200),
                duration: const Duration(milliseconds: 800),
                child: Text(
                  AppStrings.baseAppName,
                  style: AppTextStyles.heading(
                    context,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  ),
                ),
              ),
              SizedBox(height: AppSizes.h12),
              FadeInUp(
                delay: const Duration(milliseconds: 400),
                duration: const Duration(milliseconds: 800),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSizes.w24),
                  child: Text(
                    'Master your finances with intelligence and ease.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body(
                      context,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ).copyWith(height: 1.4),
                  ),
                ),
              ),
              const Spacer(flex: 2),
              // Bottom action area
              FadeInUp(
                delay: const Duration(milliseconds: 600),
                duration: const Duration(milliseconds: 800),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(AppSizes.w32),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(AppSizes.r32),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Get Started',
                        style: AppTextStyles.heading(context, fontSize: 24),
                      ),
                      SizedBox(height: AppSizes.h32),
                      SizedBox(
                        width: double.infinity,
                        height: 56.h,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : loginWithGoogle,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                AppColors.getSurfaceContainerLowest(context),
                            foregroundColor: AppColors.getText(context),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppSizes.r16),
                              side: BorderSide(
                                color: Theme.of(
                                  context,
                                ).colorScheme.outline.withOpacity(0.3),
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
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      SizedBox(height: AppSizes.h24),
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: AppTextStyles.small(
                            context,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                          children: [
                            TextSpan(text: 'By continuing, you agree to our\n'),
                            TextSpan(
                              text: 'Terms & Conditions',
                              style: AppTextStyles.small(
                                context,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                              recognizer: termsRecognizer,
                            ),
                            TextSpan(text: ' and '),
                            TextSpan(
                              text: 'Privacy Policy',
                              style: AppTextStyles.small(
                                context,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                              recognizer: privacyRecognizer,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: MediaQuery.of(context).padding.bottom),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

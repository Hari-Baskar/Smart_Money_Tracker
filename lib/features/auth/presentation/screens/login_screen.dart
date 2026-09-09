import 'package:smart_money_tracker/core/constants/app_colors.dart';
import 'package:smart_money_tracker/core/constants/app_sizes.dart';
import 'package:smart_money_tracker/core/services/security_service.dart';
import 'package:smart_money_tracker/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
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
    final isGoogleLoading = useState(false);
    final isCheckingAuth = useState(true);
    final isDark = AppColors.isDark(context);

    useEffect(() {
      Future<void> checkAuth() async {
        try {
          final user = ref.read(authRepositoryProvider).currentUser;
          if (user != null) {
            final prefs = await SharedPreferences.getInstance();
            final disclosed = prefs.getBool('permissions_disclosed') ?? false;
            final securityService = ref.read(securityServiceProvider);
            final targetRoute = disclosed ? '/dashboard' : '/permissions';
            final requiresLock = await securityService
                .isAppLockEnabledOnLaunch();

            if (!context.mounted) return;

            if (requiresLock) {
              context.go('/app-lock', extra: targetRoute);
            } else {
              context.go(targetRoute);
            }
            return;
          }
        } catch (e) {
          debugPrint('Auth check error: $e');
        }

        if (context.mounted) {
          isCheckingAuth.value = false;
        }
      }

      checkAuth();
      return null;
    }, []);

    Future<void> handlePostLoginNavigation() async {
      final user = ref.read(authStateProvider).value;
      if (user != null && !user.isAnonymous) {
        final deviceInfo = DeviceInfoPlugin();
        final firebaseUser = FirebaseAuth.instance.currentUser;

        final isNewUser =
            firebaseUser != null &&
            firebaseUser.metadata.creationTime != null &&
            firebaseUser.metadata.lastSignInTime != null &&
            firebaseUser.metadata.creationTime!
                    .difference(firebaseUser.metadata.lastSignInTime!)
                    .inSeconds
                    .abs() <
                5;

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

        if (settings != null && settings.containsKey('active_device_id')) {
          final activeDeviceId = settings['active_device_id'] as String?;
          final activeDeviceName = settings['active_device_name'] as String?;

          if (activeDeviceId != null && activeDeviceId != currentDeviceId) {
            bool forceLogin = false;
            if (context.mounted) {
              forceLogin =
                  await context.push<bool>(
                    '/force-logout',
                    extra: activeDeviceName,
                  ) ??
                  false;
            }

            if (!forceLogin) {
              await ref.read(authNotifierProvider.notifier).signOut();
              return;
            }
          }
        }

        if (currentDeviceId != null) {
          ref.read(authRepositoryProvider).saveUserSettings(user.id, {
            'active_device_id': currentDeviceId,
            'active_device_name': currentDeviceName,
          });
        }

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

        ref
            .read(transactionRepositoryProvider)
            .fetchIgnoredTransactionsFromCloud(user.id)
            .catchError((e) {
              debugPrint('Error fetching ignored transactions silently: $e');
            });

        if (localCount == 0 && remoteCount > 0) {
          await ref
              .read(restoreNotifierProvider.notifier)
              .setRestoreCount(remoteCount);
          if (context.mounted) context.go('/sync-disclosure');
          return;
        } else if (remoteCount > localCount) {
          ref
              .read(transactionRepositoryProvider)
              .restoreTransactions(user.id)
              .catchError((e) {
                debugPrint('Error during background delta sync: $e');
              });
        }

        final disclosed = prefs.getBool('permissions_disclosed') ?? false;
        if (context.mounted) {
          if (!disclosed) {
            context.go('/permissions');
          } else {
            context.go('/dashboard');
          }
        }
      } else {
        final prefs = await SharedPreferences.getInstance();
        final disclosed = prefs.getBool('permissions_disclosed') ?? false;
        if (context.mounted) {
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
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(e.toString())));
        }
      } finally {
        isGoogleLoading.value = false;
      }
    }

    final termsRecognizer = useMemoized(
      () => TapGestureRecognizer()
        ..onTap = () {
          if (context.mounted) {
            context.push(
              '/settings-detail',
              extra: {
                'title': 'Terms & Conditions',
                'content': AppStrings.termsAndConditionsContent,
              },
            );
          }
        },
    );

    final privacyRecognizer = useMemoized(
      () => TapGestureRecognizer()
        ..onTap = () {
          if (context.mounted) {
            context.push(
              '/settings-detail',
              extra: {
                'title': 'Privacy Policy',
                'content': AppStrings.privacyPolicyContent,
              },
            );
          }
        },
    );

    if (isCheckingAuth.value) {
      return Scaffold(
        backgroundColor: AppColors.getSurfaceContainerLowest(context),
        body: const SizedBox.shrink(),
      );
    }

    final bgMainColor = AppColors.getBackground(context);
    final titleTextColor = AppColors.getText(context);
    final subtitleColor = AppColors.getTextMuted(context);
    final buttonTextColor = isDark
        ? AppColors.white
        : AppColors.getText(context);
    final disclaimerBaseColor = AppColors.getTextMuted(context);

    return Scaffold(
      backgroundColor: bgMainColor,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSizes.w24),
          child: Column(
            children: [
              const Spacer(flex: 5),

              // Title: Finzo
              FadeInDown(
                duration: const Duration(milliseconds: 600),
                child: Text(
                  AppStrings.baseAppName,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.heading(
                    context,
                    fontSize: 44,
                    fontWeight: FontWeight.w800,
                    color: titleTextColor,
                  ).copyWith(letterSpacing: -0.5),
                ),
              ),

              SizedBox(height: AppSizes.h12),

              // Subtitle: Auto-track expenses. / Master your budget.
              FadeInDown(
                delay: const Duration(milliseconds: 100),
                duration: const Duration(milliseconds: 600),
                child: Text(
                  'Auto-track expenses.\nMaster your budget.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.subHeading(
                    context,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: subtitleColor,
                  ).copyWith(height: 1.35),
                ),
              ),

              const Spacer(flex: 5),

              // "Continue with Google" Pill Button
              FadeInUp(
                delay: const Duration(milliseconds: 200),
                duration: const Duration(milliseconds: 600),
                child: Container(
                  width: double.infinity,
                  height: AppSizes.h(52),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.getSurfaceContainer(context)
                        : AppColors.getSurfaceContainerLowest(context),
                    borderRadius: BorderRadius.circular(AppSizes.r(28)),
                    border: isDark
                        ? null
                        : Border.all(
                            color: AppColors.getBorder(context),
                            width: 1,
                          ),
                    boxShadow: isDark
                        ? null
                        : [
                            BoxShadow(
                              color: AppColors.black.withValues(alpha: 0.03),
                              blurRadius: 16,
                              spreadRadius: 0,
                              offset: Offset.zero,
                            ),
                          ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: isGoogleLoading.value ? null : loginWithGoogle,
                      borderRadius: BorderRadius.circular(AppSizes.r(28)),
                      child: Center(
                        child: isGoogleLoading.value
                            ? SizedBox(
                                height: AppSizes.r24,
                                width: AppSizes.r24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: buttonTextColor,
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
                                  SizedBox(width: AppSizes.w12),
                                  Text(
                                    'Continue with Google',
                                    style: AppTextStyles.body(
                                      context,
                                      color: buttonTextColor,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(height: AppSizes.h24),

              // Terms & Privacy Links Footer
              FadeInUp(
                delay: const Duration(milliseconds: 300),
                duration: const Duration(milliseconds: 600),
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: AppTextStyles.body(
                      context,

                      color: disclaimerBaseColor,
                    ).copyWith(height: 1.45),
                    children: [
                      const TextSpan(
                        text: 'By continuing, you agree to Finzo’s\n',
                      ),
                      TextSpan(
                        text: 'Terms and Conditions',
                        style: AppTextStyles.body(
                          context,

                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                        recognizer: termsRecognizer,
                      ),
                      const TextSpan(text: ' and '),
                      TextSpan(
                        text: 'Privacy Policy',
                        style: AppTextStyles.body(
                          context,

                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                        recognizer: privacyRecognizer,
                      ),
                      const TextSpan(text: '.'),
                    ],
                  ),
                ),
              ),

              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:smart_money_tracker/core/constants/app_colors.dart';
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
import 'package:smart_money_tracker/features/dashboard/presentation/screens/settings_detail_screen.dart';
import 'package:smart_money_tracker/features/auth/presentation/providers/auth_provider.dart';

class LoginScreen extends HookConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMounted = useIsMounted();
    final isGoogleLoading = useState(false);
    final isGuestLoading = useState(false);
    final isLoading = isGoogleLoading.value || isGuestLoading.value;

    Future<void> loginWithGoogle() async {
      isGoogleLoading.value = true;
      try {
        final success = await ref
            .read(authNotifierProvider.notifier)
            .signInWithGoogle();
        if (!success) return;
        final prefs = await SharedPreferences.getInstance();
        final disclosed = prefs.getBool('permissions_disclosed') ?? false;
        if (isMounted()) {
          if (!disclosed) {
            context.go('/permissions');
          } else {
            context.go('/dashboard');
          }
        }
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
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SettingsDetailScreen(
                title: 'Terms & Conditions',
                content: AppStrings.termsAndConditionsContent,
              ),
            ),
          );
        },
    );

    final privacyRecognizer = useMemoized(
      () => TapGestureRecognizer()
        ..onTap = () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SettingsDetailScreen(
                title: 'Privacy Policy',
                content: AppStrings.privacyPolicyContent,
              ),
            ),
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
              const Spacer(flex: 2),
              FadeInDown(
                duration: const Duration(milliseconds: 1000),
                child: Container(
                  width: AppSizes.r(120),
                  height: AppSizes.r(120),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: AppSizes.boxBorderRadius,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: AppSizes.boxBorderRadius,
                    child: Image.asset(
                      AppStrings.appIconPath,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              SizedBox(height: AppSizes.h32),
              FadeInDown(
                delay: const Duration(milliseconds: 200),
                child: Text(
                  'Smart Money',
                  style: AppTextStyles.heading(context, color: AppColors.primary),
                ),
              ),
              SizedBox(height: AppSizes.h16),
              FadeInDown(
                delay: const Duration(milliseconds: 400),
                child: Text(
                  'Master your finances with intelligence and ease.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body(context, color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ),
              const Spacer(flex: 3),
              FadeInUp(
                delay: const Duration(milliseconds: 600),
                child: Column(
                  children: [
                    Text(
                      'Sign in to get started',
                      style: AppTextStyles.small(context, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                    SizedBox(height: AppSizes.h24),
                    SizedBox(
                      width: double.infinity,
                      height: AppSizes.h(60),
                      child: ElevatedButton(
                        onPressed: isLoading ? null : loginWithGoogle,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black87,
                          elevation: 2,
                          shadowColor: Colors.black12,
                          shape: RoundedRectangleBorder(
                            borderRadius: AppSizes.boxBorderRadius,
                            side: BorderSide(
                              color: Colors.grey.shade200,
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
                                    style: AppTextStyles.body(context, color: Colors.black87),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    SizedBox(height: AppSizes.h16),
                    TextButton(
                      onPressed: isLoading
                          ? null
                          : () async {
                              isGuestLoading.value = true;
                              try {
                                await ref
                                    .read(authNotifierProvider.notifier)
                                    .signInAnonymously();
                                final prefs =
                                    await SharedPreferences.getInstance();
                                final disclosed =
                                    prefs.getBool('permissions_disclosed') ??
                                    false;
                                if (isMounted()) {
                                  if (!disclosed) {
                                    context.go('/permissions');
                                  } else {
                                    context.go('/dashboard');
                                  }
                                }
                              } catch (e) {
                                if (isMounted()) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(e.toString())),
                                  );
                                }
                              } finally {
                                if (isMounted()) isGuestLoading.value = false;
                              }
                            },
                      child: isGuestLoading.value
                          ? SizedBox(
                              height: AppSizes.r20,
                              width: AppSizes.r20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                              ),
                            )
                          : Text(
                              'Continue as Guest',
                              style: AppTextStyles.body(context, color: AppColors.primary),
                            ),
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 1),
              FadeInUp(
                delay: const Duration(milliseconds: 800),
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: AppTextStyles.small(context, color: Theme.of(
                        context,
                      ).colorScheme.onSurfaceVariant.withOpacity(0.6)),
                    children: [
                      const TextSpan(text: 'By continuing, you agree to our '),
                      TextSpan(
                        text: 'Terms & Conditions',
                        style: AppTextStyles.small(context, color: AppColors.primary).copyWith(
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: termsRecognizer,
                      ),
                      const TextSpan(text: ' and '),
                      TextSpan(
                        text: 'Privacy Policy',
                        style: AppTextStyles.small(context, color: AppColors.primary).copyWith(
                          decoration: TextDecoration.underline,
                        ),
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

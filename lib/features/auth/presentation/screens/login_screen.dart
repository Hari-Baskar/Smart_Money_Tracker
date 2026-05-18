import 'package:smart_money_tracker/core/constants/app_colors.dart';
import 'package:smart_money_tracker/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
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
        await ref.read(authNotifierProvider.notifier).signInWithGoogle();
        if (isMounted()) {
          context.go('/dashboard');
        }
      } catch (e) {
        if (isMounted()) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
        }
      } finally {
        if (isMounted()) isGoogleLoading.value = false;
      }
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 32.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              FadeInDown(
                child: Container(
                  padding: EdgeInsets.all(20.r),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.account_balance_wallet_rounded,
                    color: AppColors.primary,
                    size: 64.r,
                  ),
                ),
              ),
              SizedBox(height: 32.h),
              FadeInDown(
                delay: const Duration(milliseconds: 200),
                child: Text(
                  'Smart Money',
                  style: AppTextStyles.display(
                    context,
                    color: AppColors.primary,
                  ),
                ),
              ),
              SizedBox(height: 16.h),
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
                      style: AppTextStyles.small(
                        context,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 24.h),
                    SizedBox(
                      width: double.infinity,
                      height: 60.h,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : loginWithGoogle,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black87,
                          elevation: 2,
                          shadowColor: Colors.black12,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.r),
                            side: BorderSide(
                              color: Colors.grey.shade200,
                              width: 1,
                            ),
                          ),
                        ),
                        child: isGoogleLoading.value
                            ? SizedBox(
                                height: 24.r,
                                width: 24.r,
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
                                    height: 24.r,
                                    width: 24.r,
                                  ),
                                  SizedBox(width: 16.w),
                                  Text(
                                    'Continue with Google',
                                    style: AppTextStyles.body(
                                      context,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    TextButton(
                      onPressed: isLoading
                          ? null
                          : () async {
                              isGuestLoading.value = true;
                              try {
                                await ref
                                    .read(authNotifierProvider.notifier)
                                    .signInAnonymously();
                                if (isMounted()) {
                                  context.go('/dashboard');
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
                              height: 20.r,
                              width: 20.r,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                              ),
                            )
                          : Text(
                              'Continue as Guest',
                              style: AppTextStyles.body(
                                context,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 1),
              FadeInUp(
                delay: const Duration(milliseconds: 800),
                child: Text(
                  'By continuing, you agree to our Terms and Privacy Policy',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.small(
                    context,
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6),
                  ),
                ),
              ),
              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }
}



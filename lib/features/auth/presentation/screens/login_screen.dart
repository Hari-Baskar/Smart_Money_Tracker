import 'package:expense_tracker/core/constants/app_colors.dart';
import 'package:expense_tracker/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:expense_tracker/features/auth/presentation/providers/auth_provider.dart';

class LoginScreen extends HookConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailController = useTextEditingController();
    final passwordController = useTextEditingController();
    final isMounted = useIsMounted();
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState is AsyncLoading;

    Future<void> loginWithEmail() async {
      final email = emailController.text.trim();
      final password = passwordController.text.trim();
      
      if (email.isEmpty || password.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter email and password")),
        );
        return;
      }

      try {
        await ref.read(authNotifierProvider.notifier).signInWithEmail(email, password);
        if (isMounted()) {
          context.go('/dashboard');
        }
      } catch (e) {
        if (isMounted()) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
        }
      }
    }

    Future<void> signUpWithEmail() async {
      final email = emailController.text.trim();
      final password = passwordController.text.trim();
      
      if (email.isEmpty || password.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter email and password")),
        );
        return;
      }

      try {
        await ref.read(authNotifierProvider.notifier).signUpWithEmail(email, password);
        if (isMounted()) {
          context.push('/name');
        }
      } catch (e) {
        if (isMounted()) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
        }
      }
    }

    Future<void> loginWithGoogle() async {
      try {
        await ref.read(authNotifierProvider.notifier).signInWithGoogle();
        if (isMounted()) {
          context.go('/dashboard');
        }
      } catch (e) {
        if (isMounted()) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
        }
      }
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 60.h),
              FadeInDown(
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.r),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(Icons.account_balance_wallet_rounded, color: AppColors.primary, size: 24.r),
                    ),
                    SizedBox(width: 12.w),
                    Text(
                      'Smart Money',
                      style: AppTextStyles.headline(
                        context,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 40.h),
              FadeInDown(
                delay: const Duration(milliseconds: 200),
                child: Text(
                  'Welcome Back',
                  style: AppTextStyles.display(
                    context,
                  ),
                ),
              ),
              SizedBox(height: 8.h),
              FadeInDown(
                delay: const Duration(milliseconds: 300),
                child: Text(
                  'Sign in to your account to continue tracking your expenses.',
                  style: AppTextStyles.body(
                    context,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              SizedBox(height: 48.h),
              FadeInUp(
                delay: const Duration(milliseconds: 400),
                child: TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: 'Email Address',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              FadeInUp(
                delay: const Duration(milliseconds: 500),
                child: TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    hintText: 'Password',
                    prefixIcon: Icon(Icons.lock_outline_rounded),
                  ),
                ),
              ),
              SizedBox(height: 40.h),
              FadeInUp(
                delay: const Duration(milliseconds: 600),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 56.h,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : loginWithEmail,
                        child: isLoading
                            ? SizedBox(
                                height: 20.r,
                                width: 20.r,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Sign In'),
                      ),
                    ),
                    SizedBox(height: 24.h),
                    Row(
                      children: [
                        Expanded(child: Divider(color: Theme.of(context).colorScheme.surfaceVariant)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          child: Text(
                            'OR',
                            style: AppTextStyles.small(
                              context,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: Theme.of(context).colorScheme.surfaceVariant)),
                      ],
                    ),
                    SizedBox(height: 24.h),
                    SizedBox(
                      width: double.infinity,
                      height: 56.h,
                      child: OutlinedButton(
                        onPressed: isLoading ? null : loginWithGoogle,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Theme.of(context).colorScheme.surfaceVariant),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                        ),
                        child: isLoading
                            ? SizedBox(
                                height: 20.r,
                                width: 20.r,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.network(
                                    'https://upload.wikimedia.org/wikipedia/commons/c/c1/Google_%22G%22_logo.svg',
                                    height: 24.r,
                                    width: 24.r,
                                    errorBuilder: (context, error, stackTrace) =>
                                        Icon(Icons.g_mobiledata, size: 24.r),
                                  ),
                                  SizedBox(width: 12.w),
                                  Text(
                                    'Continue with Google',
                                    style: AppTextStyles.body(
                                      context,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    SizedBox(height: 24.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Don\'t have an account? ',
                          style: AppTextStyles.small(context),
                        ),
                        GestureDetector(
                          onTap: isLoading ? null : signUpWithEmail,
                          child: Text(
                            'Sign Up',
                            style: AppTextStyles.small(
                              context,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }
}


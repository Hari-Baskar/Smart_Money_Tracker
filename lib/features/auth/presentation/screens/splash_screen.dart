import 'package:expense_tracker/core/constants/app_colors.dart';
import 'package:expense_tracker/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:expense_tracker/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends HookConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMounted = useIsMounted();

    useEffect(() {
      Future<void> checkAuth() async {
        await Future.delayed(const Duration(seconds: 3));
        if (!isMounted()) return;

        final prefs = await SharedPreferences.getInstance();
        final disclosed = prefs.getBool('permissions_disclosed') ?? false;

        final user = ref.read(authRepositoryProvider).currentUser;
        if (user != null) {
          if (!disclosed) {
            context.go('/permissions');
          } else {
            context.go('/dashboard');
          }
        } else {
          context.go('/login');
        }
      }

      checkAuth();
      return null;
    }, []);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FadeInDown(
                  duration: const Duration(milliseconds: 1000),
                  child: Container(
                    width: 120.r,
                    height: 120.r,
                    padding: EdgeInsets.all(20.r),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(30.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        Icons.account_balance_wallet_rounded,
                        size: 60.r,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 32.h),
                FadeInUp(
                  duration: const Duration(milliseconds: 1000),
                  child: Column(
                    children: [
                      Text(
                        'Smart Money',
                        style: AppTextStyles.display(
                          context,
                          color: Theme.of(context).colorScheme.onBackground,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'Track your money\nautomatically',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.body(
                          context,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 60.h),
                FadeIn(
                  delay: const Duration(milliseconds: 500),
                  child: SizedBox(
                    width: 120.w,
                    child: LinearProgressIndicator(
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                      minHeight: 4,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 40.h,
            left: 0,
            right: 0,
            child: FadeInUp(
              delay: const Duration(milliseconds: 800),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.lock_outline_rounded,
                        color: AppColors.primary,
                        size: 16.r,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'SECURE & ENCRYPTED',
                        style: AppTextStyles.small(
                          context,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 6.r,
                        height: 6.r,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Container(
                        width: 6.r,
                        height: 6.r,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Container(
                        width: 6.r,
                        height: 6.r,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

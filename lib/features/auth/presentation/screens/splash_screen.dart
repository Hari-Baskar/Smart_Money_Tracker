import 'package:smart_money_tracker/core/constants/app_colors.dart';
import 'package:smart_money_tracker/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:smart_money_tracker/features/auth/presentation/providers/auth_provider.dart';
import 'package:smart_money_tracker/core/constants/app_sizes.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_money_tracker/core/constants/app_strings.dart';
import 'package:smart_money_tracker/core/services/security_service.dart';

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
          final securityService = ref.read(securityServiceProvider);
          final pin = await securityService.getLocalPin();
          
          if (pin == null) {
            // Missing local PIN config, route through LoginScreen for verification
            if (isMounted()) context.go('/login');
            return;
          }

          final targetRoute = disclosed ? '/dashboard' : '/permissions';
          final requiresLock = await securityService.isAppLockEnabledOnLaunch();
          
          if (requiresLock && isMounted()) {
            context.go('/app-lock', extra: targetRoute);
          } else if (isMounted()) {
            context.go(targetRoute);
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(width: AppSizes.screenWidth),
          FadeInDown(
            duration: const Duration(milliseconds: 1000),
            child: Image.asset(
              AppStrings.appIconPath,
              fit: BoxFit.cover,

              width: AppSizes.screenWidth * 0.4,
            ),
          ),

          FadeInDown(
            delay: const Duration(milliseconds: 1000),
            child: Text(
              AppStrings.baseAppName,
              style: AppTextStyles.heading(
                context,
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
              ),
            ),
          ),
          SizedBox(height: AppSizes.h12),
          FadeInUp(
            duration: const Duration(milliseconds: 1000),
            child: Text(
              'Track your money',
              textAlign: TextAlign.center,
              style: AppTextStyles.body(
                context,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          SizedBox(height: AppSizes.h24),
          FadeIn(
            delay: const Duration(milliseconds: 500),
            child: SizedBox(
              width: AppSizes.screenWidth * 0.5,
              child: LinearProgressIndicator(
                backgroundColor: AppColors.primary.withOpacity(0.1),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.primary,
                ),
                minHeight: 4,
                borderRadius: AppSizes.boxBorderRadius,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

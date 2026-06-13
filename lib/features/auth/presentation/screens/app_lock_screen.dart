import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_money_tracker/core/constants/app_colors.dart';
import 'package:smart_money_tracker/core/constants/app_sizes.dart';
import 'package:smart_money_tracker/core/theme/app_text_styles.dart';
import 'package:smart_money_tracker/core/services/security_service.dart';
import 'package:smart_money_tracker/core/utils/app_toast.dart';
import 'package:smart_money_tracker/features/auth/presentation/providers/auth_provider.dart';

class AppLockScreen extends HookConsumerWidget {
  final String nextRoute;

  const AppLockScreen({super.key, required this.nextRoute});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMounted = useIsMounted();
    final isAuthenticating = useState(false);

    Future<void> authenticate() async {
      if (isAuthenticating.value) return;
      isAuthenticating.value = true;
      
      final securityService = ref.read(securityServiceProvider);
      final success = await securityService.authenticateWithBiometrics(
        'Unlock smart money tracker',
      );

      if (!isMounted()) return;
      isAuthenticating.value = false;

      if (success) {
        context.go(nextRoute);
      } else {
        AppToast.show(context, 'Authentication failed', isError: true);
      }
    }

    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        authenticate();
      });
      return null;
    }, []);

    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_rounded,
                size: AppSizes.screenHeight * 0.08,
                color: AppColors.primary,
              ),
              SizedBox(height: AppSizes.h24),
              Text(
                'App Locked',
                style: AppTextStyles.heading(context, fontSize: 28),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppSizes.h8),
              Text(
                'Unlock to continue',
                style: AppTextStyles.body(
                  context,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppSizes.h48),
              ElevatedButton.icon(
                onPressed: isAuthenticating.value ? null : authenticate,
                icon: const Icon(Icons.fingerprint_rounded, color: AppColors.white),
                label: Text(
                  'Unlock',
                  style: AppTextStyles.body(context, color: AppColors.white, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSizes.w32,
                    vertical: AppSizes.h16,
                  ),
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.r16),
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

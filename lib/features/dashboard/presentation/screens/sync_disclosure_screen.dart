import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_money_tracker/core/constants/app_colors.dart';
import 'package:smart_money_tracker/core/constants/app_sizes.dart';
import 'package:smart_money_tracker/core/theme/app_text_styles.dart';
import 'package:smart_money_tracker/features/auth/presentation/providers/auth_provider.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/providers/transaction_provider.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/providers/restore_provider.dart';

class SyncDisclosureScreen extends HookConsumerWidget {
  const SyncDisclosureScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMounted = useIsMounted();
    final isRestoring = useState(false);

    final restoreState = ref.watch(restoreNotifierProvider);

    Future<void> handleRestore() async {
      final user = ref.read(authStateProvider).value;
      if (user == null) return;

      isRestoring.value = true;
      try {
        await ref
            .read(transactionRepositoryProvider)
            .restoreTransactions(user.id);

        await ref.read(restoreNotifierProvider.notifier).setHasRestored(true);
        await ref.read(restoreNotifierProvider.notifier).setRestoreCount(0);

        if (isMounted()) {
          context.go('/dashboard');
        }
      } catch (e) {
        if (isMounted()) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to restore data: $e')));
        }
      } finally {
        if (isMounted()) {
          isRestoring.value = false;
        }
      }
    }

    void handleSkip() {
      context.go('/dashboard');
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(AppSizes.w24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Icon(
                Icons.cloud_sync_rounded,
                size: AppSizes.screenHeight * 0.1,
                color: AppColors.primary,
              ),
              SizedBox(height: AppSizes.h32),
              Text(
                'We have your recent transactions!',
                style: AppTextStyles.heading(context),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppSizes.h16),

              Text(
                'Your latest transactions are securely backed up in the cloud and ready to be synced to this device.',
                style: AppTextStyles.body(context),
                textAlign: TextAlign.center,
              ),

              const Spacer(),

              ElevatedButton(
                onPressed: isRestoring.value ? null : handleRestore,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: EdgeInsets.symmetric(vertical: AppSizes.h16),
                ),
                child: isRestoring.value
                    ? SizedBox(
                        height: AppSizes.r20,
                        width: AppSizes.r20,
                        child: CircularProgressIndicator(
                          color: AppColors.white,
                          strokeWidth: AppSizes.w(2),
                        ),
                      )
                    : Text(
                        'Restore Now',
                        style: AppTextStyles.body(
                          context,
                          color: AppColors.white,
                        ),
                      ),
              ),

              SizedBox(height: AppSizes.h16),

              TextButton(
                onPressed: isRestoring.value ? null : handleSkip,
                child: Text(
                  'Skip',
                  style: AppTextStyles.body(
                    context,
                    color: AppColors.getTextMuted(context),
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

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_money_tracker/core/utils/app_toast.dart';
import 'package:smart_money_tracker/core/constants/app_colors.dart';
import 'package:smart_money_tracker/core/constants/app_sizes.dart';
import 'package:smart_money_tracker/core/theme/app_text_styles.dart';
import 'package:smart_money_tracker/features/auth/presentation/providers/auth_provider.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/providers/transaction_provider.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/providers/restore_provider.dart';
import 'package:smart_money_tracker/core/constants/app_toast_messages.dart';

class SyncDisclosureScreen extends HookConsumerWidget {
  const SyncDisclosureScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMounted = useIsMounted();
    final isRestoring = useState(false);
    final progress = useState<double>(0.0);

    final restoreState = ref.watch(restoreNotifierProvider);

    Future<void> handleRestore() async {
      final user = ref.read(authStateProvider).value;
      if (user == null) return;

      isRestoring.value = true;

      // Simulate progress while the backend call is running
      Timer? progressTimer;
      progressTimer = Timer.periodic(const Duration(milliseconds: 100), (
        timer,
      ) {
        if (progress.value < 0.90) {
          progress.value += 0.03;
        }
      });

      try {
        await ref
            .read(transactionRepositoryProvider)
            .restoreTransactions(user.id);

        progressTimer.cancel();
        progress.value = 1.0; // Complete

        // Let the user see 100% before navigating
        await Future.delayed(const Duration(milliseconds: 400));

        await ref.read(restoreNotifierProvider.notifier).setHasRestored(true);
        await ref.read(restoreNotifierProvider.notifier).setRestoreCount(0);

        if (isMounted()) {
          context.go('/dashboard');
        }
      } catch (e) {
        progressTimer.cancel();
        if (isMounted()) {
          AppToast.show(context, AppToastMessages.restoreFailed + ': $e', isError: true);
        }
      } finally {
        if (isMounted()) {
          isRestoring.value = false;
        }
      }
    }

    useEffect(() {
      if (isMounted()) {
        // Automatically start the restore process after a tiny delay for visual smoothness
        Future.delayed(const Duration(milliseconds: 300), handleRestore);
      }
      return null;
    }, const []);

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
                Icons.cloud_download_rounded,
                size: AppSizes.screenHeight * 0.1,
                color: AppColors.primary,
              ),
              SizedBox(height: AppSizes.h32),
              Text(
                'Restoring Your Data',
                style: AppTextStyles.heading(context),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppSizes.h16),

              Text(
                'Fetching your recent transactions securely from the cloud...',
                style: AppTextStyles.body(context),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: AppSizes.h32),

              Center(
                child: SizedBox(
                  width: AppSizes.screenWidth * 0.7,
                  child: Column(
                    children: [
                      LinearProgressIndicator(
                        value: progress.value,
                        color: AppColors.primary,
                        // backgroundColor: AppColors.getSurfaceContainerHighest(context),
                        borderRadius: BorderRadius.circular(AppSizes.r8),
                        minHeight: AppSizes.h8,
                      ),
                      SizedBox(height: AppSizes.h12),
                      Text(
                        '${(progress.value * 100).clamp(0, 100).toInt()}%',
                        style: AppTextStyles.subHeading(
                          context,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

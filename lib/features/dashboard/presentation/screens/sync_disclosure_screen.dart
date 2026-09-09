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
    final isRestoring = useState(false);
    final progress = useState<double>(0.0);

    Future<void> handleRestore() async {
      final user = ref.read(authStateProvider).value;
      if (user == null) return;

      isRestoring.value = true;

      // Simulate progress while the backend call is running
      Timer? progressTimer;
      progressTimer = Timer.periodic(const Duration(milliseconds: 100), (
        timer,
      ) {
        if (progress.value < 0.95) {
          progress.value += 0.15;
        }
      });

      try {
        await ref
            .read(transactionRepositoryProvider)
            .restoreTransactions(user.id);

        progressTimer.cancel();
        progress.value = 1.0; // Complete

        await ref.read(restoreNotifierProvider.notifier).setHasRestored(true);
        await ref.read(restoreNotifierProvider.notifier).setRestoreCount(0);

        if (context.mounted) {
          context.go('/dashboard');
        }
      } catch (e) {
        progressTimer.cancel();
        if (context.mounted) {
          AppToast.show(
            context,
            AppToastMessages.restoreFailed,
            isError: true,
          );
        }
      } finally {
        if (context.mounted) {
          isRestoring.value = false;
        }
      }
    }

    useEffect(() {
      if (context.mounted) {
        // Automatically start the restore process immediately
        handleRestore();
      }
      return null;
    }, const []);

    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(AppSizes.w24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              if (progress.value >= 1.0)
                Container(
                  width: AppSizes.screenHeight * 0.1,
                  height: AppSizes.screenHeight * 0.1,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    color: AppColors.white,
                    size: AppSizes.screenHeight * 0.08,
                  ),
                )
              else
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: AppSizes.screenHeight * 0.1,
                      height: AppSizes.screenHeight * 0.1,
                      child: CircularProgressIndicator(
                        value: progress.value,
                        strokeWidth: 8,
                        color: AppColors.primary,
                        backgroundColor: AppColors.primary.withValues(
                          alpha: 0.1,
                        ),
                      ),
                    ),
                    Text(
                      '${(progress.value * 100).clamp(0, 100).toInt()}%',
                      style: AppTextStyles.heading(
                        context,
                        color: AppColors.getText(context),
                      ),
                    ),
                  ],
                ),
              SizedBox(height: AppSizes.h16),
              Text(
                progress.value >= 1.0
                    ? 'Restore Complete'
                    : 'Restoring Your Data',
                style: AppTextStyles.subHeading(
                  context,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppSizes.h8),

              Text(
                progress.value >= 1.0
                    ? 'Your transactions have been successfully synced.'
                    : 'Fetching your recent transactions securely from the cloud...',
                style: AppTextStyles.body(context),
                textAlign: TextAlign.center,
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

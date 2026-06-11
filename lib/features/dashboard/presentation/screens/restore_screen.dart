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
import 'package:smart_money_tracker/core/services/update_service.dart';
import 'package:smart_money_tracker/core/utils/app_toast.dart';
import 'package:smart_money_tracker/core/services/analytics_service.dart';

class RestoreScreen extends HookConsumerWidget {
  const RestoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMounted = useIsMounted();
    final isRestoring = useState(false);

    useEffect(() {
      AnalyticsService.logScreenView('RestoreScreen');
      return null;
    }, const []);

    final restoreState = ref.watch(restoreNotifierProvider);
    final updateState = ref.watch(updateProvider).value;
    final initialLimit = updateState?.config?.paginationInitialFetchLimit ?? 500;

    Future<void> handleRestore() async {
      final user = ref.read(authStateProvider).value;
      if (user == null) return;

      isRestoring.value = true;
      try {
        await ref
            .read(transactionRepositoryProvider)
            .restoreTransactions(user.id);

        // Mark as restored so the card doesn't show
        await ref
            .read(restoreNotifierProvider.notifier)
            .setHasRestored(true);
        await ref
            .read(restoreNotifierProvider.notifier)
            .setRestoreCount(0);

        if (isMounted()) {
          AppToast.show(context, 'Data restored successfully!');
          context.go('/dashboard');
        }
      } catch (e) {
        if (isMounted()) {
          AppToast.show(context, 'Failed to restore data: $e', isError: true);
        }
      } finally {
        if (isMounted()) {
          isRestoring.value = false;
        }
      }
    }

    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AppBar(
        backgroundColor: AppColors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Theme.of(context).colorScheme.onBackground,
            size: AppSizes.r20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Restore Data', style: AppTextStyles.heading(context)),
        centerTitle: true,
      ),
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
                'We have your recent transactions!',
                style: AppTextStyles.subHeading(context),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppSizes.h16),

              Text(
                'Your latest transactions are securely backed up in the cloud and ready to be synced to this device.',
                style: AppTextStyles.body(context),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppSizes.h8),
              Text(
                'Estimated time: ~${(initialLimit / 100).ceil()} second${(initialLimit / 100).ceil() == 1 ? '' : 's'}',
                style: AppTextStyles.small(context, color: AppColors.getTextMuted(context)),
                textAlign: TextAlign.center,
              ),

              const Spacer(),

              ElevatedButton(
                onPressed: isRestoring.value
                    ? null
                    : handleRestore,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: EdgeInsets.symmetric(vertical: AppSizes.h16),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppSizes.cardBorderRadius,
                  ),
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
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              SizedBox(height: AppSizes.h16),
            ],
          ),
        ),
      ),
    );
  }
}

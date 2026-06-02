import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:smart_money_tracker/core/constants/app_sizes.dart';
import 'package:smart_money_tracker/core/constants/app_colors.dart';
import 'package:smart_money_tracker/core/theme/app_text_styles.dart';
import 'package:smart_money_tracker/core/models/transaction_model.dart';
import 'package:smart_money_tracker/features/main/presentation/widgets/app_drawer.dart';
import 'package:smart_money_tracker/features/main/presentation/screens/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:smart_money_tracker/features/auth/presentation/providers/auth_provider.dart';
import '../providers/transaction_provider.dart';
import 'package:intl/intl.dart';
import 'package:smart_money_tracker/core/utils/app_toast.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:go_router/go_router.dart';
import 'package:notification_listener_service/notification_listener_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_money_tracker/features/sms_disclosure/presentation/providers/sms_disclosure_provider.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/providers/settings_provider.dart';

import 'add_transaction_screen.dart';
import 'transaction_detail_screen.dart';
import '../widgets/expandable_transaction_card.dart';
import 'package:smart_money_tracker/core/services/update_service.dart';
import 'package:smart_money_tracker/core/services/notification_service.dart';
import 'package:smart_money_tracker/core/common/widgets/update_dialog.dart';
import 'package:smart_money_tracker/core/common/widgets/banner_ad_widget.dart';

import '../widgets/history_summary_card.dart';

class DashboardScreen extends HookConsumerWidget {
  const DashboardScreen({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return 'Good Morning';
    } else if (hour >= 12 && hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Night';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final smsGranted = useState(false);
    final notificationListenerGranted = useState(false);
    final isPermissionBannerDismissed = useState(false);
    final hasCheckedPermissions = useState(false);
    final isMounted = useIsMounted();

    Future<void> checkPermissions() async {
      final smsStatus = await Permission.sms.status;
      final notificationStatus =
          await NotificationListenerService.isPermissionGranted();
      final prefs = await SharedPreferences.getInstance();
      final dismissed = prefs.getBool('dismiss_permission_banner') ?? false;

      if (isMounted()) {
        smsGranted.value = smsStatus.isGranted;
        notificationListenerGranted.value = notificationStatus;
        isPermissionBannerDismissed.value = dismissed;
        hasCheckedPermissions.value = true;
      }
    }

    useEffect(() {
      checkPermissions();

      final observer = _DashboardLifecycleObserver(onResume: checkPermissions);
      WidgetsBinding.instance.addObserver(observer);

      return () {
        WidgetsBinding.instance.removeObserver(observer);
      };
    }, [settings]);

    ref.listen(updateProvider, (previous, next) {
      next.when(
        data: (state) {
          if (state.status != UpdateStatus.none && state.config != null) {
            showDialog(
              context: context,
              barrierDismissible: state.status != UpdateStatus.mandatory,
              builder: (context) => UpdateDialog(
                currentVersion: state.currentVersion,
                newVersion: state.status == UpdateStatus.mandatory
                    ? state.config!.minVersion
                    : state.config!.maxVersion,
                isMandatory: state.status == UpdateStatus.mandatory,
                releaseNotes: state.config!.releaseNotes,
                updateUrl: state.config!.updateUrl,
              ),
            );
          }
        },
        error: (err, stack) {
          debugPrint('Update Check Error: $err');
          // Silent failure for updates to avoid annoying the user,
          // but logged for debugging.
        },
        loading: () => debugPrint('Checking for updates...'),
      );
    });

    final transactionsAsync = ref.watch(todayTransactionsProvider);
    final userProfileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: AppColors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.menu_rounded, size: AppSizes.r(28)),
          onPressed: () =>
              ref.read(mainScaffoldKeyProvider).currentState?.openDrawer(),
        ),
        title: Text('Smart Money', style: AppTextStyles.heading(context)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddTransactionScreen(),
            ),
          );
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: AppColors.white),
        label: Text(
          'Add Transaction',
          style: AppTextStyles.body(context, color: AppColors.white),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(AppSizes.w12),
        child: transactionsAsync.when(
          data: (transactions) {
            final totalSpent = transactions
                .where((t) => t.type == TransactionType.debit)
                .fold(0.0, (sum, t) => sum + t.amount);

            final totalIncome = transactions
                .where((t) => t.type == TransactionType.credit)
                .fold(0.0, (sum, t) => sum + t.amount);

            // Sort transactions by date descending
            final sortedTransactions = List<TransactionModel>.from(transactions)
              ..sort((a, b) => b.date.compareTo(a.date));

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Greeting
                SliverToBoxAdapter(
                  child: Builder(
                    builder: (context) {
                      final nameAsync = ref.watch(userNameProvider);
                      final greetingText = nameAsync.when(
                        data: (name) => '${_getGreeting()}, ${name ?? ''}',
                        loading: () => _getGreeting(),
                        error: (_, __) => _getGreeting(),
                      );
                      return Text(
                        greetingText,
                        style: AppTextStyles.subHeading(
                          context,
                          color: AppColors.getTextMuted(context),
                        ),
                      );
                    },
                  ),
                ),

                // Summary Card
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSizes.h12),
                    child: HistorySummaryCard(
                      selectedCategory: '',
                      selectedSubcategory: '',
                      totalSpent: totalSpent,
                      totalIncome: totalIncome,
                      incomeCount: transactions
                          .where((t) => t.type == TransactionType.credit)
                          .length,
                      expenseCount: transactions
                          .where((t) => t.type != TransactionType.credit)
                          .length,
                    ),
                  ),
                ),

                // SMS & Notification Permission and Scanning Banner
                SliverToBoxAdapter(
                  child: Consumer(
                    builder: (context, ref, child) {
                      if (!hasCheckedPermissions.value) {
                        return const SizedBox.shrink();
                      }
                      final syncState = ref.watch(transactionSyncProvider);
                      final isSyncing = syncState is AsyncLoading;

                      final isSmsToggledOn = settings.smsConsentEnabled;
                      final isNotificationToggledOn =
                          settings.notificationListenerEnabled;

                      final isSmsActive = isSmsToggledOn && smsGranted.value;
                      final isNotificationActive =
                          isNotificationToggledOn &&
                          notificationListenerGranted.value;

                      final showScanBox = isSmsActive;

                      Widget? permissionBanner;

                      Widget? scanBox;

                      if (!isSmsActive && !isNotificationActive) {
                        // Both SMS and Notifications are turned off / inactive -> show unified banner for both
                        if (!isPermissionBannerDismissed.value) {
                          permissionBanner = _buildPermissionBanner(
                            context,
                            title: 'Allow Permissions',
                            description:
                                'Please grant SMS and Notification Listener permissions to automatically detect and parse your transaction alerts.',
                            isPermissionBannerDismissed:
                                isPermissionBannerDismissed,
                            onAllowPressed: () async {
                              await context.push('/app-permissions');
                              checkPermissions();
                            },
                          );
                        }
                      } else if (!isSmsActive) {
                        // Only SMS is turned off / inactive
                        if (!isPermissionBannerDismissed.value) {
                          permissionBanner = _buildPermissionBanner(
                            context,
                            title: 'SMS Permission Required',
                            description:
                                'SMS permission is required to automatically scan and process your transactional messages.',
                            isPermissionBannerDismissed:
                                isPermissionBannerDismissed,
                            onAllowPressed: () async {
                              await context.push('/app-permissions');
                              checkPermissions();
                            },
                          );
                        }
                      } else if (!isNotificationActive) {
                        // Only Notification Listener is turned off / inactive
                        if (!isPermissionBannerDismissed.value) {
                          permissionBanner = _buildPermissionBanner(
                            context,
                            title: 'Notification Listener Permission Required',
                            description:
                                'Notification listener permission is required to detect and import transactions from instant payment notifications.',
                            isPermissionBannerDismissed:
                                isPermissionBannerDismissed,
                            onAllowPressed: () async {
                              await context.push('/app-permissions');
                              checkPermissions();
                            },
                          );
                        }
                      }

                      if (showScanBox) {
                        scanBox = _buildScanBox(context, ref, isSyncing);
                      }

                      if (permissionBanner != null && scanBox != null) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [permissionBanner, scanBox],
                        );
                      } else if (permissionBanner != null) {
                        return permissionBanner;
                      } else if (scanBox != null) {
                        return scanBox;
                      } else {
                        return const SizedBox.shrink();
                      }
                    },
                  ),
                ),

                // Banner Ad
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSizes.w(20),
                      vertical: AppSizes.h12,
                    ),
                    child: const BannerAdWidget(),
                  ),
                ),

                // Recent Transactions Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: AppSizes.h8),
                    child: Text(
                      'Today\'s Transactions',
                      style: AppTextStyles.subHeading(context),
                    ),
                  ),
                ),

                if (transactions.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSizes.h40),
                      child: Center(
                        child: Text(
                          'No transactions for today',
                          style: AppTextStyles.small(context),
                        ),
                      ),
                    ),
                  )
                else
                  // Transaction List
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildTransactionCard(
                        context,
                        sortedTransactions[index],
                      ),
                      childCount: sortedTransactions.length,
                    ),
                  ),

                SliverPadding(
                  padding: EdgeInsets.only(bottom: AppSizes.h(100)),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
        ),
      ),
    );
  }

  Widget _buildTransactionCard(BuildContext context, TransactionModel t) {
    return Consumer(
      builder: (context, ref, child) {
        return Dismissible(
          key: Key(t.id),
          direction: DismissDirection.endToStart,
          dismissThresholds: const {DismissDirection.endToStart: 0.3},
          confirmDismiss: (direction) async {
            return await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: Theme.of(context).colorScheme.surface,
                title: Text(
                  'Delete Transaction',
                  style: AppTextStyles.heading(context),
                ),
                content: Text(
                  'Are you sure you want to delete this transaction?',
                  style: AppTextStyles.body(context),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text('Cancel', style: AppTextStyles.body(context)),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.error,
                    ),
                    child: Text(
                      'Delete',
                      style: AppTextStyles.body(
                        context,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
          onDismissed: (direction) {
            ref.read(transactionSyncProvider.notifier).deleteTransaction(t.id);
            AppToast.show(context, 'Transaction deleted');
          },
          background: Container(
            alignment: Alignment.centerRight,
            padding: EdgeInsets.only(right: AppSizes.w(20)),
            margin: EdgeInsets.symmetric(
              horizontal: AppSizes.w(20),
              vertical: AppSizes.h8,
            ),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.15),
              borderRadius: AppSizes.boxBorderRadius,
            ),
            child: Icon(
              Icons.delete_outline,
              color: AppColors.error,
              size: AppSizes.r24,
            ),
          ),
          child: ExpandableTransactionCard(
            transaction: t,
            margin: EdgeInsets.symmetric(vertical: AppSizes.h4),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TransactionDetailScreen(transaction: t),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildScanBox(BuildContext context, WidgetRef ref, bool isSyncing) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: AppSizes.h12),
      padding: EdgeInsets.all(AppSizes.r16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: AppSizes.cardBorderRadius,
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.sms_outlined,
                color: AppColors.primary,
                size: AppSizes.r20,
              ),
              SizedBox(width: AppSizes.w12),
              Expanded(
                child: Text(
                  'Missing a transaction?',
                  style: AppTextStyles.body(context),
                ),
              ),
            ],
          ),
          SizedBox(height: AppSizes.h8),
          Text(
            'If a recent payment wasn\'t detected, try scanning your SMS inbox again. Note: Encrypted RCS messages cannot be detected due to system privacy.',
            style: AppTextStyles.small(context),
          ),
          SizedBox(height: AppSizes.h12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isSyncing
                      ? null
                      : () {
                          ref.read(transactionSyncProvider.notifier).sync();
                          AppToast.show(context, 'Scanning today\'s messages');
                        },
                  icon: isSyncing
                      ? SizedBox(
                          width: AppSizes.r16,
                          height: AppSizes.r16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        )
                      : const Icon(Icons.search_rounded),
                  label: Text(
                    isSyncing ? 'Scanning...' : 'Scan Today',
                    style: AppTextStyles.small(context),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    foregroundColor: AppColors.primary,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(vertical: AppSizes.h(10)),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppSizes.cardBorderRadius,
                    ),
                  ),
                ),
              ),
              SizedBox(width: AppSizes.w8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isSyncing
                      ? null
                      : () {
                          ref
                              .read(transactionSyncProvider.notifier)
                              .syncYesterday();
                          AppToast.show(
                            context,
                            'Scanning yesterday\'s messages',
                          );
                        },
                  icon: isSyncing
                      ? SizedBox(
                          width: AppSizes.r16,
                          height: AppSizes.r16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        )
                      : const Icon(Icons.history_rounded),
                  label: Text(
                    isSyncing ? 'Scanning...' : 'Scan Yesterday',
                    style: AppTextStyles.small(context),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    foregroundColor: AppColors.primary,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(vertical: AppSizes.h(10)),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppSizes.cardBorderRadius,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionBanner(
    BuildContext context, {
    required String title,
    required String description,
    required ValueNotifier<bool> isPermissionBannerDismissed,
    VoidCallback? onAllowPressed,
  }) {
    return Container(
      padding: EdgeInsets.all(AppSizes.r16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: AppSizes.cardBorderRadius,
        border: Border.all(color: AppColors.error.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: AppColors.error,
                size: AppSizes.r20,
              ),
              SizedBox(width: AppSizes.w12),
              Expanded(child: Text(title, style: AppTextStyles.body(context))),
            ],
          ),
          SizedBox(height: AppSizes.h8),
          Text(description, style: AppTextStyles.small(context)),
          SizedBox(height: AppSizes.h12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed:
                      onAllowPressed ??
                      () {
                        context.push('/app-permissions');
                      },
                  icon: const Icon(Icons.security_rounded),
                  label: Text(
                    'Allow Access',
                    style: AppTextStyles.body(context, color: AppColors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(vertical: AppSizes.h(12)),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppSizes.cardBorderRadius,
                    ),
                  ),
                ),
              ),
              SizedBox(width: AppSizes.w12),
              TextButton(
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('dismiss_permission_banner', true);
                  isPermissionBannerDismissed.value = true;
                },
                child: Text(
                  'Don\'t show again',
                  style: AppTextStyles.small(
                    context,
                    color: AppColors.getTextMuted(context),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DashboardLifecycleObserver extends WidgetsBindingObserver {
  final VoidCallback onResume;
  _DashboardLifecycleObserver({required this.onResume});

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      onResume();
    }
  }
}

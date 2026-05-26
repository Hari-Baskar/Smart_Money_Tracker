import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:smart_money_tracker/core/constants/app_sizes.dart';
import 'package:smart_money_tracker/core/constants/app_colors.dart';
import 'package:smart_money_tracker/core/theme/app_text_styles.dart';
import 'package:smart_money_tracker/core/models/transaction_model.dart';
import 'package:smart_money_tracker/features/main/presentation/widgets/app_drawer.dart';
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
import 'package:smart_money_tracker/core/services/update_service.dart';
import 'package:smart_money_tracker/core/common/widgets/update_dialog.dart';
import 'package:smart_money_tracker/core/common/widgets/banner_ad_widget.dart';

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
      drawer: const AppDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(
              Icons.menu_rounded,
              color: AppColors.isDark(context)
                  ? AppColors.getText(context)
                  : AppColors.primary,
              size: AppSizes.r(28),
            ),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text(
          'Smart Money',
          style: AppTextStyles.headline(
            context,
            color: AppColors.isDark(context)
                ? AppColors.getText(context)
                : AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.sync_rounded,
              color: AppColors.isDark(context)
                  ? AppColors.getText(context)
                  : AppColors.primary,
              size: AppSizes.r(24),
            ),
            onPressed: () async {
              if (smsGranted.value) {
                ref.read(transactionSyncProvider.notifier).sync();
                AppToast.show(context, 'Scanning');
              } else {
                AppToast.show(context, 'SMS permission is required');
                await context.push('/app-permissions');
                checkPermissions();
              }
            },
          ),
          SizedBox(width: AppSizes.w8),
        ],
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
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          'Add Transaction',
          style: AppTextStyles.small(context, color: Colors.white),
        ),
      ),
      body: transactionsAsync.when(
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
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSizes.w(20),
                    AppSizes.h16,
                    AppSizes.w(20),
                    AppSizes.h8,
                  ),
                  child: Text(
                    _getGreeting(),
                    style: AppTextStyles.headline(
                      context,
                      color: AppColors.getTextMuted(context),
                    ),
                  ),
                ),
              ),

              // Summary Card
              SliverToBoxAdapter(
                child: Container(
                  margin: EdgeInsets.symmetric(
                    horizontal: AppSizes.w(20),
                    vertical: AppSizes.h12,
                  ),
                  padding: EdgeInsets.all(AppSizes.r16),
                  decoration: BoxDecoration(
                    color: AppColors.getSurfaceContainerLowest(context),
                    borderRadius: BorderRadius.circular(AppSizes.r20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.isDark(context)
                            ? Colors.black.withOpacity(0.25)
                            : Colors.black.withOpacity(0.05),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                    border: Border.all(
                      color: AppColors.isDark(context)
                          ? Colors.white.withOpacity(0.06)
                          : AppColors.primary.withOpacity(0.08),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Today's Spending Card
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.all(AppSizes.r16),
                          decoration: BoxDecoration(
                            color: AppColors.isDark(context)
                                ? Colors.red.withOpacity(0.06)
                                : const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(AppSizes.r16),
                            border: Border.all(
                              color: AppColors.error.withOpacity(
                                AppColors.isDark(context) ? 0.2 : 0.08,
                              ),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(AppSizes.r8),
                                    decoration: BoxDecoration(
                                      color: AppColors.error.withOpacity(0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.trending_up_rounded,
                                      color: AppColors.error,
                                      size: AppSizes.r16,
                                    ),
                                  ),
                                  SizedBox(width: AppSizes.w8),
                                  Text(
                                    'Spending',
                                    style: AppTextStyles.small(
                                      context,
                                      color: AppColors.getTextMuted(context),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: AppSizes.h12),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  '₹${AppColors.formatShortAmount(totalSpent)}',
                                  style: AppTextStyles.display(
                                    context,
                                    color: AppColors.error,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20.sp,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: AppSizes.w12),
                      // Today's Income Card
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.all(AppSizes.r16),
                          decoration: BoxDecoration(
                            color: AppColors.isDark(context)
                                ? Colors.green.withOpacity(0.06)
                                : const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(AppSizes.r16),
                            border: Border.all(
                              color: AppColors.success.withOpacity(
                                AppColors.isDark(context) ? 0.2 : 0.08,
                              ),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(AppSizes.r8),
                                    decoration: BoxDecoration(
                                      color: AppColors.success.withOpacity(
                                        0.12,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.trending_down_rounded,
                                      color: AppColors.success,
                                      size: AppSizes.r16,
                                    ),
                                  ),
                                  SizedBox(width: AppSizes.w8),
                                  Text(
                                    'Income',
                                    style: AppTextStyles.small(
                                      context,
                                      color: AppColors.getTextMuted(context),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: AppSizes.h12),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  '₹${AppColors.formatShortAmount(totalIncome)}',
                                  style: AppTextStyles.display(
                                    context,
                                    color: AppColors.success,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20.sp,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
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
                    final isNotificationToggledOn = settings.notificationListenerEnabled;

                    final isSmsActive = isSmsToggledOn && smsGranted.value;
                    final isNotificationActive = isNotificationToggledOn && notificationListenerGranted.value;

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
                  padding: EdgeInsets.fromLTRB(
                    AppSizes.w(20),
                    AppSizes.h32,
                    AppSizes.w(20),
                    AppSizes.h12,
                  ),
                  child: Text(
                    'Today\'s Transactions',
                    style: AppTextStyles.headline(context),
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

              SliverPadding(padding: EdgeInsets.only(bottom: AppSizes.h(100))),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
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
                  style: AppTextStyles.headline(context),
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
                        fontWeight: FontWeight.bold,
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
              borderRadius: BorderRadius.circular(AppSizes.r16),
            ),
            child: Icon(
              Icons.delete_outline,
              color: AppColors.error,
              size: AppSizes.r24,
            ),
          ),
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TransactionDetailScreen(transaction: t),
                ),
              );
            },
            child: Container(
              margin: EdgeInsets.symmetric(
                horizontal: AppSizes.w(20),
                vertical: AppSizes.h8,
              ),
              decoration: BoxDecoration(
                color: AppColors.getSurfaceContainerLowest(context),
                borderRadius: BorderRadius.circular(AppSizes.r16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.isDark(context)
                        ? Colors.black.withOpacity(0.2)
                        : Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: AppColors.isDark(context)
                      ? Colors.white.withOpacity(0.05)
                      : Colors.black.withOpacity(0.03),
                  width: 1,
                ),
              ),
              child: ListTile(
                contentPadding: EdgeInsets.all(AppSizes.r12),
                leading: Container(
                  width: AppSizes.r(48),
                  height: AppSizes.r(48),
                  decoration: BoxDecoration(
                    color: t.type == TransactionType.credit
                        ? AppColors.success.withOpacity(0.12)
                        : AppColors.getCategoryBgColor(context, t.category),
                    borderRadius: BorderRadius.circular(AppSizes.r12),
                  ),
                  child: Icon(
                    t.type == TransactionType.credit
                        ? Icons.account_balance_wallet_rounded
                        : AppColors.getCategoryIcon(t.category),
                    color: t.type == TransactionType.credit
                        ? AppColors.success
                        : AppColors.getCategoryColor(t.category),
                    size: AppSizes.r24,
                  ),
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        t.subcategory,
                        style: AppTextStyles.body(
                          context,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: AppSizes.w8),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSizes.w8,
                        vertical: AppSizes.h(2),
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.isDark(context)
                            ? Colors.white.withOpacity(0.06)
                            : AppColors.primary.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(AppSizes.r(20)),
                      ),
                      child: Text(
                        t.category.toUpperCase(),
                        style: AppTextStyles.small(
                          context,
                          color: AppColors.getTextMuted(context),
                          fontSize: 8.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                subtitle: Padding(
                  padding: EdgeInsets.only(top: AppSizes.h4),
                  child: Text(
                    t.merchant.trim().isNotEmpty
                        ? "${t.type == TransactionType.credit ? 'From' : 'Payee'}: ${t.merchant} • ${DateFormat('hh:mm a').format(t.date)}"
                        : DateFormat('hh:mm a').format(t.date),
                    style: AppTextStyles.small(
                      context,
                      color: AppColors.getTextMuted(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                trailing: Text(
                  '${t.type == TransactionType.credit ? '+' : '-'}₹${AppColors.formatShortAmount(t.amount)}',
                  style: AppTextStyles.headline(
                    context,
                    color: t.type == TransactionType.credit
                        ? AppColors.success
                        : AppColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildScanBox(BuildContext context, WidgetRef ref, bool isSyncing) {
    return Container(
      margin: EdgeInsets.fromLTRB(
        AppSizes.w(20),
        AppSizes.h24,
        AppSizes.w(20),
        0,
      ),
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
                  style: AppTextStyles.body(
                    context,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: AppSizes.h8),
          Text(
            'If a recent payment wasn\'t detected, try scanning your SMS inbox again. Note: Encrypted RCS messages cannot be detected due to system privacy.',
            style: AppTextStyles.small(context, color: AppColors.textMuted),
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
                    style: TextStyle(fontSize: 11.sp),
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
                    style: TextStyle(fontSize: 11.sp),
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
      margin: EdgeInsets.fromLTRB(
        AppSizes.w(20),
        AppSizes.h24,
        AppSizes.w(20),
        0,
      ),
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
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.body(
                    context,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: AppSizes.h8),
          Text(
            description,
            style: AppTextStyles.small(context, color: AppColors.textMuted),
          ),
          SizedBox(height: AppSizes.h12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onAllowPressed ?? () {
                    context.push('/app-permissions');
                  },
                  icon: const Icon(Icons.security_rounded),
                  label: Text(
                    'Allow Access',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
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
                  AppToast.show(context, 'Alert dismissed');
                },
                child: Text(
                  'Don\'t show again',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.getTextMuted(context),
                    fontWeight: FontWeight.w500,
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

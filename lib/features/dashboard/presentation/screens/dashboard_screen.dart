import 'package:smart_money_tracker/core/constants/app_sizes.dart';
import 'package:smart_money_tracker/core/constants/app_colors.dart';
import 'package:smart_money_tracker/core/theme/app_text_styles.dart';
import 'package:smart_money_tracker/core/models/transaction_model.dart';
import 'package:smart_money_tracker/features/main/presentation/screens/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:smart_money_tracker/features/auth/presentation/providers/auth_provider.dart';
import 'package:smart_money_tracker/features/sms_disclosure/presentation/providers/sms_disclosure_provider.dart';
import '../providers/transaction_provider.dart';
import 'package:smart_money_tracker/core/utils/app_toast.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_money_tracker/core/constants/app_routes.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/providers/settings_provider.dart';
import 'package:smart_money_tracker/core/constants/app_strings.dart';

import '../widgets/expandable_transaction_card.dart';
import 'package:smart_money_tracker/core/services/update_service.dart';
import 'package:smart_money_tracker/features/budget/domain/providers/budget_providers.dart';
import 'package:smart_money_tracker/features/budget/presentation/widgets/budget_progress_card.dart';

import 'package:smart_money_tracker/core/common/screens/update_screen.dart';
import 'package:smart_money_tracker/core/common/widgets/banner_ad_widget.dart';
import 'package:smart_money_tracker/core/services/analytics_service.dart';
import 'package:smart_money_tracker/core/services/app_review_service.dart';
import 'package:smart_money_tracker/core/constants/app_toast_messages.dart';
import 'package:smart_money_tracker/core/common/widgets/primary_button.dart';
import 'package:smart_money_tracker/core/common/widgets/enable_sms_scanner_bottom_sheet.dart';
import 'package:smart_money_tracker/core/services/notification_service.dart';

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
    final permissions = ref.watch(smsConsentRepositoryProvider);
    final settings = ref.watch(settingsProvider);

    final smsGranted = useState(false);
    final hasConsented = useState(false);
    final hasCheckedPermissions = useState(false);
    final isConsentBannerDismissed = useState(false);
    final isGenericBannerDismissed = useState(false);

    Future<void> checkPermissions() async {
      final isGranted = await Permission.sms.isGranted;
      final consented = await permissions.hasConsented();
      final prefs = await SharedPreferences.getInstance();
      final consentDismissed = prefs.getBool('dismiss_consent_banner') ?? false;
      final genericDismissed = prefs.getBool('dismiss_generic_banner') ?? false;

      smsGranted.value = isGranted;
      hasConsented.value = consented;
      isConsentBannerDismissed.value = consentDismissed;
      isGenericBannerDismissed.value = genericDismissed;
      hasCheckedPermissions.value = true;
    }

    Future<void> handleScanToday() async {
      final consentRepository = ref.read(smsConsentRepositoryProvider);
      final hasConsent = await consentRepository.hasConsented();
      final isPermissionGranted = await Permission.sms.isGranted;
      final isSettingsEnabled = ref.read(settingsProvider).smsConsentEnabled;

      if (!hasConsent || !isPermissionGranted || !isSettingsEnabled) {
        if (context.mounted) {
          showEnableSmsScannerModal(context);
        }
        return;
      }

      AnalyticsService.logEvent('scan_today_dashboard');
      if (context.mounted) {
        AppToast.show(context, AppToastMessages.scanning);
      }
      await ref.read(transactionSyncProvider.notifier).sync();
      if (context.mounted) {
        AppToast.show(context, AppToastMessages.scanned);
      }
    }

    void showScanTodayModal() {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (bottomSheetContext) {
          final isDark = AppColors.isDark(bottomSheetContext);
          return Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.white,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppSizes.r24),
              ),
            ),
            padding: EdgeInsets.fromLTRB(
              AppSizes.w24,
              AppSizes.h12,
              AppSizes.w24,
              AppSizes.h24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: AppSizes.w(48),
                    height: AppSizes.h4,
                    margin: EdgeInsets.only(bottom: AppSizes.h20),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.white.withValues(alpha: 0.2)
                          : AppColors.black.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppSizes.r(2)),
                    ),
                  ),
                ),

                // Title
                Text(
                  'Scan Today\'s Transactions',
                  style: AppTextStyles.subHeading(context).copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.getText(context),
                  ),
                ),
                SizedBox(height: AppSizes.h12),

                // Concise 5-6 lines of clear explanation
                Text(
                  'This will scan your device inbox for today\'s bank SMS alerts.\n\n'
                  'Please note that RCS / Chat messages from Google Messages cannot be detected due to Android\'s end-to-end encryption. '
                  'If you receive bank alerts as RCS messages, please add them manually using the + button.',
                  style: AppTextStyles.body(context).copyWith(
                    color: AppColors.getTextMuted(context),
                    height: 1.5,
                  ),
                ),
                SizedBox(height: AppSizes.h24),

                // Primary Action Button
                SafeArea(
                  top: false,
                  child: PrimaryButton(
                    text: 'Scan Today',
                    onPressed: () {
                      Navigator.pop(bottomSheetContext);
                      handleScanToday();
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    Future<void> onScanTodayPressed() async {
      final consentRepository = ref.read(smsConsentRepositoryProvider);
      final hasConsent = await consentRepository.hasConsented();
      final isPermissionGranted = await Permission.sms.isGranted;
      final isSettingsEnabled = ref.read(settingsProvider).smsConsentEnabled;

      if (!hasConsent || !isPermissionGranted || !isSettingsEnabled) {
        if (context.mounted) {
          showEnableSmsScannerModal(context);
        }
        return;
      }

      if (context.mounted) {
        showScanTodayModal();
      }
    }

    useEffect(() {
      AnalyticsService.logScreenView('DashboardScreen');
      checkPermissions();

      // Prompt for notification permission on first install for the Daily Summary
      SharedPreferences.getInstance().then((prefs) async {
        final hasAsked =
            prefs.getBool('has_asked_daily_reminder_permission') ?? false;
        if (!hasAsked) {
          final status = await Permission.notification.request();
          await prefs.setBool('is_daily_reminder_enabled', status.isGranted);
          await prefs.setBool('has_asked_daily_reminder_permission', true);
          if (status.isGranted) {
            final todayTransactions =
                ref.read(todayTransactionsProvider).value ?? [];
            double totalExpense = 0.0;
            double totalIncome = 0.0;
            for (final t in todayTransactions) {
              if (t.type == TransactionType.credit) {
                totalIncome += t.amount;
              } else {
                totalExpense += t.amount;
              }
            }
            await NotificationService.updateDailyReminderState(
              totalIncome: totalIncome,
              totalExpense: totalExpense,
            );
          }
        }
      });

      final observer = _DashboardLifecycleObserver(onResume: checkPermissions);
      WidgetsBinding.instance.addObserver(observer);

      final authState = ref.read(authStateProvider);
      final userId = authState.value?.id;
      if (userId != null) {
        final updateState = ref.read(updateProvider).value;
        final config = updateState?.config;
        AppReviewService().checkAndRequestReview(
          reviewDays: config?.reviewDays ?? 14,
        );
      }

      return () {
        WidgetsBinding.instance.removeObserver(observer);
      };
    }, [settings]);

    ref.listen(updateProvider, (previous, next) {
      next.when(
        data: (state) {
          if (state.status != UpdateStatus.none && state.config != null) {
            context.push(
              AppRoutes.update,
              extra: UpdateScreenArgs(
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
    final allBudgets = ref.watch(budgetProgressProvider);
    final isBudgetsLoading = ref.watch(budgetsProvider).isLoading;
    final now = DateTime.now();

    // Only show current/active budgets on the dashboard
    final budgetProgressList = allBudgets.where((b) {
      if (b.isCompleted || b.budget.isStopped) return false;
      if (b.isUpcoming) {
        // Only show upcoming custom budgets if their start date lies within the current month
        if (b.periodStart == null) return false;
        return b.periodStart!.year == now.year &&
            b.periodStart!.month == now.month;
      }
      return true;
    }).toList();

    final showScanBox =
        useState(false).value && // Hidden for now
        hasCheckedPermissions.value &&
        settings.smsConsentEnabled &&
        smsGranted.value &&
        hasConsented.value;

    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AppBar(
        backgroundColor: AppColors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.menu_rounded, size: AppSizes.r(28)),
          onPressed: () =>
              ref.read(mainScaffoldKeyProvider).currentState?.openDrawer(),
        ),
        title: Text(
          AppStrings.baseAppName,
          style: AppTextStyles.heading(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.search_rounded,
              color: AppColors.getText(context),
              size: AppSizes.r24,
            ),
            tooltip: 'Scan Today',
            onPressed: onScanTodayPressed,
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(AppSizes.w12),
        child: CustomScrollView(
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
                    error: (_, _) => _getGreeting(),
                  );
                  return Text(
                    greetingText,
                    style: AppTextStyles.subHeading(
                      context,
                    ).copyWith(fontWeight: FontWeight.bold),
                  );
                },
              ),
            ),

            // Budget Loading
            if (isBudgetsLoading && budgetProgressList.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSizes.h24),
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),

            // Promo Cards Section
            if (budgetProgressList.isEmpty && !isBudgetsLoading)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(
                    top: AppSizes.h16,
                    bottom: AppSizes.h16,
                  ),
                  child: _buildPromoCard(
                    context,
                    icon: Icons.savings,
                    title: 'Create a budget',
                    subtitle:
                        'Most people underestimate small daily expenses, but they can add up significantly by the end of the month.',
                    actionText: 'Create now',
                    onTap: () => context.push(AppRoutes.createBudget),
                  ),
                ),
              ),

            // Budget Section
            if (budgetProgressList.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(
                    top: AppSizes.h16,
                    bottom: AppSizes.h16,
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ...budgetProgressList.map((progress) {
                            return Padding(
                              padding: EdgeInsets.only(right: AppSizes.w8),
                              child: SizedBox(
                                width: MediaQuery.of(context).size.width * 0.45,
                                child: BudgetProgressCard(
                                  progress: progress,
                                  onTap: () => context.push(
                                    AppRoutes.budgetDetail,
                                    extra: progress,
                                  ),
                                ),
                              ),
                            );
                          }),
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.45,
                            child: _buildCreateBudgetCard(context),
                          ),
                        ],
                      ),
                    ),
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
                  final isSyncing = ref
                      .watch(transactionSyncProvider)
                      .isLoading;
                  final isSmsToggledOn = settings.smsConsentEnabled;
                  Widget? permissionBanner;
                  Widget? scanBox;

                  if (!hasConsented.value && !isConsentBannerDismissed.value) {
                    permissionBanner = _buildPermissionBanner(
                      context,
                      title: 'Consent Required',
                      description:
                          'Explicit consent is required to automatically parse transactions. Please provide consent to continue.',
                      isPermissionBannerDismissed: isConsentBannerDismissed,
                      prefKey: 'dismiss_consent_banner',
                      onAllowPressed: () async {
                        await context.push('/permissions');
                        checkPermissions();
                      },
                    );
                  } else if (hasConsented.value) {
                    final isSmsFullyEnabled =
                        isSmsToggledOn && smsGranted.value;

                    if (!isSmsFullyEnabled && !isGenericBannerDismissed.value) {
                      permissionBanner = _buildPermissionBanner(
                        context,
                        title: 'Allow Permissions',
                        description:
                            'Please turn on and grant SMS permissions to detect your transactions.',
                        isPermissionBannerDismissed: isGenericBannerDismissed,
                        prefKey: 'dismiss_generic_banner',
                        onAllowPressed: () async {
                          await context.push('/settings');
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
            SliverToBoxAdapter(child: const BannerAdWidget()),

            // Recent Transactions Header
            SliverToBoxAdapter(
              child: transactionsAsync.maybeWhen(
                data: (transactions) {
                  final dailyExpense = transactions
                      .where((t) => t.type == TransactionType.debit)
                      .fold(0.0, (sum, t) => sum + t.amount);

                  final dailyIncome = transactions
                      .where((t) => t.type == TransactionType.credit)
                      .fold(0.0, (sum, t) => sum + t.amount);

                  final creditCount = transactions
                      .where((t) => t.type == TransactionType.credit)
                      .length;

                  final debitCount = transactions
                      .where((t) => t.type != TransactionType.credit)
                      .length;

                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: AppColors.transparent,
                        isScrollControlled: true,
                        builder: (modalContext) {
                          final isDark = AppColors.isDark(modalContext);
                          return Container(
                            padding: EdgeInsets.fromLTRB(
                              AppSizes.w24,
                              AppSizes.h12,
                              AppSizes.w24,
                              AppSizes.h24,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.surfaceDark
                                  : AppColors.white,
                              borderRadius: AppSizes.boxBorderRadius,
                            ),
                            child: SafeArea(
                              top: false,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Center(
                                    child: Container(
                                      width: AppSizes.w(48),
                                      height: AppSizes.h4,
                                      margin: EdgeInsets.only(
                                        bottom: AppSizes.h20,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? AppColors.white.withValues(
                                                alpha: 0.12,
                                              )
                                            : AppColors.black.withValues(
                                                alpha: 0.08,
                                              ),
                                        borderRadius: AppSizes.boxBorderRadius,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: AppSizes.h24),
                                  Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Total Credit',
                                                style:
                                                    AppTextStyles.body(
                                                      modalContext,
                                                    ).copyWith(
                                                      color:
                                                          AppColors.getTextMuted(
                                                            modalContext,
                                                          ),
                                                    ),
                                              ),
                                              SizedBox(height: AppSizes.h4),
                                              Text(
                                                '$creditCount transaction${creditCount == 1 ? '' : 's'}',
                                                style: AppTextStyles.small(
                                                  modalContext,
                                                  color: AppColors.getTextMuted(
                                                    modalContext,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          Text(
                                            '₹${AppColors.formatShortAmount(dailyIncome)}',
                                            style:
                                                AppTextStyles.body(
                                                  modalContext,
                                                ).copyWith(
                                                  color: AppColors.success,
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: AppSizes.h16),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Total Debit',
                                                style:
                                                    AppTextStyles.body(
                                                      modalContext,
                                                    ).copyWith(
                                                      color:
                                                          AppColors.getTextMuted(
                                                            modalContext,
                                                          ),
                                                    ),
                                              ),
                                              SizedBox(height: AppSizes.h4),
                                              Text(
                                                '$debitCount transaction${debitCount == 1 ? '' : 's'}',
                                                style: AppTextStyles.small(
                                                  modalContext,
                                                  color: AppColors.getTextMuted(
                                                    modalContext,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          Text(
                                            '₹${AppColors.formatShortAmount(dailyExpense)}',
                                            style:
                                                AppTextStyles.body(
                                                  modalContext,
                                                ).copyWith(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                    child: Padding(
                      padding: EdgeInsets.only(
                        bottom: AppSizes.h8,
                        top: AppSizes.h8,
                      ),
                      child: Text(
                        'Today\'s Transactions',
                        style: AppTextStyles.subHeading(
                          context,
                        ).copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                },
                orElse: () => Padding(
                  padding: EdgeInsets.only(
                    bottom: AppSizes.h8,
                    top: AppSizes.h8,
                  ),
                  child: Text(
                    'Today\'s Transactions',
                    style: AppTextStyles.subHeading(
                      context,
                    ).copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),

            transactionsAsync.when(
              data: (transactions) {
                if (transactions.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: AppSizes.h(64),
                        bottom: AppSizes.h(40),
                      ),
                      child: Center(
                        child: Text(
                          'No transactions today',
                          style: AppTextStyles.body(
                            context,
                            color: AppColors.getTextMuted(context),
                          ),
                        ),
                      ),
                    ),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final t = transactions[index];
                    return _buildTransactionCard(context, t);
                  }, childCount: transactions.length),
                );
              },
              loading: () => const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
              error: (err, _) => SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      'Something went wrong',
                      style: AppTextStyles.body(context),
                    ),
                  ),
                ),
              ),
            ), // Extra padding at bottom for navigation bar clearance
            SliverToBoxAdapter(child: SizedBox(height: AppSizes.h(80))),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionCard(BuildContext context, TransactionModel t) {
    return ExpandableTransactionCard(
      transaction: t,
      margin: EdgeInsets.symmetric(
        horizontal: AppSizes.w8,
        vertical: AppSizes.h4,
      ),
      onTap: () {
        context.push(AppRoutes.transactionDetail, extra: t);
      },
    );
  }

  Widget _buildScanBox(BuildContext context, WidgetRef ref, bool isSyncing) {
    return Container(
      margin: EdgeInsets.only(top: AppSizes.h8, bottom: AppSizes.h8),
      padding: EdgeInsets.all(AppSizes.r16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: AppSizes.cardBorderRadius,
        border: AppColors.isDark(context)
            ? null
            : Border.all(
                color: AppColors.black.withValues(alpha: 0.08),
                width: 1,
              ),
        boxShadow: AppColors.isDark(context)
            ? null
            : [
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.03),
                  blurRadius: 16,
                  spreadRadius: 0,
                  offset: Offset.zero,
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.help_outline_rounded,
                size: AppSizes.r20,
                color: AppColors.getText(context),
              ),
              SizedBox(width: AppSizes.w8),
              Text(
                'Missing a transaction?',
                style: AppTextStyles.subHeading(
                  context,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          SizedBox(height: AppSizes.h8),
          Text(
            'RCS and chat messages cannot be auto-detected. Add them manually.',
            style: AppTextStyles.body(
              context,
              color: AppColors.getTextMuted(context),
            ),
          ),
          SizedBox(height: AppSizes.h12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: isSyncing
                      ? null
                      : () {
                          ref.read(transactionSyncProvider.notifier).sync();
                        },
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: AppSizes.h(10)),
                    decoration: BoxDecoration(
                      color: AppColors.getTextMuted(
                        context,
                      ).withValues(alpha: 0.15),
                      borderRadius: AppSizes.cardBorderRadius,
                    ),
                    child: Center(
                      child: isSyncing
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: AppSizes.r16,
                                  height: AppSizes.r16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.getText(context),
                                  ),
                                ),
                                SizedBox(width: AppSizes.w8),
                                Text(
                                  'Scanning...',
                                  style: AppTextStyles.body(
                                    context,
                                  ).copyWith(fontWeight: FontWeight.w600),
                                ),
                              ],
                            )
                          : Text(
                              'Scan Today',
                              style: AppTextStyles.body(
                                context,
                              ).copyWith(fontWeight: FontWeight.w600),
                            ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: AppSizes.w8),
              Expanded(
                child: GestureDetector(
                  onTap: () => context.push(AppRoutes.addTransaction),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: AppSizes.h(10)),
                    decoration: BoxDecoration(
                      color: AppColors.getTextMuted(
                        context,
                      ).withValues(alpha: 0.15),
                      borderRadius: AppSizes.cardBorderRadius,
                    ),
                    child: Center(
                      child: Text(
                        'Add Manually',
                        style: AppTextStyles.body(
                          context,
                        ).copyWith(fontWeight: FontWeight.w600),
                      ),
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
    required String prefKey,
    VoidCallback? onAllowPressed,
  }) {
    return Container(
      padding: EdgeInsets.all(AppSizes.r16),
      margin: EdgeInsets.only(top: AppSizes.h8, bottom: AppSizes.h16),
      decoration: BoxDecoration(
        color: AppColors.getSurfaceContainerLowest(context),
        borderRadius: AppSizes.cardBorderRadius,
        border: AppColors.isDark(context)
            ? null
            : Border.all(
                color: AppColors.black.withValues(alpha: 0.08),
                width: 1,
              ),
        boxShadow: AppColors.isDark(context)
            ? null
            : [
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.03),
                  blurRadius: 16,
                  spreadRadius: 0,
                  offset: Offset.zero,
                ),
              ],
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
              SizedBox(width: AppSizes.w8),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.subHeading(context).copyWith(),
                ),
              ),
            ],
          ),
          SizedBox(height: AppSizes.h8),
          Text(
            description,
            style: AppTextStyles.body(
              context,
            ).copyWith(color: AppColors.getTextMuted(context)),
          ),
          SizedBox(height: AppSizes.h12),
          Row(
            children: [
              TextButton(
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool(prefKey, true);
                  isPermissionBannerDismissed.value = true;
                },
                child: Text(
                  'Don\'t show again',
                  style: AppTextStyles.body(
                    context,
                    color: AppColors.getTextMuted(context),
                  ),
                ),
              ),
              SizedBox(width: AppSizes.w12),
              Expanded(
                child: ElevatedButton(
                  onPressed:
                      onAllowPressed ??
                      () {
                        context.push(AppRoutes.settings);
                      },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(vertical: AppSizes.h(12)),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppSizes.cardBorderRadius,
                    ),
                  ),
                  child: Text(
                    'Allow Access',
                    style: AppTextStyles.body(
                      context,
                      color: AppColors.white,
                    ).copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPromoCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String actionText,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(AppSizes.r16),
        decoration: BoxDecoration(
          color: AppColors.getSurfaceContainerLowest(context),
          borderRadius: AppSizes.cardBorderRadius,
          border: AppColors.isDark(context)
              ? null
              : Border.all(
                  color: AppColors.black.withValues(alpha: 0.08),
                  width: 1,
                ),
          boxShadow: AppColors.isDark(context)
              ? null
              : [
                  BoxShadow(
                    color: AppColors.black.withValues(alpha: 0.03),
                    blurRadius: 16,
                    spreadRadius: 0,
                    offset: Offset.zero,
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary, size: AppSizes.r20),
                SizedBox(width: AppSizes.w8),
                Expanded(
                  child: Text(title, style: AppTextStyles.subHeading(context)),
                ),
              ],
            ),
            SizedBox(height: AppSizes.h8),
            Text(
              subtitle,
              style: AppTextStyles.body(
                context,
              ).copyWith(color: AppColors.getTextMuted(context)),
            ),
            SizedBox(height: AppSizes.h12),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                actionText,
                style: AppTextStyles.body(
                  context,
                  color: AppColors.getTextMuted(context),
                ).copyWith(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateBudgetCard(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(AppRoutes.createBudget),
      child: Container(
        padding: EdgeInsets.all(AppSizes.r16),
        decoration: BoxDecoration(
          color: AppColors.getSurfaceContainerLowest(context),
          borderRadius: AppSizes.cardBorderRadius,
          border: AppColors.isDark(context)
              ? null
              : Border.all(
                  color: AppColors.black.withValues(alpha: 0.08),
                  width: 1,
                ),
          boxShadow: AppColors.isDark(context)
              ? null
              : [
                  BoxShadow(
                    color: AppColors.black.withValues(alpha: 0.03),
                    blurRadius: 16,
                    spreadRadius: 0,
                    offset: Offset.zero,
                  ),
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_circle_outline_rounded,
              color: AppColors.getTextMuted(context),
              size: AppSizes.r(32),
            ),
            SizedBox(height: AppSizes.h8),
            Text(
              'Create Budget',
              style: AppTextStyles.body(
                context,
              ).copyWith(color: AppColors.getTextMuted(context)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
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

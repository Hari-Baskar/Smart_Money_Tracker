import 'package:smart_money_tracker/core/constants/app_sizes.dart';
import 'package:smart_money_tracker/core/constants/app_colors.dart';
import 'package:smart_money_tracker/core/theme/app_text_styles.dart';
import 'package:smart_money_tracker/core/models/transaction_model.dart';
import 'package:smart_money_tracker/core/constants/payment_constants.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/providers/transaction_provider.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/screens/history_filter_screen.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/screens/download_report_screen.dart';
import '../widgets/expandable_transaction_card.dart';
import '../widgets/history_summary_card.dart';
import 'package:smart_money_tracker/features/main/presentation/screens/main_screen.dart';
import 'package:smart_money_tracker/core/common/widgets/banner_ad_widget.dart';
import '../providers/custom_asset_provider.dart';
import '../providers/subcategory_provider.dart';
import 'package:smart_money_tracker/core/services/analytics_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/providers/settings_provider.dart';
import 'package:smart_money_tracker/core/utils/app_toast.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:smart_money_tracker/core/constants/app_strings.dart';
import 'package:smart_money_tracker/features/sms_disclosure/presentation/providers/sms_disclosure_provider.dart';
import 'package:smart_money_tracker/core/common/widgets/custom_month_year_picker_sheet.dart';
import 'package:smart_money_tracker/core/services/update_service.dart';
import 'package:smart_money_tracker/core/constants/app_routes.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_money_tracker/core/constants/app_toast_messages.dart';
import 'package:flutter/material.dart';

class HistoryScreen extends HookConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasUsedFreeScan = useState(false);
    final isSyncing30Days = useState(false);
    final canUseSmsScanner = useState(false);
    final settings = ref.watch(settingsProvider);
    final isSmsConsentEnabled = settings.smsConsentEnabled;
    final lifecycleState = useAppLifecycleState();
    final config = ref.watch(updateProvider).value?.config;
    final showAds = config?.showAds ?? false;
    final showScanAd = config?.showScanAd ?? false;

    final rewardedAd = useState<RewardedAd?>(null);
    final isAdLoaded = useState(false);

    void loadRewardedAd() {
      final adUnitId = AppStrings.androidRewardedAdUnitId;

      RewardedAd.load(
        adUnitId: adUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            rewardedAd.value = ad;
            isAdLoaded.value = true;
            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdShowedFullScreenContent: (ad) {},
              onAdDismissedFullScreenContent: (ad) {
                ad.dispose();
                rewardedAd.value = null;
                isAdLoaded.value = false;
                loadRewardedAd();
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                ad.dispose();
                rewardedAd.value = null;
                isAdLoaded.value = false;
                loadRewardedAd();
              },
            );
          },
          onAdFailedToLoad: (error) {
            debugPrint('Failed to load rewarded ad: $error');
            isAdLoaded.value = false;
            rewardedAd.value = null;
          },
        ),
      );
    }

    useEffect(() {
      loadRewardedAd();
      return () {
        rewardedAd.value?.dispose();
      };
    }, const []);

    useEffect(() {
      AnalyticsService.logScreenView('HistoryScreen');
      SharedPreferences.getInstance().then((prefs) {
        hasUsedFreeScan.value = prefs.getBool('has_used_free_scan') ?? false;
      });
    }, const []);

    final smsDisclosureState = ref.watch(smsDisclosureNotifierProvider);

    useEffect(() {
      Future<void> checkSmsStatus() async {
        final hasConsented = await ref
            .read(smsConsentRepositoryProvider)
            .hasConsented();
        final hasPermission = await Permission.sms.isGranted;
        if (hasConsented && hasPermission && isSmsConsentEnabled) {
          canUseSmsScanner.value = true;
        } else {
          canUseSmsScanner.value = false;
        }
      }

      checkSmsStatus();
      return null;
    }, [settings, lifecycleState, smsDisclosureState.hasConsented]);

    final dateRange = useState(
      DateTimeRange(
        start: DateTime(DateTime.now().year, DateTime.now().month, 1),
        end: DateTime.now(),
      ),
    );
    final selectedCategoryState = useState('All');
    final selectedSubcategoryState = useState('All');
    final selectedBankIdState = useState<String?>(null);
    final selectedPaymentMethodIdState = useState<String?>(null);
    final transactionTypeState = useState<TransactionType?>(null);

    final customBankController = useTextEditingController();
    final customPaymentController = useTextEditingController();

    final isLoadingOlder = useState(false);
    final hasReachedEnd = useState(false);

    Future<void> handleFilterTap() async {
      final result = await context.push<HistoryFilterState>(
        AppRoutes.historyFilter,
        extra: HistoryFilterState(
          dateRange: dateRange.value,
          category: selectedCategoryState.value,
          subcategory: selectedSubcategoryState.value,
          bankId: selectedBankIdState.value,
          paymentMethodId: selectedPaymentMethodIdState.value,
          transactionType: transactionTypeState.value,
        ),
      );
      if (result != null) {
        dateRange.value = result.dateRange;
        selectedCategoryState.value = result.category;
        selectedSubcategoryState.value = result.subcategory;
        selectedBankIdState.value = result.bankId;
        selectedPaymentMethodIdState.value = result.paymentMethodId;
        transactionTypeState.value = result.transactionType;
      }
    }

    Future<void> handleScanHistory() async {
      if (!canUseSmsScanner.value) {
        AppToast.show(context, AppToastMessages.enableSmsScanner);
        return;
      }
      final settings = ref.read(settingsProvider);
      final selectedMonth = await _showMonthPicker(
        context,
        settings.scannedMonths,
      );
      if (selectedMonth != null) {
        final monthKey =
            '${selectedMonth.year}-${selectedMonth.month.toString().padLeft(2, '0')}';

        void updateFilterToScannedMonth() {
          final lastDay = DateTime(
            selectedMonth.year,
            selectedMonth.month + 1,
            0,
          );
          dateRange.value = DateTimeRange(start: selectedMonth, end: lastDay);
        }

        if (showScanAd && isAdLoaded.value && rewardedAd.value != null) {
          await rewardedAd.value!.show(
            onUserEarnedReward: (AdWithoutView ad, RewardItem reward) async {
              AnalyticsService.logEvent('Monthly Scan');

              final stopwatch = Stopwatch()..start();
              isSyncing30Days.value = true;
              await ref
                  .read(transactionSyncProvider.notifier)
                  .syncSpecificMonth(selectedMonth.year, selectedMonth.month);
              await ref
                  .read(settingsProvider.notifier)
                  .addScannedMonth(monthKey);
              updateFilterToScannedMonth();
              isSyncing30Days.value = false;
              stopwatch.stop();
              AppToast.show(context, AppToastMessages.scanned);
            },
          );
        } else {
          // Fallback if ad fails to load
          final stopwatch = Stopwatch()..start();
          isSyncing30Days.value = true;
          await ref
              .read(transactionSyncProvider.notifier)
              .syncSpecificMonth(selectedMonth.year, selectedMonth.month);
          await ref.read(settingsProvider.notifier).addScannedMonth(monthKey);
          updateFilterToScannedMonth();
          isSyncing30Days.value = false;
          stopwatch.stop();
          AppToast.show(context, AppToastMessages.scanned);
        }
      }
    }

    // Shortcuts
    final selectedCategory = selectedCategoryState.value;
    final selectedSubcategory = selectedSubcategoryState.value;
    final currentDateRange = dateRange.value;
    final selectedBankId = selectedBankIdState.value;
    final selectedPaymentMethodId = selectedPaymentMethodIdState.value;
    final activeFilterCount = [
      transactionTypeState.value != null,
      selectedCategory != 'All',
      selectedSubcategory != 'All',
      selectedBankId != null,
      selectedPaymentMethodId != null,
    ].where((f) => f).length;

    final subcategoriesAsync = ref.watch(subcategoriesProvider);
    String subcategoryLabel = selectedSubcategory;
    if (selectedSubcategory != 'All' && subcategoriesAsync.hasValue) {
      final match = subcategoriesAsync.value!
          .where((s) => s.id == selectedSubcategory)
          .firstOrNull;
      if (match != null) {
        subcategoryLabel = match.name;
      }
    }

    final customAssetsAsync = ref.watch(customAssetsProvider);
    final customAssets = customAssetsAsync.value ?? const [];

    String? getDisplayBankName(String? id) {
      if (id == null) return null;
      final customBank = customAssets
          .where((a) => a.id == id && a.type == 'bank')
          .firstOrNull;
      if (customBank != null) {
        return customBank.isArchived
            ? '${customBank.name} (Archived)'
            : customBank.name;
      }
      return PaymentConstants.getBankName(id) ?? 'None';
    }

    String? getDisplayPaymentName(String? id) {
      if (id == null) return null;
      final customPayment = customAssets
          .where((a) => a.id == id && a.type == 'payment_method')
          .firstOrNull;
      if (customPayment != null) {
        return customPayment.isArchived
            ? '${customPayment.name} (Archived)'
            : customPayment.name;
      }
      return PaymentConstants.getPaymentMethodName(id) ?? 'None';
    }

    final startOfRange = DateTime(
      currentDateRange.start.year,
      currentDateRange.start.month,
      currentDateRange.start.day,
    );
    final endOfRange = DateTime(
      currentDateRange.end.year,
      currentDateRange.end.month,
      currentDateRange.end.day,
      23,
      59,
      59,
      999,
    );
    final adjustedRange = DateTimeRange(start: startOfRange, end: endOfRange);

    final transactionsAsync = ref.watch(
      transactionsInDateRangeProvider(adjustedRange),
    );

    Future<void> pickMonthForFilter() async {
      final settings = ref.read(settingsProvider);
      final selectedMonth = await _showMonthPicker(
        context,
        settings.scannedMonths,
      );
      if (selectedMonth != null) {
        final lastDay = DateTime(
          selectedMonth.year,
          selectedMonth.month + 1,
          0,
        );
        dateRange.value = DateTimeRange(start: selectedMonth, end: lastDay);
      }
    }

    List<TransactionModel> getFilteredTransactions() {
      final transactions = transactionsAsync.value;
      if (transactions == null) return [];

      final dateFiltered = transactions.where((t) {
        return t.date.isAfter(
              currentDateRange.start.subtract(const Duration(seconds: 1)),
            ) &&
            t.date.isBefore(currentDateRange.end.add(const Duration(days: 1)));
      }).toList();

      final List<TransactionModel> finalFiltered = [];

      for (var t in dateFiltered) {
        if (transactionTypeState.value != null &&
            t.type != transactionTypeState.value)
          continue;
        if (selectedBankId != null && t.bankId != selectedBankId) continue;
        if (selectedPaymentMethodId != null &&
            t.paymentMethodId != selectedPaymentMethodId)
          continue;

        if (selectedCategory == 'All') {
          if (selectedSubcategory == 'All' ||
              t.subcategory == selectedSubcategory) {
            finalFiltered.add(t);
          }
        } else {
          if (t.splits.isEmpty) {
            if (t.category == selectedCategory &&
                (selectedSubcategory == 'All' ||
                    t.subcategory == selectedSubcategory)) {
              finalFiltered.add(t);
            }
          } else {
            double splitTotal = 0;
            int splitIndex = 0;
            for (var split in t.splits) {
              splitTotal += split.amount;
              if (split.category == selectedCategory &&
                  (selectedSubcategory == 'All' ||
                      split.subcategory == selectedSubcategory)) {
                finalFiltered.add(
                  TransactionModel(
                    id: '${t.id}_split_$splitIndex',
                    amount: split.amount,
                    merchant: t.merchant,
                    date: split.date ?? t.date,
                    type: t.type,
                    category: split.category,
                    subcategory: split.subcategory,
                    rawSms: t.rawSms,
                    splits: const [],
                    isEdited: t.isEdited,
                    reference: t.reference,
                    bankId: t.bankId,
                    paymentMethodId: t.paymentMethodId,
                  ),
                );
              }
              splitIndex++;
            }
            final remainder = t.amount - splitTotal;
            if (remainder > 0.01) {
              if (t.category == selectedCategory &&
                  (selectedSubcategory == 'All' ||
                      t.subcategory == selectedSubcategory)) {
                finalFiltered.add(
                  TransactionModel(
                    id: '${t.id}_remainder',
                    amount: remainder,
                    merchant: t.merchant,
                    date: t.date,
                    type: t.type,
                    category: t.category,
                    subcategory: t.subcategory,
                    rawSms: t.rawSms,
                    splits: const [],
                    isEdited: t.isEdited,
                    reference: t.reference,
                    bankId: t.bankId,
                    paymentMethodId: t.paymentMethodId,
                  ),
                );
              }
            }
          }
        }
      }
      return finalFiltered;
    }

    int activeFiltersCount = 0;
    if (selectedCategoryState.value != 'All') activeFiltersCount++;
    if (selectedSubcategoryState.value != 'All') activeFiltersCount++;
    if (selectedBankIdState.value != null) activeFiltersCount++;
    if (selectedPaymentMethodIdState.value != null) activeFiltersCount++;
    if (transactionTypeState.value != null) activeFiltersCount++;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: AppColors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.menu_rounded, size: AppSizes.r(28)),
          onPressed: () =>
              ref.read(mainScaffoldKeyProvider).currentState?.openDrawer(),
        ),
        title: Text('History', style: AppTextStyles.heading(context)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: activeFiltersCount > 0,
              label: Text(
                activeFiltersCount.toString(),
                style: AppTextStyles.body(
                  context,
                  color: AppColors.white,
                ).copyWith(fontSize: 10),
              ),
              backgroundColor: AppColors.primary,
              child: Icon(
                Icons.filter_list_rounded,
                color: AppColors.getText(context),
                size: AppSizes.r(24),
              ),
            ),
            onPressed: handleFilterTap,
          ),
        ],
      ),
      body: isSyncing30Days.value
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  SizedBox(height: AppSizes.h16),
                  Text(
                    'Scanning SMS... Please wait',
                    style: AppTextStyles.body(context),
                  ),
                ],
              ),
            )
          : Padding(
              padding: EdgeInsets.only(bottom: AppSizes.h12),
              child: Column(
                children: [
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        final transactions = transactionsAsync.value;

                        if (transactions != null) {
                          // 1. Filter by Date Range (already handled by provider range)
                          final dateFiltered = transactions.where((t) {
                            return t.date.isAfter(
                                  currentDateRange.start.subtract(
                                    const Duration(seconds: 1),
                                  ),
                                ) &&
                                t.date.isBefore(
                                  currentDateRange.end.add(
                                    const Duration(days: 1),
                                  ),
                                );
                          }).toList();

                          // 2. Filter by Category, Subcategory, Bank, PaymentMethod & Calculate Totals
                          double totalSpent = 0;
                          double totalIncome = 0;
                          final List<TransactionModel> finalFiltered = [];

                          for (var t in dateFiltered) {
                            // Transaction Type filter
                            if (transactionTypeState.value != null &&
                                t.type != transactionTypeState.value) {
                              continue;
                            }
                            // Bank filter
                            if (selectedBankId != null &&
                                t.bankId != selectedBankId) {
                              continue;
                            }
                            // Payment method filter
                            if (selectedPaymentMethodId != null &&
                                t.paymentMethodId != selectedPaymentMethodId) {
                              continue;
                            }

                            if (selectedCategory == 'All') {
                              final subcategoryMatch =
                                  selectedSubcategory == 'All' ||
                                  t.subcategory == selectedSubcategory;
                              if (subcategoryMatch) {
                                finalFiltered.add(t);
                                if (t.type == TransactionType.credit) {
                                  totalIncome += t.amount;
                                } else {
                                  totalSpent += t.amount;
                                }
                              }
                            } else {
                              if (t.splits.isEmpty) {
                                final categoryMatch =
                                    t.category == selectedCategory;
                                final subcategoryMatch =
                                    selectedSubcategory == 'All' ||
                                    t.subcategory == selectedSubcategory;
                                if (categoryMatch && subcategoryMatch) {
                                  finalFiltered.add(t);
                                  if (t.type == TransactionType.credit) {
                                    totalIncome += t.amount;
                                  } else {
                                    totalSpent += t.amount;
                                  }
                                }
                              } else {
                                // Transaction has splits, and category filter is NOT 'All'.
                                double splitTotal = 0;
                                int splitIndex = 0;
                                for (var split in t.splits) {
                                  splitTotal += split.amount;
                                  final categoryMatch =
                                      split.category == selectedCategory;
                                  final subcategoryMatch =
                                      selectedSubcategory == 'All' ||
                                      split.subcategory == selectedSubcategory;

                                  if (categoryMatch && subcategoryMatch) {
                                    final virtualTxn = TransactionModel(
                                      id: '${t.id}_split_$splitIndex',
                                      amount: split.amount,
                                      merchant: t.merchant,
                                      date: split.date ?? t.date,
                                      type: t.type,
                                      category: split.category,
                                      subcategory: split.subcategory,
                                      rawSms: t.rawSms,
                                      splits: const [],
                                      isEdited: t.isEdited,
                                      reference: t.reference,
                                      bankId: t.bankId,
                                      paymentMethodId: t.paymentMethodId,
                                    );
                                    finalFiltered.add(virtualTxn);
                                    if (t.type == TransactionType.credit) {
                                      totalIncome += split.amount;
                                    } else {
                                      totalSpent += split.amount;
                                    }
                                  }
                                  splitIndex++;
                                }

                                final remainder = t.amount - splitTotal;
                                if (remainder > 0.01) {
                                  final categoryMatch =
                                      t.category == selectedCategory;
                                  final subcategoryMatch =
                                      selectedSubcategory == 'All' ||
                                      t.subcategory == selectedSubcategory;
                                  if (categoryMatch && subcategoryMatch) {
                                    final virtualRemainder = TransactionModel(
                                      id: '${t.id}_remainder',
                                      amount: remainder,
                                      merchant: t.merchant,
                                      date: t.date,
                                      type: t.type,
                                      category: t.category,
                                      subcategory: t.subcategory,
                                      rawSms: t.rawSms,
                                      splits: const [],
                                      isEdited: t.isEdited,
                                      reference: t.reference,
                                      bankId: t.bankId,
                                      paymentMethodId: t.paymentMethodId,
                                    );
                                    finalFiltered.add(virtualRemainder);
                                    if (t.type == TransactionType.credit) {
                                      totalIncome += remainder;
                                    } else {
                                      totalSpent += remainder;
                                    }
                                  }
                                }
                              }
                            }
                          }

                          int activeFilters = 0;
                          if (selectedCategory != 'All') activeFilters++;
                          if (selectedSubcategory != 'All') activeFilters++;
                          if (selectedBankId != null) activeFilters++;
                          if (selectedPaymentMethodId != null) activeFilters++;
                          if (transactionTypeState.value != null)
                            activeFilters++;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: ListView(
                                  children: [
                                    SizedBox(height: AppSizes.h12),
                                    // Dynamic Summary Card
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: AppSizes.w12,
                                      ),
                                      child: HistorySummaryCard(
                                        selectedCategory: selectedCategory,
                                        selectedSubcategory:
                                            selectedSubcategory,
                                        totalSpent: totalSpent,
                                        totalIncome: totalIncome,
                                        incomeCount: finalFiltered
                                            .where(
                                              (t) =>
                                                  t.type ==
                                                  TransactionType.credit,
                                            )
                                            .length,
                                        expenseCount: finalFiltered
                                            .where(
                                              (t) =>
                                                  t.type !=
                                                  TransactionType.credit,
                                            )
                                            .length,
                                        dateRange: currentDateRange,
                                        onFilterTap: handleFilterTap,
                                        activeFiltersCount: activeFilters,
                                      ),
                                    ),
                                    _buildActionsBanner(
                                      context,
                                      ref,
                                      ref
                                          .watch(transactionSyncProvider)
                                          .isLoading,
                                      canScan: canUseSmsScanner.value,
                                      onScan: handleScanHistory,
                                      onAnalysis: () {
                                        if (finalFiltered.isNotEmpty) {
                                          context.push(
                                            AppRoutes.historyAnalysis,
                                            extra: {
                                              'transactions': finalFiltered,
                                              'dateRange': currentDateRange,
                                            },
                                          );
                                        } else {
                                          AppToast.show(
                                            context,
                                            'No transactions for analysis',
                                          );
                                        }
                                      },
                                      onExport: () {
                                        if (finalFiltered.isEmpty) {
                                          AppToast.show(
                                            context,
                                            'No transactions to download',
                                          );
                                          return;
                                        }
                                        final activeFiltersList = <String>[];
                                        if (transactionTypeState.value !=
                                            null) {
                                          activeFiltersList.add(
                                            'Type: ${transactionTypeState.value == TransactionType.credit ? 'Income' : 'Expense'}',
                                          );
                                        }
                                        if (selectedBankId != null) {
                                          activeFiltersList.add(
                                            'Bank: ${getDisplayBankName(selectedBankId)}',
                                          );
                                        }
                                        if (selectedPaymentMethodId != null) {
                                          activeFiltersList.add(
                                            'Method: ${getDisplayPaymentName(selectedPaymentMethodId)}',
                                          );
                                        }
                                        if (selectedCategory != 'All') {
                                          activeFiltersList.add(
                                            'Category: $selectedCategory',
                                          );
                                        }
                                        if (selectedSubcategory != 'All') {
                                          activeFiltersList.add(
                                            'Subcategory: $selectedSubcategory',
                                          );
                                        }
                                        final filterStr =
                                            activeFiltersList.isEmpty
                                            ? 'All'
                                            : activeFiltersList.join(', ');
                                        AnalyticsService.logEvent(
                                          'download_history_report',
                                        );
                                        context.push(
                                          AppRoutes.downloadReport,
                                          extra: DownloadReportScreenArgs(
                                            transactions: finalFiltered,
                                            filterString: filterStr,
                                          ),
                                        );
                                      },
                                    ),
                                    // Banner Ad
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: AppSizes.h4,
                                        horizontal: AppSizes.w12,
                                      ),
                                      child: const BannerAdWidget(),
                                    ),
                                    //SizedBox(height: AppSizes.h16),

                                    // Header with Toggle
                                    Padding(
                                      padding: EdgeInsets.only(
                                        left: AppSizes.w16,
                                        right: AppSizes.w16,
                                        top: AppSizes.h8,
                                        bottom: AppSizes.h8,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Transaction History',
                                            style: AppTextStyles.subHeading(
                                              context,
                                            ),
                                          ),
                                          if (finalFiltered.isNotEmpty)
                                            TextButton(
                                              onPressed: () {
                                                context.push(
                                                  AppRoutes.budgetHistory,
                                                  extra: {
                                                    'transactions':
                                                        finalFiltered,
                                                    'budgetName': '',
                                                  },
                                                );
                                              },
                                              style: TextButton.styleFrom(
                                                padding: EdgeInsets.zero,
                                                minimumSize: Size.zero,
                                                tapTargetSize:
                                                    MaterialTapTargetSize
                                                        .shrinkWrap,
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    'View All',
                                                    style:
                                                        AppTextStyles.body(
                                                          context,
                                                          color:
                                                              AppColors.getTextMuted(
                                                                context,
                                                              ),
                                                        ).copyWith(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                  ),
                                                  SizedBox(width: AppSizes.w4),
                                                  Icon(
                                                    Icons
                                                        .arrow_forward_ios_rounded,
                                                    size: AppSizes.r12,
                                                    color:
                                                        AppColors.getTextMuted(
                                                          context,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    if (finalFiltered.isEmpty)
                                      Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: AppSizes.w12,
                                        ),
                                        child: SizedBox(
                                          height: AppSizes.h(
                                            250,
                                          ), // Reduced from 350 to bring it much higher up
                                          child: _buildEmptyState(
                                            context,
                                            activeFilterCount > 0
                                                ? 'No transactions match your filters'
                                                : 'No transactions',
                                            null,
                                            hasUsedFreeScan,
                                            isSyncing30Days,
                                            canUseSmsScanner.value,
                                            ref,
                                          ),
                                        ),
                                      )
                                    else ...[
                                      ...finalFiltered.take(10).map((txn) {
                                        return Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: AppSizes.w12,
                                          ),
                                          child: _buildTransactionCard(
                                            context,
                                            txn,
                                            transactions,
                                            isGrouped: false,
                                          ),
                                        );
                                      }).toList(),
                                      SizedBox(height: AppSizes.h32),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          );
                        }

                        if (transactionsAsync.hasError) {
                          return Center(
                            child: Text('Error: ${transactionsAsync.error}'),
                          );
                        }

                        return const Center(child: CircularProgressIndicator());
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Future<DateTime?> _showMonthPicker(
    BuildContext context,
    List<String> scannedMonths,
  ) async {
    final now = DateTime.now();
    return await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CustomMonthYearPickerSheet(
        initialDate: now,
        scannedMonths: scannedMonths,
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    String message, [
    VoidCallback? onAdjustFilters,
    ValueNotifier<bool>? hasUsedFreeScan,
    ValueNotifier<bool>? isSyncing,
    bool canUseSmsScanner = false,
    WidgetRef? ref,
  ]) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSizes.w16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: AppSizes.r(64),
              color: AppColors.getTextMuted(context).withOpacity(0.5),
            ),
            SizedBox(height: AppSizes.h8),
            Text(
              message,
              style: AppTextStyles.body(
                context,
                color: AppColors.getTextMuted(context),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSizes.h(80)), // Bring content up
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionCard(
    BuildContext context,
    TransactionModel t,
    List<TransactionModel> allTransactions, {
    bool isGrouped = false,
  }) {
    return ExpandableTransactionCard(
      transaction: t,
      isGrouped: isGrouped,
      margin: EdgeInsets.symmetric(vertical: AppSizes.h4),
      onTap: () {
        TransactionModel txToEdit = t;
        if (t.id.contains('_split_') || t.id.contains('_remainder')) {
          final parentId = t.id.split('_split_')[0].split('_remainder')[0];
          txToEdit = allTransactions.firstWhere(
            (tx) => tx.id == parentId,
            orElse: () => t,
          );
        }
        context.push(AppRoutes.transactionDetail, extra: txToEdit);
      },
    );
  }

  Widget _buildActionsBanner(
    BuildContext context,
    WidgetRef ref,
    bool isSyncing, {
    required bool canScan,
    required VoidCallback onScan,
    required VoidCallback onAnalysis,
    required VoidCallback onExport,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: AppSizes.w12,
        vertical: AppSizes.h8,
      ),
      padding: EdgeInsets.all(AppSizes.r16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: AppSizes.cardBorderRadius,
        border: AppColors.isDark(context)
            ? null
            : Border.all(color: AppColors.black.withOpacity(0.08), width: 1),
        boxShadow: AppColors.isDark(context)
            ? null
            : [
                BoxShadow(
                  color: AppColors.black.withOpacity(0.03),
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
                Icons.explore_outlined,
                size: AppSizes.r20,
                color: AppColors.getText(context),
              ),
              SizedBox(width: AppSizes.w8),
              Text(
                'Explore your history',
                style: AppTextStyles.subHeading(
                  context,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          SizedBox(height: AppSizes.h8),
          Text(
            'Use filters to customize your analysis and export targeted transaction reports.',
            style: AppTextStyles.body(
              context,
              color: AppColors.getTextMuted(context),
            ),
          ),
          SizedBox(height: AppSizes.h12),
          Row(
            children: [
              if (canScan) ...[
                Expanded(
                  child: GestureDetector(
                    onTap: isSyncing ? null : onScan,
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
                                    'Wait',
                                    style: AppTextStyles.body(
                                      context,
                                    ).copyWith(fontWeight: FontWeight.w600),
                                  ),
                                ],
                              )
                            : Text(
                                'Scan',
                                style: AppTextStyles.body(
                                  context,
                                ).copyWith(fontWeight: FontWeight.w600),
                              ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: AppSizes.w8),
              ],
              Expanded(
                child: GestureDetector(
                  onTap: onAnalysis,
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
                        'Analyze',
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
                  onTap: onExport,
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
                        'Export',
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

  // void _showExploreHistoryHelp(BuildContext context) {
  //   showModalBottomSheet(
  //     context: context,
  //     isScrollControlled: true,
  //     useSafeArea: true,
  //     backgroundColor: AppColors.getSurfaceContainerLowest(context),
  //     shape: RoundedRectangleBorder(
  //       borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.r24)),
  //     ),
  //     builder: (modalContext) => SafeArea(
  //       child: SingleChildScrollView(
  //         padding: EdgeInsets.symmetric(
  //           horizontal: AppSizes.w20,
  //           vertical: AppSizes.h20,
  //         ),
  //         child: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             Center(
  //               child: Container(
  //                 width: AppSizes.w(40),
  //                 height: AppSizes.h4,
  //                 margin: EdgeInsets.only(bottom: AppSizes.h16),
  //                 decoration: BoxDecoration(
  //                   color: AppColors.getTextMuted(
  //                     context,
  //                   ).withValues(alpha: 0.3),
  //                   borderRadius: BorderRadius.circular(AppSizes.r100),
  //                 ),
  //               ),
  //             ),
  //             Row(
  //               children: [
  //                 Container(
  //                   padding: EdgeInsets.all(AppSizes.r8),
  //                   decoration: BoxDecoration(
  //                     color: AppColors.getTextMuted(
  //                       context,
  //                     ).withValues(alpha: 0.15),
  //                     shape: BoxShape.circle,
  //                   ),
  //                   child: Icon(
  //                     Icons.explore_outlined,
  //                     color: AppColors.getText(context),
  //                     size: AppSizes.r20,
  //                   ),
  //                 ),
  //                 SizedBox(width: AppSizes.w12),
  //                 Expanded(
  //                   child: Text(
  //                     'Explore History Tools',
  //                     style: AppTextStyles.subHeading(
  //                       context,
  //                     ).copyWith(fontWeight: FontWeight.bold),
  //                   ),
  //                 ),
  //               ],
  //             ),
  //             SizedBox(height: AppSizes.h20),
  //             _buildHelpPoint(
  //               context,
  //               icon: Icons.search_rounded,
  //               title: 'Scan SMS',
  //               description:
  //                   'Scans your device SMS inbox to detect and import historical bank transactions for any month.',
  //             ),
  //             SizedBox(height: AppSizes.h12),
  //             _buildHelpPoint(
  //               context,
  //               icon: Icons.pie_chart_outline_rounded,
  //               title: 'Spending Analysis',
  //               description:
  //                   'Visual breakdowns of your expenses and income by category, percentages, daily averages, and trends.',
  //             ),
  //             SizedBox(height: AppSizes.h12),
  //             _buildHelpPoint(
  //               context,
  //               icon: Icons.download_rounded,
  //               title: 'Export Reports',
  //               description:
  //                   'Download formatted Excel (.xlsx) or PDF reports for selected date ranges or full history.',
  //             ),
  //             SizedBox(height: AppSizes.h24),
  //             PrimaryButton(
  //               text: 'Got it',
  //               isExpanded: true,
  //               onPressed: () => Navigator.of(modalContext).pop(),
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }

  // Widget _buildHelpPoint(
  //   BuildContext context, {
  //   required IconData icon,
  //   required String title,
  //   required String description,
  // }) {
  //   return Row(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Icon(
  //         icon,
  //         size: AppSizes.r(18),
  //         color: AppColors.getTextMuted(context),
  //       ),
  //       SizedBox(width: AppSizes.w12),
  //       Expanded(
  //         child: Column(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             Text(
  //               title,
  //               style: AppTextStyles.body(
  //                 context,
  //               ).copyWith(fontWeight: FontWeight.w600),
  //             ),
  //             SizedBox(height: AppSizes.h2),
  //             Text(
  //               description,
  //               style: AppTextStyles.small(context).copyWith(
  //                 color: AppColors.getTextMuted(context),
  //                 fontWeight: FontWeight.w600,
  //               ),
  //             ),
  //           ],
  //         ),
  //       ),
  //     ],
  //   );
  // }
}

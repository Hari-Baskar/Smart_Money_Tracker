import 'package:share_plus/share_plus.dart';
import 'package:smart_money_tracker/core/constants/app_sizes.dart';
import 'package:smart_money_tracker/core/constants/app_colors.dart';
import 'package:smart_money_tracker/core/theme/app_text_styles.dart';
import 'package:smart_money_tracker/core/models/transaction_model.dart';
import 'package:smart_money_tracker/core/constants/payment_constants.dart';
import 'package:smart_money_tracker/features/auth/presentation/providers/auth_provider.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/providers/transaction_provider.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/screens/history_filter_screen.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/screens/download_report_screen.dart';
import '../widgets/expandable_transaction_card.dart';
import '../widgets/history_summary_card.dart';
import '../widgets/history_analysis_view.dart';
import 'package:smart_money_tracker/features/main/presentation/screens/main_screen.dart';
import 'package:smart_money_tracker/core/common/widgets/banner_ad_widget.dart';
import '../providers/custom_asset_provider.dart';
import '../providers/subcategory_provider.dart';
import 'package:smart_money_tracker/core/models/custom_asset_model.dart';
import 'package:smart_money_tracker/core/services/analytics_service.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends HookConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useEffect(() {
      AnalyticsService.logScreenView('HistoryScreen');
      return null;
    }, const []);

    final filterState = useState(
      HistoryFilterState(
        dateRange: DateTimeRange(
          start: DateTime.now().subtract(const Duration(days: 30)),
          end: DateTime.now(),
        ),
        category: 'All',
        subcategory: 'All',
      ),
    );



    final downloadedFileName = useState<String?>(null);
    final downloadedFilePath = useState<String?>(null);

    final isLoadingOlder = useState(false);
    final hasReachedEnd = useState(false);

    Future<void> openFilterScreen() async {
      final result = await context.push<HistoryFilterState>(
        '/history-filter',
        extra: filterState.value,
      );
      if (result != null) {
        filterState.value = result;
      }
    }

    // Shortcuts
    final selectedCategory = filterState.value.category;
    final selectedSubcategory = filterState.value.subcategory;
    final dateRange = filterState.value.dateRange;
    final selectedBankId = filterState.value.bankId;
    final selectedPaymentMethodId = filterState.value.paymentMethodId;
    final activeFilterCount = [
      filterState.value.transactionType != null,
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
      dateRange.start.year,
      dateRange.start.month,
      dateRange.start.day,
    );
    final endOfRange = DateTime(
      dateRange.end.year,
      dateRange.end.month,
      dateRange.end.day,
      23,
      59,
      59,
      999,
    );
    final adjustedRange = DateTimeRange(start: startOfRange, end: endOfRange);

    final transactionsAsync = ref.watch(
      transactionsInDateRangeProvider(adjustedRange),
    );

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: AppColors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.menu_rounded, size: AppSizes.r(28)),
          onPressed: () => ref
              .read(mainScaffoldKeyProvider)
              .currentState
              ?.openDrawer(),
        ),
        title: Text(
          'History',
          style: AppTextStyles.heading(context),
        ),
        centerTitle: true,
        actions: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: Icon(
                  Icons.tune_rounded,
                  size: AppSizes.r(24),
                  color: filterState.value.hasActiveFilters
                      ? AppColors.primary
                      : null,
                ),
                tooltip: 'Filters',
                onPressed: openFilterScreen,
              ),
              if (activeFilterCount > 0)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    width: AppSizes.r(16),
                    height: AppSizes.r(16),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$activeFilterCount',
                        style: AppTextStyles.small(
                          context,
                          color: AppColors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 8,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(AppSizes.w12),
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
                            dateRange.start.subtract(
                              const Duration(seconds: 1),
                            ),
                          ) &&
                          t.date.isBefore(
                            dateRange.end.add(const Duration(days: 1)),
                          );
                    }).toList();

                    // 2. Filter by Category, Subcategory, Bank, PaymentMethod & Calculate Totals
                    double totalSpent = 0;
                    double totalIncome = 0;
                    final List<TransactionModel> finalFiltered = [];

                    for (var t in dateFiltered) {
                      // Transaction Type filter
                      if (filterState.value.transactionType != null &&
                          t.type != filterState.value.transactionType) {
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
                          final categoryMatch = t.category == selectedCategory;
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

                    if (finalFiltered.isEmpty) {
                      return _buildEmptyState(
                        context,
                        filterState.value.hasActiveFilters
                            ? 'No transactions match your filters'
                            : 'No transactions',
                        filterState.value.hasActiveFilters
                            ? openFilterScreen
                            : null,
                      );
                    }

                    return ListView(
                      children: [
                        // Dynamic Summary Card
                        HistorySummaryCard(
                          selectedCategory: selectedCategory,
                          selectedSubcategory: selectedSubcategory,
                          totalSpent: totalSpent,
                          totalIncome: totalIncome,
                          incomeCount: finalFiltered
                              .where((t) => t.type == TransactionType.credit)
                              .length,
                          expenseCount: finalFiltered
                              .where((t) => t.type != TransactionType.credit)
                              .length,
                        ),
                        SizedBox(height: AppSizes.h12),

                        // Banner Ad
                        const BannerAdWidget(),
                        SizedBox(height: AppSizes.h12),

                        if (activeFilterCount > 0)
                          Padding(
                            padding: EdgeInsets.only(bottom: AppSizes.h12),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: AppSizes.w12,
                                vertical: AppSizes.h8,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(
                                  AppSizes.r8,
                                ),
                                border: Border.all(
                                  color: AppColors.primary.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                [
                                  '${DateFormat('MMM d, yy').format(dateRange.start)} - ${DateFormat('MMM d, yy').format(dateRange.end)}',
                                  if (filterState.value.transactionType != null)
                                    filterState.value.transactionType ==
                                            TransactionType.credit
                                        ? 'Income'
                                        : 'Expense',
                                  if (selectedCategory != 'All')
                                    selectedCategory,
                                  if (selectedSubcategory != 'All')
                                    subcategoryLabel,
                                  if (selectedBankId != null)
                                    getDisplayBankName(selectedBankId) ?? '',
                                  if (selectedPaymentMethodId != null)
                                    getDisplayPaymentName(
                                          selectedPaymentMethodId,
                                        ) ??
                                        '',
                                ].where((s) => s.isNotEmpty).join(' ➔ '),
                                style: AppTextStyles.small(
                                  context,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),

                        // Downloaded File Name Banner
                        if (downloadedFileName.value != null) ...[
                          Container(
                            padding: EdgeInsets.all(AppSizes.r12),
                            margin: EdgeInsets.only(bottom: AppSizes.h12),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.08),
                              borderRadius: AppSizes.cardBorderRadius,
                              border: Border.all(
                                color: Colors.green.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: Colors.green,
                                ),
                                SizedBox(width: AppSizes.w12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'File Downloaded Successfully',
                                        style: AppTextStyles.body(
                                          context,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        downloadedFileName.value!,
                                        style: AppTextStyles.small(
                                          context,
                                          color: AppColors.getTextMuted(
                                            context,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.share_rounded,
                                    color: Colors.green,
                                  ),
                                  onPressed: () {
                                    if (downloadedFilePath.value != null) {
                                      Share.shareXFiles([
                                        XFile(downloadedFilePath.value!),
                                      ], text: 'Exported Transactions');
                                    }
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close_rounded),
                                  onPressed: () {
                                    downloadedFileName.value = null;
                                    downloadedFilePath.value = null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Header with Toggle
                        Padding(
                          padding: EdgeInsets.only(bottom: AppSizes.h12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'All Transactions',
                                style: AppTextStyles.body(
                                  context,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton.filledTonal(
                                    onPressed: () {
                                      context.push('/history-analysis', extra: finalFiltered);
                                    },
                                    icon: Icon(Icons.pie_chart_rounded, size: AppSizes.r(20)),
                                    tooltip: 'Analysis',
                                    style: IconButton.styleFrom(
                                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                      foregroundColor: AppColors.primary,
                                    ),
                                  ),
                                  SizedBox(width: AppSizes.w8),
                                  IconButton.filledTonal(
                                    onPressed: () {
                                      final activeFilters = <String>[];
                                      if (filterState.value.transactionType != null) {
                                        activeFilters.add(
                                          'Type: ${filterState.value.transactionType == TransactionType.credit ? 'Income' : 'Expense'}',
                                        );
                                      }
                                      if (selectedBankId != null) {
                                        activeFilters.add(
                                          'Bank: ${getDisplayBankName(selectedBankId)}',
                                        );
                                      }
                                      if (selectedPaymentMethodId != null) {
                                        activeFilters.add(
                                          'Method: ${getDisplayPaymentName(selectedPaymentMethodId)}',
                                        );
                                      }
                                      if (filterState.value.category != 'All') {
                                        activeFilters.add(
                                          'Category: ${filterState.value.category}',
                                        );
                                      }
                                      if (filterState.value.subcategory != 'All') {
                                        activeFilters.add(
                                          'Subcategory: $subcategoryLabel',
                                        );
                                      }
                                      final filterStr = activeFilters.isEmpty
                                          ? 'All'
                                          : activeFilters.join(', ');

                                      AnalyticsService.logEvent('download_history_report');
                                      context.push(
                                        '/download-report',
                                        extra: DownloadReportScreenArgs(
                                          transactions: finalFiltered,
                                          filterString: filterStr,
                                        ),
                                      );
                                    },
                                    icon: Icon(Icons.download_rounded, size: AppSizes.r(20)),
                                    tooltip: 'Download Report',
                                    style: IconButton.styleFrom(
                                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                      foregroundColor: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        ..._groupAndBuildTransactions(context, finalFiltered),
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

  List<Widget> _groupAndBuildTransactions(
    BuildContext context,
    List<TransactionModel> transactions,
  ) {
    final sortedTransactions = List<TransactionModel>.from(transactions)
      ..sort((a, b) => b.date.compareTo(a.date));

    final Map<String, List<TransactionModel>> grouped = {};
    for (var t in sortedTransactions) {
      final dateKey = DateFormat('MMMM dd, yyyy').format(t.date);
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(t);
    }

    List<Widget> widgets = [];
    for (var dateKey in grouped.keys) {
      widgets.add(
        Padding(
          padding: EdgeInsets.symmetric(vertical: AppSizes.h12),
          child: Text(
            dateKey,
            style: AppTextStyles.body(context, color: AppColors.primary),
          ),
        ),
      );
      widgets.addAll(
        grouped[dateKey]!.map((t) => _buildTransactionCard(context, t)),
      );
    }
    return widgets;
  }

  Widget _buildEmptyState(
    BuildContext context,
    String message, [
    VoidCallback? onAdjustFilters,
  ]) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: AppSizes.r(64),
            color: Theme.of(
              context,
            ).colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
          SizedBox(height: AppSizes.h16),
          Text(
            message,
            style: AppTextStyles.body(
              context,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          if (onAdjustFilters != null) ...[
            SizedBox(height: AppSizes.h12),
            TextButton.icon(
              onPressed: onAdjustFilters,
              icon: Icon(Icons.tune_rounded, size: AppSizes.r16),
              label: const Text('Adjust Filters'),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTransactionCard(BuildContext context, TransactionModel t) {
    return ExpandableTransactionCard(
      transaction: t,
      margin: EdgeInsets.symmetric(vertical: AppSizes.h4),
      onTap: () {
        context.push('/transaction-detail', extra: t);
      },
    );
  }
}

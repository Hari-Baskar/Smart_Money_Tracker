import 'package:smart_money_tracker/core/constants/app_sizes.dart';
import 'package:smart_money_tracker/core/constants/app_colors.dart';
import 'package:smart_money_tracker/core/theme/app_text_styles.dart';
import 'package:smart_money_tracker/core/models/transaction_model.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/providers/transaction_provider.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/providers/subcategory_provider.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/screens/transaction_detail_screen.dart';
import 'package:smart_money_tracker/features/main/presentation/widgets/app_drawer.dart';
import 'package:smart_money_tracker/core/common/widgets/banner_ad_widget.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class HistoryScreen extends HookConsumerWidget {
  const HistoryScreen({super.key});

  static const List<String> _categoriesList = [
    'All',
    'Food',
    'Travel',
    'Shopping',
    'Bills',
    'Groceries',
    'Entertainment',
    'Health',
    'Investment',
    'Other',
    'Unknown',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = useState('All');
    final selectedSubcategory = useState('All');
    final showAnalysis = useState(false);
    final subcategoriesAsync = ref.watch(subcategoriesProvider);

    useEffect(() {
      selectedSubcategory.value = 'All';
      return null;
    }, [selectedCategory.value]);

    final dateRange = useState(
      DateTimeRange(
        start: DateTime.now().subtract(const Duration(days: 30)),
        end: DateTime.now(),
      ),
    );

    Future<void> selectDateRange() async {
      final DateTimeRange? picked = await showDateRangePicker(
        context: context,
        initialDateRange: dateRange.value,
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
        builder: (context, child) {
          final isDark = AppColors.isDark(context);
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: isDark
                  ? const ColorScheme.dark(
                      primary: Color(0xFF078644),
                      onPrimary: Colors.white,
                      primaryContainer: Color(0xFF004D25),
                      onPrimaryContainer: Colors.white,
                      surface: AppColors.surfaceDark,
                      onSurface: Colors.white,
                      secondary: Color(0xFF078644),
                      onSecondary: Colors.white,
                    )
                  : const ColorScheme.light(
                      primary: AppColors.primary,
                      onPrimary: Colors.white,
                      onSurface: AppColors.textLight,
                    ),
            ),
            child: child!,
          );
        },
      );
      if (picked != null && picked != dateRange.value) {
        dateRange.value = picked;
      }
    }

    final transactionsAsync = ref.watch(transactionsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      drawer: const AppDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(
              Icons.menu_rounded,
              color: AppColors.primary,
              size: AppSizes.r(28),
            ),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text('History', style: AppTextStyles.headline(context)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Date Range Display
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSizes.w(20), vertical: AppSizes.h8),
            child: GestureDetector(
              onTap: selectDateRange,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: AppSizes.w16, vertical: AppSizes.h12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: AppSizes.cardBorderRadius,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: AppSizes.r16,
                      color: AppColors.primary,
                    ),
                    SizedBox(width: AppSizes.w12),
                    Text(
                      '${DateFormat('MMM dd').format(dateRange.value.start)} - ${DateFormat('MMM dd').format(dateRange.value.end)}',
                      style: AppTextStyles.small(
                        context,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.edit_rounded,
                      size: AppSizes.r(14),
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Dropdown Filters
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSizes.w(20), vertical: AppSizes.h12),
            child: Row(
              children: [
                // Category Dropdown
                Expanded(
                  child: _buildDropdown(
                    context: context,
                    value: selectedCategory.value,
                    items: _getSortedCategories(),
                    onChanged: (val) {
                      if (val != null) selectedCategory.value = val;
                    },
                    hint: 'Category',
                  ),
                ),
                // Subcategory Dropdown
                SizedBox(width: AppSizes.w12),
                Expanded(
                  child: selectedCategory.value == 'All'
                      ? _buildDropdown(
                          context: context,
                          value: 'All',
                          items: ['All'],
                          onChanged: null,
                          hint: 'Subcategory',
                        )
                      : subcategoriesAsync.when(
                          data: (allSubcategories) {
                            final filtered = allSubcategories
                                .where(
                                  (s) =>
                                      s.parentCategory ==
                                      selectedCategory.value,
                                )
                                .map((s) => s.name)
                                .toSet()
                                .toList();

                            final sortedSub = filtered..sort();
                            final displaySub = ['All', ...sortedSub];

                            return _buildDropdown(
                              context: context,
                              value:
                                  displaySub.contains(selectedSubcategory.value)
                                  ? selectedSubcategory.value
                                  : 'All',
                              items: displaySub,
                              onChanged: (val) {
                                if (val != null)
                                  selectedSubcategory.value = val;
                              },
                              hint: 'Subcategory',
                            );
                          },
                          loading: () => Container(
                            height: AppSizes.h(48),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: AppSizes.cardBorderRadius,
                              border: Border.all(
                                color: Theme.of(
                                  context,
                                ).colorScheme.surfaceVariant,
                              ),
                            ),
                          ),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                ),
              ],
            ),
          ),

          Expanded(
            child: transactionsAsync.when(
              data: (transactions) {
                // 1. Filter by Date Range
                final dateFiltered = transactions.where((t) {
                  return t.date.isAfter(
                        dateRange.value.start.subtract(
                          const Duration(seconds: 1),
                        ),
                      ) &&
                      t.date.isBefore(
                        dateRange.value.end.add(const Duration(days: 1)),
                      );
                }).toList();

                // 2. Filter by Category & Subcategory & Calculate Totals
                double totalSpent = 0;
                double totalIncome = 0;
                final List<TransactionModel> finalFiltered = [];

                for (var t in dateFiltered) {
                  final categoryMatch =
                      selectedCategory.value == 'All' ||
                      t.category == selectedCategory.value;
                  final subcategoryMatch =
                      selectedSubcategory.value == 'All' ||
                      t.subcategory == selectedSubcategory.value;

                  if (categoryMatch && subcategoryMatch) {
                    finalFiltered.add(t);
                    if (t.type == TransactionType.credit) {
                      totalIncome += t.amount;
                    } else {
                      totalSpent += t.amount;
                    }
                  }
                }

                if (finalFiltered.isEmpty) {
                  return _buildEmptyState(
                    context,
                    'No transactions found for this selection',
                  );
                }

                return ListView(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSizes.w(20),
                    vertical: AppSizes.h(10),
                  ),
                  children: [
                    // Dynamic Summary Card
                    _buildSummaryCard(
                      context,
                      selectedCategory.value,
                      selectedSubcategory.value,
                      totalSpent,
                      totalIncome,
                    ),
                    SizedBox(height: AppSizes.h24),

                    // Banner Ad
                    const BannerAdWidget(),
                    SizedBox(height: AppSizes.h12),

                    // Header with Toggle
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          showAnalysis.value
                              ? 'Expense Analysis'
                              : selectedCategory.value == 'All'
                              ? 'All Transactions'
                              : selectedSubcategory.value == 'All'
                              ? '${selectedCategory.value} Transactions'
                              : '${selectedCategory.value} > ${selectedSubcategory.value}',
                          style: AppTextStyles.body(
                            context,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () =>
                              showAnalysis.value = !showAnalysis.value,
                          icon: Icon(
                            showAnalysis.value
                                ? Icons.history_rounded
                                : Icons.analytics_rounded,
                            size: AppSizes.r(18),
                            color: AppColors.primary,
                          ),
                          label: Text(
                            showAnalysis.value
                                ? 'Show History'
                                : 'View Analysis',
                            style: AppTextStyles.small(
                              context,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSizes.h12),
                    if (showAnalysis.value)
                      _buildAnalysisView(context, finalFiltered)
                    else
                      ..._groupAndBuildTransactions(context, finalFiltered),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    String selectedCategory,
    String selectedSubcategory,
    double totalSpent,
    double totalIncome,
  ) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: AppSizes.h12),
      padding: EdgeInsets.all(AppSizes.r24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: AppSizes.cardBorderRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: AppColors.primary.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selected Spending',
                    style: AppTextStyles.small(
                      context,
                      color: AppColors.getTextMuted(context),
                    ),
                  ),
                  SizedBox(height: AppSizes.h4),
                  Text(
                    totalSpent >= 1000
                        ? '₹${(totalSpent / 1000).toStringAsFixed(1)}K'
                        : '₹${NumberFormat('#,###').format(totalSpent)}',
                    style: AppTextStyles.display(
                      context,
                      color: AppColors.error,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Selected Income',
                    style: AppTextStyles.small(
                      context,
                      color: AppColors.getTextMuted(context),
                    ),
                  ),
                  SizedBox(height: AppSizes.h4),
                  Text(
                    totalIncome >= 1000
                        ? '₹${(totalIncome / 1000).toStringAsFixed(1)}K'
                        : '₹${NumberFormat('#,###').format(totalIncome)}',
                    style: AppTextStyles.display(
                      context,
                      color: AppColors.success,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: AppSizes.h16),
          Divider(
            color: Theme.of(
              context,
            ).colorScheme.outlineVariant.withOpacity(0.5),
            height: 1,
          ),
          SizedBox(height: AppSizes.h16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.trending_up,
                    color: AppColors.error.withOpacity(0.8),
                    size: AppSizes.r16,
                  ),
                  SizedBox(width: AppSizes.w4),
                  Text(
                    'Spent in period',
                    style: AppTextStyles.small(
                      context,
                      color: AppColors.getTextMuted(context),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Icon(
                    Icons.trending_down,
                    color: AppColors.success.withOpacity(0.8),
                    size: AppSizes.r16,
                  ),
                  SizedBox(width: AppSizes.w4),
                  Text(
                    'Income in period',
                    style: AppTextStyles.small(
                      context,
                      color: AppColors.getTextMuted(context),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
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
          padding: EdgeInsets.symmetric(vertical: AppSizes.h12, horizontal: AppSizes.w8),
          child: Text(
            dateKey,
            style: AppTextStyles.small(context, color: AppColors.primary),
          ),
        ),
      );
      widgets.addAll(
        grouped[dateKey]!.map((t) => _buildTransactionCard(context, t)),
      );
    }
    return widgets;
  }

  Widget _buildAnalysisView(
    BuildContext context,
    List<TransactionModel> transactions,
  ) {
    // 1. Group by category
    final Map<String, List<TransactionModel>> categoryGroups = {};
    for (var t in transactions) {
      categoryGroups.putIfAbsent(t.category, () => []).add(t);
    }

    // 2. Sort categories by total amount descending
    final sortedCategories = categoryGroups.keys.toList()
      ..sort((a, b) {
        final totalA = categoryGroups[a]!.fold(0.0, (sum, t) => sum + t.amount);
        final totalB = categoryGroups[b]!.fold(0.0, (sum, t) => sum + t.amount);
        return totalB.compareTo(totalA);
      });

    final totalVolume = transactions.fold(0.0, (sum, t) => sum + t.amount);

    final List<Color> chartColors = [
      AppColors.primary,
      const Color(0xFF6366F1),
      const Color(0xFFEC4899),
      const Color(0xFFF59E0B),
      const Color(0xFF10B981),
      const Color(0xFF3B82F6),
      const Color(0xFF8B5CF6),
      const Color(0xFFF43F5E),
    ];

    return Column(
      children: [
        // Pie Chart Section
        Container(
          height: AppSizes.h(250),
          margin: EdgeInsets.only(bottom: AppSizes.h24),
          padding: EdgeInsets.all(AppSizes.r16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: AppSizes.cardBorderRadius,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: AppSizes.r(50),
              sections: sortedCategories.asMap().entries.map((entry) {
                final idx = entry.key;
                final cat = entry.value;
                final total = categoryGroups[cat]!.fold(
                  0.0,
                  (sum, t) => sum + t.amount,
                );
                final percentage = (total / totalVolume) * 100;

                return PieChartSectionData(
                  color: chartColors[idx % chartColors.length],
                  value: total,
                  title: percentage > 5
                      ? '${percentage.toStringAsFixed(0)}%'
                      : '',
                  radius: AppSizes.r(60),
                  titleStyle: AppTextStyles.small(
                    context,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        ...sortedCategories.map((cat) {
          final catTransactions = categoryGroups[cat]!;
          final catTotal = catTransactions.fold(
            0.0,
            (sum, t) => sum + t.amount,
          );

          // 3. Group by subcategory within category
          final Map<String, double> subGroups = {};
          for (var t in catTransactions) {
            subGroups[t.subcategory] =
                (subGroups[t.subcategory] ?? 0.0) + t.amount;
          }

          final sortedSubs = subGroups.keys.toList()
            ..sort((a, b) => subGroups[b]!.compareTo(subGroups[a]!));

          return Container(
            margin: EdgeInsets.only(bottom: 12.h),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: AppSizes.cardBorderRadius,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.symmetric(
                  horizontal: AppSizes.w16,
                  vertical: AppSizes.h4,
                ),
                leading: Container(
                  width: AppSizes.r40,
                  height: AppSizes.r40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: AppSizes.cardBorderRadius,
                  ),
                  child: Icon(
                    _getCategoryIcon(cat),
                    color: AppColors.primary,
                    size: AppSizes.r20,
                  ),
                ),
                title: Text(
                  cat,
                  style: AppTextStyles.body(
                    context,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                trailing: Text(
                  '₹${catTotal.toStringAsFixed(0)}',
                  style: AppTextStyles.body(
                    context,
                    color:
                        catTransactions.any(
                          (t) => t.type == TransactionType.credit,
                        )
                        ? Colors.green
                        : AppColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                children: [
                  Padding(
                    padding: EdgeInsets.only(
                      left: AppSizes.w16,
                      right: AppSizes.w16,
                      bottom: AppSizes.h16,
                    ),
                    child: Column(
                      children: [
                        Divider(
                          color: Theme.of(context).colorScheme.surfaceVariant,
                        ),
                        SizedBox(height: AppSizes.h8),
                        ...sortedSubs.map((sub) {
                          final subTotal = subGroups[sub]!;
                          final percentage = (subTotal / catTotal) * 100;
                          return Padding(
                            padding: EdgeInsets.symmetric(vertical: 6.h),
                            child: Row(
                              children: [
                                Container(
                                  width: AppSizes.r8,
                                  height: AppSizes.r8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                SizedBox(width: AppSizes.w12),
                                Expanded(
                                  child: Text(
                                    sub,
                                    style: AppTextStyles.small(context),
                                  ),
                                ),
                                Text(
                                  '₹${subTotal.toStringAsFixed(0)}',
                                  style: AppTextStyles.small(
                                    context,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(width: AppSizes.w12),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: AppSizes.w8,
                                    vertical: AppSizes.h(2),
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.surfaceVariant,
                                    borderRadius: AppSizes.cardBorderRadius,
                                  ),
                                  child: Text(
                                    '${percentage.toStringAsFixed(0)}%',
                                    style: AppTextStyles.small(
                                      context,

                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, String message) {
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
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(BuildContext context, TransactionModel t) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TransactionDetailScreen(transaction: t),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: AppSizes.h12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: AppSizes.cardBorderRadius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: EdgeInsets.all(AppSizes.r12),
          leading: Container(
            width: AppSizes.r(48),
            height: AppSizes.r(48),
            decoration: BoxDecoration(
              color: t.type == TransactionType.credit
                  ? Colors.green.withOpacity(0.1)
                  : Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: AppSizes.cardBorderRadius,
            ),
            child: Icon(
              t.type == TransactionType.credit
                  ? Icons.account_balance_wallet_rounded
                  : _getCategoryIcon(t.category),
              color: t.type == TransactionType.credit
                  ? Colors.green
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              size: AppSizes.r24,
            ),
          ),
          title: Text(
            '${t.subcategory} (${t.category})',
            style: AppTextStyles.body(context, fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            "${t.type == TransactionType.credit ? 'From' : 'Payee'}: ${t.merchant} • ${DateFormat('hh:mm a').format(t.date)}",
            style: AppTextStyles.small(context),
          ),
          trailing: Text(
            '${t.type == TransactionType.credit ? '+' : '-'}₹${t.amount.toStringAsFixed(0)}',
            style: AppTextStyles.headline(
              context,
              color: t.type == TransactionType.credit
                  ? Colors.green
                  : AppColors.error,
            ),
          ),
        ),
      ),
    );
  }

  List<String> _getSortedCategories() {
    final others = _categoriesList.where((c) => c != 'All').toList()..sort();
    return ['All', ...others];
  }

  Widget _buildDropdown({
    required BuildContext context,
    required String value,
    required List<String> items,
    required void Function(String?)? onChanged,
    required String hint,
  }) {
    final isDisabled = onChanged == null;
    return Opacity(
      opacity: isDisabled ? 0.5 : 1.0,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: AppSizes.w16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: AppSizes.cardBorderRadius,
          border: Border.all(
            color: Theme.of(context).colorScheme.surfaceVariant,
          ),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            disabledHint: Text(value, style: AppTextStyles.small(context)),
            dropdownColor: Theme.of(context).colorScheme.surface,
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.primary,
              size: AppSizes.r20,
            ),
            items: items.map((String item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(
                  item,
                  style: AppTextStyles.small(context),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant_rounded;
      case 'travel':
        return Icons.directions_car_rounded;
      case 'shopping':
        return Icons.shopping_bag_rounded;
      case 'bills':
        return Icons.receipt_long_rounded;
      case 'groceries':
        return Icons.local_grocery_store_rounded;
      case 'entertainment':
        return Icons.movie_rounded;
      case 'health':
        return Icons.medical_services_rounded;
      default:
        return Icons.category_rounded;
    }
  }
}

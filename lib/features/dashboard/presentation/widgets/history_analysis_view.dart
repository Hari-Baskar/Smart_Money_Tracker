import 'package:flutter/material.dart';
import 'package:smart_money_tracker/core/constants/app_colors.dart';
import 'package:smart_money_tracker/core/constants/app_sizes.dart';
import 'package:smart_money_tracker/core/models/transaction_model.dart';
import 'package:smart_money_tracker/core/theme/app_text_styles.dart';
import 'package:intl/intl.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_money_tracker/core/constants/app_routes.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/providers/subcategory_provider.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/screens/analysis/subcategory_breakdown_screen.dart';

class HistoryAnalysisView extends HookConsumerWidget {
  final List<TransactionModel> transactions;
  final DateTimeRange dateRange;

  const HistoryAnalysisView({
    super.key,
    required this.transactions,
    required this.dateRange,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = AppColors.isDark(context);
    final numDays = dateRange.end.difference(dateRange.start).inDays + 1;

    // Process transactions
    final expenses = transactions
        .where((t) => t.type == TransactionType.debit)
        .toList();
    final incomes = transactions
        .where((t) => t.type == TransactionType.credit)
        .toList();

    final totalSpent = expenses.fold(0.0, (sum, t) => sum + t.amount);
    final totalIncome = incomes.fold(0.0, (sum, t) => sum + t.amount);

    final dailyAvgSpent = numDays > 0 ? totalSpent / numDays : 0.0;
    final dailyAvgIncome = numDays > 0 ? totalIncome / numDays : 0.0;

    // Categories
    final categoriesAsync = ref.watch(categoriesProvider);
    final subcategoriesAsync = ref.watch(subcategoriesProvider);
    final categories = categoriesAsync.value ?? const [];
    final subcategories = subcategoriesAsync.value ?? const [];

    String resolveCategory(String id) {
      final match = categories.where((c) => c.id == id).firstOrNull;
      return match?.name ?? id;
    }

    String resolveSubcategory(String id) {
      final match = subcategories.where((s) => s.id == id).firstOrNull;
      return match?.name ?? id;
    }

    bool isSingleCategory(List<TransactionModel> txns) {
      if (txns.isEmpty) return false;
      final firstCat = txns.first.splits.isEmpty
          ? txns.first.category
          : txns.first.splits.first.category;
      return txns.every((t) {
        if (t.splits.isEmpty) return t.category == firstCat;
        return t.splits.every((s) => s.category == firstCat);
      });
    }

    bool isSingleSubcategory(List<TransactionModel> txns) {
      if (txns.isEmpty) return false;
      final firstSub = txns.first.splits.isEmpty
          ? txns.first.subcategory
          : txns.first.splits.first.subcategory;
      return txns.every((t) {
        if (t.splits.isEmpty) return t.subcategory == firstSub;
        return t.splits.every((s) => s.subcategory == firstSub);
      });
    }

    // Category breakdowns
    List<_CategoryStat> _getCategoryStats(
      List<TransactionModel> txns,
      double total,
    ) {
      if (total == 0) return [];
      final Map<String, double> map = {};
      for (var t in txns) {
        if (t.splits.isEmpty) {
          map[t.category] = (map[t.category] ?? 0.0) + t.amount;
        } else {
          double splitTotal = 0;
          for (var split in t.splits) {
            splitTotal += split.amount;
            map[split.category] = (map[split.category] ?? 0.0) + split.amount;
          }
          final remainder = t.amount - splitTotal;
          if (remainder > 0.01) {
            map[t.category] = (map[t.category] ?? 0.0) + remainder;
          }
        }
      }

      final list = map.entries
          .map(
            (e) => _CategoryStat(
              id: e.key,
              name: resolveCategory(e.key),
              amount: e.value,
              percentage: e.value / total,
            ),
          )
          .toList();

      list.sort((a, b) => b.amount.compareTo(a.amount));
      return list;
    }

    List<_CategoryStat> _getSubcategoryStats(
      List<TransactionModel> txns,
      double total,
    ) {
      if (total == 0) return [];
      final Map<String, double> map = {};
      for (var t in txns) {
        if (t.splits.isEmpty) {
          final sub = (t.subcategory?.isNotEmpty == true)
              ? t.subcategory!
              : 'Other';
          map[sub] = (map[sub] ?? 0.0) + t.amount;
        } else {
          double splitTotal = 0;
          for (var split in t.splits) {
            splitTotal += split.amount;
            final sub = (split.subcategory?.isNotEmpty == true)
                ? split.subcategory!
                : 'Other';
            map[sub] = (map[sub] ?? 0.0) + split.amount;
          }
          final remainder = t.amount - splitTotal;
          if (remainder > 0.01) {
            final sub = (t.subcategory?.isNotEmpty == true)
                ? t.subcategory!
                : 'Other';
            map[sub] = (map[sub] ?? 0.0) + remainder;
          }
        }
      }

      final list = map.entries
          .map(
            (e) => _CategoryStat(
              id: e.key,
              name: e.key == 'Other' ? 'Other' : resolveSubcategory(e.key),
              amount: e.value,
              percentage: e.value / total,
            ),
          )
          .toList();

      list.sort((a, b) => b.amount.compareTo(a.amount));
      return list;
    }

    final incomeIsSingleCat = isSingleCategory(incomes);
    final incomeIsSingleSubcat = isSingleSubcategory(incomes);
    final expenseIsSingleCat = isSingleCategory(expenses);
    final expenseIsSingleSubcat = isSingleSubcategory(expenses);

    final incomeParentCatId = incomes.isNotEmpty
        ? (incomes.first.splits.isEmpty
              ? incomes.first.category
              : incomes.first.splits.first.category)
        : '';

    final expenseParentCatId = expenses.isNotEmpty
        ? (expenses.first.splits.isEmpty
              ? expenses.first.category
              : expenses.first.splits.first.category)
        : '';

    List<_CategoryStat> incomeStats = [];
    if (!incomeIsSingleSubcat) {
      if (incomeIsSingleCat) {
        incomeStats = _getSubcategoryStats(incomes, totalIncome);
      } else {
        incomeStats = _getCategoryStats(incomes, totalIncome);
      }
    }

    List<_CategoryStat> expenseStats = [];
    if (!expenseIsSingleSubcat) {
      if (expenseIsSingleCat) {
        expenseStats = _getSubcategoryStats(expenses, totalSpent);
      } else {
        expenseStats = _getCategoryStats(expenses, totalSpent);
      }
    }

    // Date formatter
    final dateFormat = DateFormat('d MMM');
    final yearFormat = DateFormat('yyyy');
    String dateRangeStr =
        '${dateFormat.format(dateRange.start)} - ${dateFormat.format(dateRange.end)} ${yearFormat.format(dateRange.end)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              dateRangeStr,
              style: AppTextStyles.body(
                context,
              ).copyWith(fontWeight: FontWeight.w600, fontSize: 15),
            ),
            SizedBox(width: AppSizes.w8),
            Text(
              '• $numDays days',
              style: AppTextStyles.body(
                context,
                color: AppColors.getTextMuted(context),
              ),
            ),
          ],
        ),
        SizedBox(height: AppSizes.h12),

        // Summary Cards
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => context.push(AppRoutes.income, extra: dateRange),
                child: _buildSummaryCard(
                  context,
                  title: 'Total Credit',
                  amount: totalIncome,
                  dailyAvg: dailyAvgIncome,
                  iconData: Icons.arrow_upward_rounded,
                  iconColor: AppColors.white,
                  iconBgColor: AppColors.success,
                ),
              ),
            ),
            SizedBox(width: AppSizes.w8),
            Expanded(
              child: GestureDetector(
                onTap: () => context.push(AppRoutes.expense, extra: dateRange),
                child: _buildSummaryCard(
                  context,
                  title: 'Total Debit',
                  amount: totalSpent,
                  dailyAvg: dailyAvgSpent,
                  iconData: Icons.arrow_downward_rounded,
                  iconColor: AppColors.white,
                  iconBgColor: AppColors.error,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: AppSizes.h24),

        // Income by Category
        if (incomeStats.isNotEmpty) ...[
          Text(
            incomeIsSingleCat ? 'Income by Subcategory' : 'Income by Category',
            style: AppTextStyles.subHeading(
              context,
            ).copyWith(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: AppSizes.h12),
          Container(
            padding: EdgeInsets.all(AppSizes.w16),
            decoration: BoxDecoration(
              color: AppColors.getSurfaceContainerLowest(context),
              borderRadius: AppSizes.cardBorderRadius,
              border: isDark
                  ? null
                  : Border.all(
                      color: AppColors.black.withOpacity(0.08),
                      width: 1,
                    ),
              boxShadow: isDark
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
              children: incomeStats
                  .asMap()
                  .entries
                  .map(
                    (e) => _buildCategoryRow(
                      context,
                      e.value,
                      incomes,
                      resolveSubcategory,
                      isLast: e.key == incomeStats.length - 1,
                      isSubcategory: incomeIsSingleCat,
                      parentCategoryId: incomeParentCatId,
                    ),
                  )
                  .toList(),
            ),
          ),
          SizedBox(height: AppSizes.h24),
        ],

        // Spending by Category
        if (expenseStats.isNotEmpty) ...[
          Text(
            expenseIsSingleCat
                ? 'Spending by Subcategory'
                : 'Spending by Category',
            style: AppTextStyles.subHeading(
              context,
            ).copyWith(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: AppSizes.h12),
          Container(
            padding: EdgeInsets.all(AppSizes.w16),
            decoration: BoxDecoration(
              color: AppColors.getSurfaceContainerLowest(context),
              borderRadius: AppSizes.cardBorderRadius,
              border: isDark
                  ? null
                  : Border.all(
                      color: AppColors.black.withOpacity(0.08),
                      width: 1,
                    ),
              boxShadow: isDark
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
              children: expenseStats
                  .asMap()
                  .entries
                  .map(
                    (e) => _buildCategoryRow(
                      context,
                      e.value,
                      expenses,
                      resolveSubcategory,
                      isLast: e.key == expenseStats.length - 1,
                      isSubcategory: expenseIsSingleCat,
                      parentCategoryId: expenseParentCatId,
                    ),
                  )
                  .toList(),
            ),
          ),
          SizedBox(height: AppSizes.h24),
        ],

        // Insights
        if (expenses.isNotEmpty || incomes.isNotEmpty) ...[
          Text(
            'Insights',
            style: AppTextStyles.subHeading(
              context,
            ).copyWith(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: AppSizes.h12),
          _buildInsights(
            context,
            expenses,
            incomes,
            expenseStats,
            totalSpent,
            numDays,
            dateRange,
            resolveSubcategory,
            resolveCategory,
            isSubcategory: expenseIsSingleCat,
          ),
        ],
      ],
    );
  }

  Widget _buildSummaryCard(
    BuildContext context, {
    required String title,
    required double amount,
    required double dailyAvg,
    required IconData iconData,
    required Color iconColor,
    required Color iconBgColor,
  }) {
    final isDark = AppColors.isDark(context);
    return Container(
      padding: EdgeInsets.all(AppSizes.w12),
      decoration: BoxDecoration(
        color: AppColors.getSurfaceContainerLowest(context),
        borderRadius: AppSizes.cardBorderRadius,
        border: isDark
            ? null
            : Border.all(color: AppColors.black.withOpacity(0.08), width: 1),
        boxShadow: isDark
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: AppSizes.r(40),
                height: AppSizes.r(40),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(iconData, color: iconColor, size: AppSizes.r24),
              ),
            ],
          ),
          SizedBox(height: AppSizes.h12),
          Text(
            title,
            style: AppTextStyles.body(
              context,
              color: AppColors.getText(context),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: AppSizes.h4),
          Text(
            '₹${AppColors.formatShortAmount(amount)}',
            style: AppTextStyles.subHeading(
              context,
              fontWeight: FontWeight.bold,
              color: AppColors.getText(context),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: AppSizes.h4),
          Text(
            dailyAvg == 0 ? '-' : '₹${dailyAvg.toStringAsFixed(0)}/day avg',
            style: AppTextStyles.body(
              context,
              color: iconBgColor == AppColors.success
                  ? AppColors.success
                  : AppColors.error,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryRow(
    BuildContext context,
    _CategoryStat stat,
    List<TransactionModel> allTxns,
    String Function(String) resolveSubcategory, {
    bool isLast = false,
    bool isSubcategory = false,
    String parentCategoryId = '',
  }) {
    final isDark = AppColors.isDark(context);
    final color = isSubcategory && parentCategoryId.isNotEmpty
        ? AppColors.getCategoryColor(parentCategoryId)
        : AppColors.getCategoryColor(stat.id);

    final categoryTxns = allTxns.where((t) {
      if (isSubcategory) {
        if (t.splits.isEmpty) {
          return (t.subcategory?.isNotEmpty == true
                  ? t.subcategory
                  : 'Other') ==
              stat.id;
        }
        return t.splits.any(
          (s) =>
              (s.subcategory?.isNotEmpty == true ? s.subcategory : 'Other') ==
              stat.id,
        );
      } else {
        if (t.splits.isEmpty) return t.category == stat.id;
        return t.splits.any((s) => s.category == stat.id);
      }
    }).toList();

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : AppSizes.h16),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (isSubcategory) {
            context.push(
              AppRoutes.budgetHistory,
              extra: {'transactions': categoryTxns, 'budgetName': stat.name},
            );
          } else {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => SubcategoryBreakdownScreen(
                  categoryName: stat.name,
                  groupTransactions: categoryTxns,
                  color: color,
                  resolveSubcategory: resolveSubcategory,
                  onShowTransactions: (ctx, subName, txns, c) {
                    ctx.push(
                      AppRoutes.budgetHistory,
                      extra: {
                        'transactions': txns,
                        'budgetName': subName == 'Other' ? stat.name : subName,
                      },
                    );
                  },
                ),
              ),
            );
          }
        },
        child: Row(
          children: [
            Container(
              width: AppSizes.r(36),
              height: AppSizes.r(36),
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: isSubcategory
                  ? Center(
                      child: Text(
                        stat.name.isNotEmpty ? stat.name[0].toUpperCase() : '?',
                        style: AppTextStyles.subHeading(
                          context,
                        ).copyWith(color: AppColors.white, fontSize: 18),
                      ),
                    )
                  : Icon(
                      AppColors.getCategoryIcon(stat.name),
                      color: AppColors.white,
                      size: AppSizes.r16,
                    ),
            ),
            SizedBox(width: AppSizes.w12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stat.name,
                    style: AppTextStyles.body(
                      context,
                    ).copyWith(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  SizedBox(height: AppSizes.h8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: stat.percentage,
                      backgroundColor: isDark
                          ? Colors.grey[800]
                          : Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      minHeight: 4,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: AppSizes.w16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${AppColors.formatShortAmount(stat.amount)}',
                  style: AppTextStyles.body(
                    context,
                  ).copyWith(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                SizedBox(height: AppSizes.h4),
              ],
            ),
            SizedBox(width: AppSizes.w12),
            SizedBox(
              width: AppSizes.w(32),
              child: Text(
                '${(stat.percentage * 100).toStringAsFixed(0)}%',
                style: AppTextStyles.small(
                  context,
                  color: AppColors.getTextMuted(context),
                ).copyWith(fontSize: 11, fontWeight: FontWeight.w600),
                textAlign: TextAlign.right,
              ),
            ),
            SizedBox(width: AppSizes.w8),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.getTextMuted(context).withOpacity(0.5),
              size: AppSizes.r16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsights(
    BuildContext context,
    List<TransactionModel> expenses,
    List<TransactionModel> incomes,
    List<_CategoryStat> expenseStats,
    double totalSpent,
    int numDays,
    DateTimeRange dateRange,
    String Function(String) resolveSubcategory,
    String Function(String) resolveCategory, {
    bool isSubcategory = false,
  }) {
    final isDark = AppColors.isDark(context);
    final List<Widget> cards = [];

    // 1. Most frequent subcategory
    if (expenses.isNotEmpty) {
      final Map<String, int> subcatCounts = {};
      for (var e in expenses) {
        if (e.subcategory != null) {
          subcatCounts[e.subcategory!] =
              (subcatCounts[e.subcategory!] ?? 0) + 1;
        } else {
          subcatCounts[e.category] = (subcatCounts[e.category] ?? 0) + 1;
        }
      }
      if (subcatCounts.isNotEmpty) {
        final sorted = subcatCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final top = sorted.first;
        if (top.value > 1) {
          final txns = expenses
              .where((e) => e.subcategory == top.key || e.category == top.key)
              .toList();
          cards.add(
            _buildInsightCard(
              context,
              onTap: () => context.push(
                AppRoutes.budgetHistory,
                extra: {
                  'transactions': txns,
                  'budgetName': resolveSubcategory(top.key),
                },
              ),
              iconData: Icons.trending_up_rounded, // or trending_up doesn't have an outline usually, we can keep trending_up
              iconColor: AppColors.getText(context),
              iconBgColor: Colors.transparent,
              useSolidBackground: false,
              title:
                  '${resolveSubcategory(top.key)} was your most frequent subcategory',
              subtitle: '${top.value} transactions',
              // subtitleColor: AppColors.success,
            ),
          );
        }
      }
    }

    // 2. Top 3 categories %
    if (expenseStats.length >= 4 && totalSpent > 0) {
      final top3 = expenseStats.take(3).toList();
      final top3Sum = top3.fold(0.0, (sum, s) => sum + s.amount);
      final pct = (top3Sum / totalSpent * 100).toStringAsFixed(0);
      final names = top3.map((e) => e.name).join(', ');
      final top3Ids = top3.map((e) => e.id).toSet();
      final txns = expenses.where((e) {
        if (isSubcategory) {
          final sub = e.subcategory?.isNotEmpty == true
              ? e.subcategory!
              : 'Other';
          return top3Ids.contains(sub);
        }
        return top3Ids.contains(e.category);
      }).toList();

      final noun = isSubcategory ? 'subcategories' : 'categories';

      cards.add(
        _buildInsightCard(
          context,
          onTap: () => context.push(
            AppRoutes.budgetHistory,
            extra: {
              'transactions': txns,
              'budgetName':
                  'Top ${top3.length} ${noun[0].toUpperCase()}${noun.substring(1)}',
            },
          ),
          iconData: Icons.pie_chart_outline_rounded,
          iconColor: AppColors.getText(context),
          iconBgColor: Colors.transparent,
          useSolidBackground: false,
          title: 'Top ${top3.length} $noun made up $pct% of your spending',
          subtitle: names,
        ),
      );
    }

    // 3. Weekend spending %
    if (expenses.isNotEmpty && totalSpent > 0) {
      double weekendTotal = 0;
      final txns = <TransactionModel>[];
      for (var e in expenses) {
        if (e.date.weekday == DateTime.saturday ||
            e.date.weekday == DateTime.sunday) {
          weekendTotal += e.amount;
          txns.add(e);
        }
      }
      final pct = (weekendTotal / totalSpent * 100).toStringAsFixed(0);
      if (weekendTotal > totalSpent * 0.4) {
        cards.add(
          _buildInsightCard(
            context,
            onTap: () => context.push(
              AppRoutes.budgetHistory,
              extra: {'transactions': txns, 'budgetName': 'Weekend Spending'},
            ),
            iconData: Icons.calendar_month_outlined,
            iconColor: AppColors.getText(context),
            iconBgColor: Colors.transparent,
            useSolidBackground: false,
            title: 'You spent a lot on weekends',
            subtitle: '$pct% of spending happened on Sat & Sun',
          ),
        );
      }
    }





    // 6. Highest spend / income
    TransactionModel? maxExpense;
    if (expenses.isNotEmpty) {
      maxExpense = expenses.reduce(
        (curr, next) => curr.amount > next.amount ? curr : next,
      );
    }

    TransactionModel? maxIncome;
    if (incomes.isNotEmpty) {
      maxIncome = incomes.reduce(
        (curr, next) => curr.amount > next.amount ? curr : next,
      );
    }

    final dateFormat = DateFormat('d MMM yyyy');

    if (maxExpense != null || maxIncome != null) {
      cards.add(SizedBox(height: AppSizes.h16));
    }

    if (maxExpense != null) {
      cards.add(
        _buildInsightCard(
          context,
          onTap: () =>
              context.push(AppRoutes.transactionDetail, extra: maxExpense),
          iconData: Icons.trending_up_rounded,
          iconColor: AppColors.white,
          iconBgColor: AppColors.error,
          title: 'Highest spend',
          subtitle: '₹${AppColors.formatShortAmount(maxExpense!.amount)}',
          titleStyle: AppTextStyles.body(
            context,
            color: AppColors.getTextMuted(context),
          ),
          subtitleStyle: AppTextStyles.body(
            context,
          ).copyWith(fontSize: 16, fontWeight: FontWeight.bold),
          trailingTitle: maxExpense!.merchant.isNotEmpty
              ? maxExpense!.merchant
              : resolveCategory(maxExpense!.category),
          trailingSubtitle: dateFormat.format(maxExpense!.date),
        ),
      );
    }

    if (maxIncome != null) {
      cards.add(
        _buildInsightCard(
          context,
          onTap: () =>
              context.push(AppRoutes.transactionDetail, extra: maxIncome),
          iconData: Icons.trending_down_rounded,
          iconColor: AppColors.white,
          iconBgColor: AppColors.primary,
          title: 'Highest income',
          subtitle: '₹${AppColors.formatShortAmount(maxIncome!.amount)}',
          titleStyle: AppTextStyles.body(
            context,
            color: AppColors.getTextMuted(context),
          ),
          subtitleStyle: AppTextStyles.body(
            context,
          ).copyWith(fontSize: 16, fontWeight: FontWeight.bold),
          trailingTitle: maxIncome!.merchant.isNotEmpty
              ? maxIncome!.merchant
              : resolveCategory(maxIncome!.category),
          trailingSubtitle: dateFormat.format(maxIncome!.date),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.getSurfaceContainerLowest(context),
        borderRadius: AppSizes.cardBorderRadius,
        border: isDark
            ? null
            : Border.all(color: AppColors.black.withOpacity(0.08), width: 1),
        boxShadow: isDark
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
        children: cards.asMap().entries.map((entry) {
          final idx = entry.key;
          final card = entry.value;
          final isLast = idx == cards.length - 1;

          if (card is SizedBox)
            return const SizedBox.shrink(); // Ignore separators for padding

          return Column(
            children: [
              card,
              if (!isLast && cards[idx + 1] is! SizedBox)
                Divider(
                  height: 1,
                  thickness: 1,
                  color: isDark ? Colors.grey[800] : Colors.grey[100],
                ),
              if (cards.length > idx + 1 && cards[idx + 1] is SizedBox)
                Divider(
                  height: 1,
                  thickness: 1,
                  color: isDark ? Colors.grey[800] : Colors.grey[100],
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInsightCard(
    BuildContext context, {
    required IconData iconData,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    Color? subtitleColor,
    TextStyle? titleStyle,
    TextStyle? subtitleStyle,
    String? trailingTitle,
    String? trailingSubtitle,
    VoidCallback? onTap,
    bool useSolidBackground = true,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.all(AppSizes.w16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (useSolidBackground) ...[
              Container(
                padding: EdgeInsets.all(AppSizes.w8),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(iconData, color: iconColor, size: AppSizes.r20),
              ),
              SizedBox(width: AppSizes.w12),
            ],
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style:
                              titleStyle ??
                              AppTextStyles.body(context).copyWith(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        SizedBox(height: AppSizes.h4),
                        Text(
                          subtitle,
                          style:
                              subtitleStyle ??
                              AppTextStyles.small(
                                context,
                                color:
                                    subtitleColor ??
                                    AppColors.getTextMuted(context),
                              ).copyWith(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                  if (trailingTitle != null) ...[
                    Container(
                      width: 1,
                      height: AppSizes.h32,
                      color: AppColors.isDark(context)
                          ? Colors.grey[800]
                          : Colors.grey[200],
                      margin: EdgeInsets.symmetric(horizontal: AppSizes.w12),
                    ),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            trailingTitle,
                            style: AppTextStyles.body(context).copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: AppSizes.h4),
                          Text(
                            trailingSubtitle ?? '',
                            style:
                                AppTextStyles.small(
                                  context,
                                  color: AppColors.getTextMuted(context),
                                ).copyWith(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(width: AppSizes.w8),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.getTextMuted(context).withOpacity(0.5),
              size: AppSizes.r20,
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryStat {
  final String id;
  final String name;
  final double amount;
  final double percentage;

  _CategoryStat({
    required this.id,
    required this.name,
    required this.amount,
    required this.percentage,
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:smart_money_tracker/core/constants/app_colors.dart';
import 'package:smart_money_tracker/core/constants/app_sizes.dart';
import 'package:smart_money_tracker/core/models/transaction_model.dart';
import 'package:smart_money_tracker/core/theme/app_text_styles.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/providers/transaction_provider.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/widgets/expandable_transaction_card.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:smart_money_tracker/core/services/analytics_service.dart';
import 'package:smart_money_tracker/core/common/widgets/banner_ad_widget.dart';

class IncomeScreen extends HookConsumerWidget {
  final DateTimeRange? initialDateRange;

  const IncomeScreen({super.key, this.initialDateRange});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use passed date range or default to the last 30 days
    final dateRange = useState(
      initialDateRange ??
          DateTimeRange(
            start: DateTime.now().subtract(const Duration(days: 30)),
            end: DateTime.now(),
          ),
    );

    useEffect(() {
      AnalyticsService.logScreenView('IncomeScreen');
      return null;
    }, const []);

    final transactionsAsync = ref.watch(
      transactionsInDateRangeProvider(dateRange.value),
    );

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: AppColors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Credit', style: AppTextStyles.subHeading(context)),
        centerTitle: true,
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: AppSizes.w12),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  const BannerAdWidget(),
                  // SizedBox(height: AppSizes.h12),
                ],
              ),
            ),
          ),
          transactionsAsync.when(
            data: (transactions) {
              final incomeTxns = transactions
                  .where((t) => t.type == TransactionType.credit)
                  .toList();
              if (incomeTxns.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: AppSizes.h(64),
                        bottom: AppSizes.h(40),
                      ),
                      child: Text(
                        'No credit transactions',
                        style: AppTextStyles.body(
                          context,
                          color: AppColors.getTextMuted(context),
                        ),
                      ),
                    ),
                  ),
                );
              }
              incomeTxns.sort((a, b) => b.date.compareTo(a.date));

              final Map<DateTime, List<TransactionModel>> grouped = {};
              for (var t in incomeTxns) {
                final date = DateTime(t.date.year, t.date.month, t.date.day);
                if (!grouped.containsKey(date)) {
                  grouped[date] = [];
                }
                grouped[date]!.add(t);
              }

              final sortedKeys = grouped.keys.toList();
              final today = DateTime.now();
              final todayDate = DateTime(today.year, today.month, today.day);
              final yesterday = todayDate.subtract(const Duration(days: 1));

              return SliverPadding(
                padding: EdgeInsets.only(bottom: AppSizes.h(100)),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final date = sortedKeys[index];
                    String topDateStr = DateFormat('yyyy').format(date);
                    String bottomDateStr = DateFormat('MMMM dd').format(date);
                    Color topColor = AppColors.getTextMuted(context);
                    Color bottomColor = AppColors.getText(context);

                    if (date == todayDate) {
                      bottomDateStr = 'Today';
                    } else if (date == yesterday) {
                      bottomDateStr = 'Yesterday';
                    }

                    final transactionWidgets = <Widget>[];
                    final transactionsForDay = grouped[date]!;

                    // Add Header here inside the card
                    transactionWidgets.add(
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSizes.w16,
                          vertical: AppSizes.h12,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.getDateContainerColor(context),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                              bottomDateStr == 'Today' ||
                                      bottomDateStr == 'Yesterday'
                                  ? bottomDateStr
                                  : '$bottomDateStr, $topDateStr',
                              style: AppTextStyles.heading(
                                context,
                                fontSize: 14,
                                color: bottomColor,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );

                    for (int i = 0; i < transactionsForDay.length; i++) {
                      final txn = transactionsForDay[i];
                      transactionWidgets.add(
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSizes.w12,
                          ),
                          child: ExpandableTransactionCard(
                            transaction: txn,
                            isGrouped: true,
                            margin: EdgeInsets.symmetric(vertical: AppSizes.h4),
                            onTap: () {
                              context.push('/transaction-detail', extra: txn);
                            },
                          ),
                        ),
                      );
                    }

                    return Container(
                      margin: EdgeInsets.zero,
                      decoration: const BoxDecoration(
                        color: Colors.transparent,
                      ),
                      child: ClipRRect(
                        borderRadius: AppSizes.boxBorderRadius,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: transactionWidgets,
                        ),
                      ),
                    );
                  }, childCount: sortedKeys.length),
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, stack) => SliverFillRemaining(
              child: Center(
                child: Text(
                  'Something went wrong',
                  style: AppTextStyles.body(context),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

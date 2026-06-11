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
  const IncomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use a default date range of the last 30 days
    final dateRange = useState(
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
          icon: Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Income', style: AppTextStyles.heading(context)),
        centerTitle: true,
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: EdgeInsets.all(AppSizes.w12),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  const BannerAdWidget(),
                  SizedBox(height: AppSizes.h12),
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
                return SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: AppSizes.h32),
                      child: Text(
                        'No income transactions',
                        style: AppTextStyles.body(context),
                      ),
                    ),
                  ),
                );
              }
              return SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: AppSizes.w12)
                    .copyWith(bottom: AppSizes.h(100)),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final txn = incomeTxns[index];
                      return ExpandableTransactionCard(
                        transaction: txn,
                        margin: EdgeInsets.symmetric(vertical: AppSizes.h4),
                        onTap: () {
                          context.push('/transaction-detail', extra: txn);
                        },
                      );
                    },
                    childCount: incomeTxns.length,
                  ),
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, stack) => SliverFillRemaining(
              child: Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }
}

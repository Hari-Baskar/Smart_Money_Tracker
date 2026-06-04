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

class ExpenseScreen extends HookConsumerWidget {
  const ExpenseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Default to last 30 days
    final dateRange = useState(
      DateTimeRange(
        start: DateTime.now().subtract(const Duration(days: 30)),
        end: DateTime.now(),
      ),
    );

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
        title: Text('Expense', style: AppTextStyles.heading(context)),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(AppSizes.w12),
        child: transactionsAsync.when(
          data: (transactions) {
            final expenseTxns = transactions
                .where((t) => t.type == TransactionType.debit)
                .toList();
            if (expenseTxns.isEmpty) {
              return Center(
                child: Text(
                  'No expense transactions',
                  style: AppTextStyles.body(context),
                ),
              );
            }
            return ListView.builder(
              itemCount: expenseTxns.length,
              itemBuilder: (context, index) {
                final txn = expenseTxns[index];
                return ExpandableTransactionCard(
                  transaction: txn,
                  margin: EdgeInsets.symmetric(vertical: AppSizes.h4),
                  onTap: () {
                    context.push('/transaction-detail', extra: txn);
                  },
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
        ),
      ),
    );
  }
}

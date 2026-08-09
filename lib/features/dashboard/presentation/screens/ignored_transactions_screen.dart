import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:smart_money_tracker/core/models/ignored_transaction_model.dart';
import 'package:smart_money_tracker/core/models/transaction_model.dart';
import 'package:smart_money_tracker/core/utils/app_toast.dart';
import 'package:smart_money_tracker/features/auth/presentation/providers/auth_provider.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/providers/transaction_provider.dart';
import 'package:smart_money_tracker/core/utils/sms_parser.dart';
import 'package:intl/intl.dart';
import 'package:smart_money_tracker/core/constants/app_colors.dart';
import 'package:smart_money_tracker/core/theme/app_text_styles.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_money_tracker/core/constants/app_routes.dart';
import 'package:smart_money_tracker/core/constants/app_sizes.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/widgets/expandable_transaction_card.dart';

class IgnoredTransactionsNotifier
    extends AsyncNotifier<List<IgnoredTransactionModel>> {
  @override
  FutureOr<List<IgnoredTransactionModel>> build() async {
    return ref.watch(ignoredTransactionsStreamProvider.future);
  }

  Future<void> restore(IgnoredTransactionModel ignored) async {
    final userId = ref.read(authStateProvider).value?.id;
    if (userId == null) return;

    // Remove from ignore list
    await ref
        .read(transactionRepositoryProvider)
        .restoreIgnoredTransaction(userId, ignored.id);

    // Parse SMS again to restore to main list
    TransactionModel? transaction;
    if (ignored.rawSms.startsWith('BackupJson: ') ||
        ignored.rawSms.startsWith('ManualJson: ')) {
      final jsonStr = ignored.rawSms.substring(
        ignored.rawSms.indexOf(': ') + 2,
      );
      try {
        final map = jsonDecode(jsonStr);
        transaction = TransactionModel.fromMap(map);
      } catch (e) {
        print('Error decoding manual/backup json: $e');
      }
    } else {
      // For older transactions deleted before the BackupJson fix
      if (ignored.rawSms == 'Manual Entry' || ignored.rawSms == 'Manual') {
        transaction = TransactionModel(
          id: ignored.id,
          amount: ignored.amount,
          merchant: ignored.merchant,
          date: ignored.date,
          type: TransactionType.debit,
          category: 'Other',
          rawSms: ignored.rawSms,
        );
      } else {
        transaction = await SmsParser.parse(
          ignored.rawSms,
          '',
          date: ignored.date,
        );
        // Ensure we preserve the amount and merchant if parser fails to extract them
        if (transaction != null) {
          transaction = transaction.copyWith(
            amount: transaction.amount == 0
                ? ignored.amount
                : transaction.amount,
            merchant: transaction.merchant == 'Unknown'
                ? ignored.merchant
                : transaction.merchant,
          );
        }
      }
    }

    if (transaction != null) {
      await ref
          .read(transactionRepositoryProvider)
          .saveTransaction(userId, transaction);
    }

    // We don't need to manually refresh the list anymore!
    // The ignoredTransactionsStreamProvider will automatically push the update
    // when LocalDatabaseHelper emits the change, causing this notifier to rebuild.
  }

  Future<void> deletePermanently(IgnoredTransactionModel ignored) async {
    final userId = ref.read(authStateProvider).value?.id;
    if (userId == null) return;

    // Remove from ignore list (which effectively deletes it permanently)
    await ref
        .read(transactionRepositoryProvider)
        .restoreIgnoredTransaction(userId, ignored.id);
  }
}

final ignoredTransactionsProvider =
    AsyncNotifierProvider<
      IgnoredTransactionsNotifier,
      List<IgnoredTransactionModel>
    >(() {
      return IgnoredTransactionsNotifier();
    });

class IgnoredTransactionsScreen extends HookConsumerWidget {
  const IgnoredTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(ignoredTransactionsProvider);
    final isDark = AppColors.isDark(context);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Text(
          'Manage Transactions',
          style: AppTextStyles.heading(context),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Theme.of(context).colorScheme.onBackground,
            size: AppSizes.r20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: state.when(
        data: (transactions) {
          if (transactions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: AppColors.primary,
                  ),
                  SizedBox(height: AppSizes.h16),
                  Text(
                    'No ignored transactions',
                    style: AppTextStyles.heading(context),
                  ),
                  SizedBox(height: AppSizes.h8),
                  Text(
                    'Transactions you delete will appear here.',
                    style: AppTextStyles.body(
                      context,
                      color: AppColors.getTextMuted(context),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: transactions.length,
            padding: EdgeInsets.symmetric(vertical: AppSizes.h8),
            itemBuilder: (context, index) {
              final txn = transactions[index];
              // Create a dummy TransactionModel for the UI
              TransactionModel dummyTxn;
              if (txn.rawSms.startsWith('BackupJson: ') ||
                  txn.rawSms.startsWith('ManualJson: ')) {
                final jsonStr = txn.rawSms.substring(
                  txn.rawSms.indexOf(': ') + 2,
                );
                try {
                  dummyTxn = TransactionModel.fromMap(jsonDecode(jsonStr));
                } catch (e) {
                  dummyTxn = TransactionModel(
                    id: txn.id,
                    amount: txn.amount,
                    merchant: txn.merchant,
                    date: txn.date,
                    type: TransactionType.unknown,
                    category: 'Unknown',
                    rawSms: txn.rawSms,
                  );
                }
              } else {
                dummyTxn = TransactionModel(
                  id: txn.id,
                  amount: txn.amount,
                  merchant: txn.merchant,
                  date: txn.date,
                  type: TransactionType.unknown,
                  category: 'Unknown',
                  rawSms: txn.rawSms,
                );
              }

              return ExpandableTransactionCard(
                transaction: dummyTxn,
                margin: EdgeInsets.symmetric(
                  horizontal: AppSizes.w12,
                  vertical: AppSizes.h4,
                ),
                onTap: () {
                  context.push(AppRoutes.ignoredTransactionDetail, extra: txn);
                },
              );
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, stack) => Center(
          child: Text(
            'Error: $err',
            style: AppTextStyles.body(context, color: AppColors.error),
          ),
        ),
      ),
    );
  }
}

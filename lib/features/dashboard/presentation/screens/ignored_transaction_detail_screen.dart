import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:smart_money_tracker/core/models/ignored_transaction_model.dart';
import 'package:smart_money_tracker/core/models/transaction_model.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/screens/transaction_detail_screen.dart';

class IgnoredTransactionDetailScreen extends StatelessWidget {
  final IgnoredTransactionModel transaction;

  const IgnoredTransactionDetailScreen({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    TransactionModel dummyTxn;
    if (transaction.rawSms.startsWith('BackupJson: ') || transaction.rawSms.startsWith('ManualJson: ')) {
      final jsonStr = transaction.rawSms.substring(transaction.rawSms.indexOf(': ') + 2);
      try {
        dummyTxn = TransactionModel.fromMap(jsonDecode(jsonStr));
      } catch (e) {
        dummyTxn = TransactionModel(
          id: transaction.id,
          amount: transaction.amount,
          merchant: transaction.merchant,
          date: transaction.date,
          type: TransactionType.unknown,
          category: 'Unknown',
          rawSms: transaction.rawSms,
        );
      }
    } else {
      dummyTxn = TransactionModel(
        id: transaction.id,
        amount: transaction.amount,
        merchant: transaction.merchant,
        date: transaction.date,
        type: TransactionType.unknown,
        category: 'Unknown',
        rawSms: transaction.rawSms,
      );
    }

    return TransactionDetailScreen(
      transaction: dummyTxn,
      isIgnored: true,
    );
  }
}

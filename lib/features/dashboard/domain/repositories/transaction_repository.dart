import 'package:expense_tracker/core/models/transaction_model.dart';

abstract class TransactionRepository {
  Future<void> saveTransaction(String userId, TransactionModel transaction);
  Future<void> deleteTransaction(String userId, String transactionId);
  Future<List<TransactionModel>> getTransactions(String userId);
  Stream<List<TransactionModel>> watchTransactions(String userId);
}

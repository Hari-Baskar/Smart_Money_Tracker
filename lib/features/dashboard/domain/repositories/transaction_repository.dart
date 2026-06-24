import 'package:smart_money_tracker/core/models/transaction_model.dart';

abstract class TransactionRepository {
  Future<void> saveTransaction(String userId, TransactionModel transaction);
  Future<void> deleteTransaction(String userId, String transactionId);
  Future<void> deleteAllTransactions(String userId);
  Future<List<TransactionModel>> getTransactions(String userId);
  Stream<List<TransactionModel>> watchTransactions(String userId);
  Stream<List<TransactionModel>> watchTransactionsInDateRange(String userId, DateTime start, DateTime end);
  Future<int> getLocalTransactionCount(String userId);
  Future<int> getRemoteTransactionCount(String userId);
  Future<void> restoreTransactions(String userId);
  Future<DateTime?> fetchOlderTransactions(String userId, {int limit = 20});
  Future<void> syncDateRange(String userId, DateTime start, DateTime end);
}

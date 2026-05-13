import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker/core/models/transaction_model.dart';
import 'package:expense_tracker/core/services/sms_service.dart';
import 'package:expense_tracker/features/auth/presentation/providers/auth_provider.dart';
import 'package:expense_tracker/features/dashboard/data/repositories/firebase_transaction_repository.dart';
import 'package:expense_tracker/features/dashboard/domain/repositories/transaction_repository.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return FirebaseTransactionRepository(FirebaseFirestore.instance);
});

final smsServiceProvider = Provider((ref) => SmsService());

// Modern AsyncNotifier for background syncing
class TransactionSyncNotifier extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() async {
    final authState = ref.watch(authStateProvider);
    final userId = authState.value?.id;

    if (userId != null) {
      // Run sync in the background without blocking the UI
      _syncAndListen(userId);
    }
  }

  bool _isListening = false;

  Future<void> _syncAndListen(String userId) async {
    final smsService = ref.read(smsServiceProvider);
    final repository = ref.read(transactionRepositoryProvider);

    // 1. Initial sync (Fetch recent)
    try {
      final transactions = await smsService.fetchRecentTransactions();
      for (var t in transactions) {
        await repository.saveTransaction(userId, t);
      }
    } catch (e) {
      print('Sync Error: $e');
    }

    // 2. Live sync (Only start once)
    if (!_isListening) {
      smsService.listenToIncomingSms((transaction) async {
        await repository.saveTransaction(userId, transaction);
      });
      _isListening = true;
    }
  }

  Future<void> sync() async {
    final authState = ref.read(authStateProvider);
    final userId = authState.value?.id;
    if (userId != null) {
      state = const AsyncLoading();
      await _syncAndListen(userId);
      state = const AsyncData(null);
    }
  }

  Future<void> deleteTransaction(String transactionId) async {
    final authState = ref.read(authStateProvider);
    final userId = authState.value?.id;
    if (userId != null) {
      state = const AsyncLoading();
      try {
        await ref
            .read(transactionRepositoryProvider)
            .deleteTransaction(userId, transactionId);
        state = const AsyncData(null);
      } catch (e, st) {
        state = AsyncError(e, st);
      }
    }
  }
}

final transactionSyncProvider =
    AsyncNotifierProvider<TransactionSyncNotifier, void>(() {
      return TransactionSyncNotifier();
    });

// Real-time stream provider for the UI
final transactionsProvider = StreamProvider<List<TransactionModel>>((ref) {
  final authState = ref.watch(authStateProvider);
  final userId = authState.value?.id;

  if (userId == null) return Stream.value([]);

  return ref.watch(transactionRepositoryProvider).watchTransactions(userId).map((
    transactions,
  ) {
    final List<TransactionModel> filteredTransactions = transactions.where((t) {
      return t.amount > 0 && t.type == TransactionType.debit;
    }).toList();

    final Map<String, TransactionModel> uniqueTransactions = {};

    for (var t in filteredTransactions) {
      // Create a unique key based on the minute, amount and merchant. 
      // If all three match, they are likely duplicates from SMS + Notification engines.
      final key =
          '${t.date.year}_${t.date.month}_${t.date.day}_${t.date.hour}_${t.date.minute}_${t.amount.toStringAsFixed(2)}_${t.merchant.toLowerCase()}';

      if (!uniqueTransactions.containsKey(key)) {
        uniqueTransactions[key] = t;
      } else {
        final existing = uniqueTransactions[key]!;
        
        // Strategy: Keep the one with the better merchant name
        // "Better" means: 
        // 1. Not UNKNOWN
        // 2. Not generic bank junk like "YOUR BANK"
        // 3. Longer name usually means more descriptive
        
        bool isNewBetter = false;
        if (existing.merchant == 'UNKNOWN' || 
            existing.merchant.contains('YOUR BANK') || 
            existing.merchant == 'BANK TRANSACTION') {
          isNewBetter = true;
        } else if (t.merchant.length > existing.merchant.length && 
                   !t.merchant.contains('YOUR BANK') &&
                   t.merchant != 'BANK TRANSACTION') {
          isNewBetter = true;
        }

        if (isNewBetter) {
          uniqueTransactions[key] = t;
        }
      }
    }

    return uniqueTransactions.values.toList();
  });
});



final todayTransactionsProvider = Provider<AsyncValue<List<TransactionModel>>>((
  ref,
) {
  final transactionsAsync = ref.watch(transactionsProvider);

  return transactionsAsync.whenData((transactions) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return transactions.where((t) {
      final tDate = DateTime(t.date.year, t.date.month, t.date.day);
      return tDate.isAtSameMomentAs(today);
    }).toList();
  });
});

final yesterdayTransactionsProvider = Provider<AsyncValue<List<TransactionModel>>>((ref) {
  final transactionsAsync = ref.watch(transactionsProvider);

  return transactionsAsync.whenData((transactions) {
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 1));

    return transactions.where((t) {
      final tDate = DateTime(t.date.year, t.date.month, t.date.day);
      return tDate.isAtSameMomentAs(yesterday);
    }).toList();
  });
});

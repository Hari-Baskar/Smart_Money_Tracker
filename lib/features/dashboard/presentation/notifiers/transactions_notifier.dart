import 'dart:async';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:smart_money_tracker/core/models/transaction_model.dart';
import 'package:smart_money_tracker/features/auth/presentation/providers/auth_provider.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/providers/subcategory_provider.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/providers/custom_asset_provider.dart';
import '../providers/transaction_provider.dart';

class TransactionsNotifier extends AsyncNotifier<List<TransactionModel>> {
  StreamSubscription<List<TransactionModel>>? _sub;

  @override
  FutureOr<List<TransactionModel>> build() {
    final authState = ref.watch(authStateProvider);
    final userId = authState.value?.id;

    if (userId == null) return [];

    final transactionsStream = ref.watch(transactionRepositoryProvider).watchTransactions(userId);
    final subcategoriesAsync = ref.watch(subcategoriesProvider);
    final subcategories = subcategoriesAsync.value ?? const [];
    final categoriesAsync = ref.watch(categoriesProvider);
    final categories = categoriesAsync.value ?? const [];
    final customAssetsAsync = ref.watch(customAssetsProvider);
    final customAssets = customAssetsAsync.value ?? const [];

    _sub?.cancel();

    final mappedStream = transactionsStream.map((transactions) {
      return transactions.where((t) => t.amount > 0).toList();
    });

    final completer = Completer<List<TransactionModel>>();

    _sub = mappedStream.listen(
      (transactions) {
        if (!completer.isCompleted) {
          completer.complete(transactions);
        }
        state = AsyncData(transactions);
      },
      onError: (err, stack) {
        if (!completer.isCompleted) {
          completer.completeError(err, stack);
        }
        state = AsyncError(err, stack);
      },
      onDone: () {
        if (!completer.isCompleted) {
          completer.complete([]);
        }
      },
    );

    ref.onDispose(() {
      _sub?.cancel();
    });

    return completer.future;
  }
}

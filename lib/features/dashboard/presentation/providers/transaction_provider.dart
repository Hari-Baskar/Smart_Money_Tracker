import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_money_tracker/core/models/transaction_model.dart';
import 'package:smart_money_tracker/core/services/sms_service.dart';
import 'package:smart_money_tracker/features/auth/presentation/providers/auth_provider.dart';
import 'package:smart_money_tracker/features/dashboard/data/repositories/firebase_transaction_repository.dart';
import 'package:smart_money_tracker/features/dashboard/domain/repositories/transaction_repository.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:smart_money_tracker/features/sms_disclosure/presentation/providers/sms_disclosure_provider.dart';

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
      // Google Play Policy compliance check: Ensure user consent is given and the Android SMS permission is active
      // BEFORE executing any SMS fetching or live inbox listening.
      final consentRepository = ref.read(smsConsentRepositoryProvider);
      final hasConsented = await consentRepository.hasConsented();
      final isPermissionGranted = await Permission.sms.isGranted;

      if (hasConsented && isPermissionGranted) {
        // Run sync in the background without blocking the UI
        _syncAndListen(userId);
      }
    }
  }

  bool _isListening = false;

  Future<void> _syncAndListen(String userId) async {
    // Google Play Policy compliance check: Ensure user consent is given and the Android SMS permission is active
    // BEFORE executing any SMS fetching or live inbox listening.
    final consentRepository = ref.read(smsConsentRepositoryProvider);
    final hasConsented = await consentRepository.hasConsented();
    final isPermissionGranted = await Permission.sms.isGranted;

    if (!hasConsented || !isPermissionGranted) {
      print('SMS Scanning / Sync is blocked: Consented = $hasConsented, Permission = $isPermissionGranted');
      return;
    }

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
        // Re-check consent and permission dynamically before processing and saving incoming SMS
        final stillConsented = await consentRepository.hasConsented();
        final stillPermissionGranted = await Permission.sms.isGranted;
        if (stillConsented && stillPermissionGranted) {
          await repository.saveTransaction(userId, transaction);
        }
      });
      _isListening = true;
    }
  }

  Future<void> sync() async {
    final authState = ref.read(authStateProvider);
    final userId = authState.value?.id;
    if (userId != null) {
      // Direct call to sync - check consent and permission
      final consentRepository = ref.read(smsConsentRepositoryProvider);
      final hasConsented = await consentRepository.hasConsented();
      final isPermissionGranted = await Permission.sms.isGranted;

      if (!hasConsented || !isPermissionGranted) {
        print('Manual sync blocked: Consented = $hasConsented, Permission = $isPermissionGranted');
        return;
      }

      state = const AsyncLoading();
      await _syncAndListen(userId);
      state = const AsyncData(null);
    }
  }

  Future<void> syncYesterday() async {
    final authState = ref.read(authStateProvider);
    final userId = authState.value?.id;
    if (userId != null) {
      // Direct call to syncYesterday - check consent and permission
      final consentRepository = ref.read(smsConsentRepositoryProvider);
      final hasConsented = await consentRepository.hasConsented();
      final isPermissionGranted = await Permission.sms.isGranted;

      if (!hasConsented || !isPermissionGranted) {
        print('Manual sync yesterday blocked: Consented = $hasConsented, Permission = $isPermissionGranted');
        return;
      }

      state = const AsyncLoading();
      try {
        final smsService = ref.read(smsServiceProvider);
        final repository = ref.read(transactionRepositoryProvider);
        
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        final transactions = await smsService.fetchTransactionsForDate(yesterday);
        
        for (var t in transactions) {
          await repository.saveTransaction(userId, t);
        }
      } catch (e) {
        print('Yesterday Sync Error: $e');
      }
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
      return t.amount > 0;
    }).toList();

    final List<TransactionModel> deduplicated = [];
    
    // Sort chronologically to make merge direction deterministic
    final sorted = List<TransactionModel>.from(filteredTransactions)
      ..sort((a, b) => a.date.compareTo(b.date));

    for (var current in sorted) {
      int duplicateIndex = -1;
      for (int i = 0; i < deduplicated.length; i++) {
        final existing = deduplicated[i];
        final timeDiff = current.date.difference(existing.date).abs();
        
        // Match duplicates: same amount, within 3 minutes, and same transaction type
        if (current.amount == existing.amount && 
            timeDiff.inMinutes <= 3 && 
            current.type == existing.type) {
          duplicateIndex = i;
          break;
        }
      }

      if (duplicateIndex == -1) {
        deduplicated.add(current);
      } else {
        final existing = deduplicated[duplicateIndex];
        
        // Strategy: Keep the one with the better merchant name
        bool isCurrentBetter = false;
        
        final existingMerchantUpper = existing.merchant.toUpperCase();
        final currentMerchantUpper = current.merchant.toUpperCase();
        
        bool isExistingGeneric = existingMerchantUpper == 'UNKNOWN' || 
            existingMerchantUpper == 'OTHER' ||
            existingMerchantUpper.contains('YOUR BANK') || 
            existingMerchantUpper == 'BANK TRANSACTION';
            
        bool isCurrentGeneric = currentMerchantUpper == 'UNKNOWN' || 
            currentMerchantUpper == 'OTHER' ||
            currentMerchantUpper.contains('YOUR BANK') || 
            currentMerchantUpper == 'BANK TRANSACTION';

        if (isExistingGeneric && !isCurrentGeneric) {
          isCurrentBetter = true;
        } else if (!isExistingGeneric && !isCurrentGeneric) {
          // Both are specific, keep the longer/more detailed one
          if (current.merchant.length > existing.merchant.length) {
            isCurrentBetter = true;
          }
        }

        if (isCurrentBetter) {
          deduplicated[duplicateIndex] = existing.copyWith(
            merchant: current.merchant,
            category: current.category != 'Unknown' && current.category != 'Other' 
                ? current.category 
                : existing.category,
            subcategory: current.subcategory != 'General' 
                ? current.subcategory 
                : existing.subcategory,
          );
        } else {
          // If we keep existing merchant, still check if current has a better category/subcategory
          final bool hasBetterCategory = (existing.category == 'Unknown' || existing.category == 'Other') && 
              current.category != 'Unknown' && current.category != 'Other';
          final bool hasBetterSubcategory = existing.subcategory == 'General' && current.subcategory != 'General';
          
          if (hasBetterCategory || hasBetterSubcategory) {
            deduplicated[duplicateIndex] = existing.copyWith(
              category: hasBetterCategory ? current.category : existing.category,
              subcategory: hasBetterSubcategory ? current.subcategory : existing.subcategory,
            );
          }
        }
      }
    }

    // Sort descending (newest first) for UI
    return deduplicated.reversed.toList();
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

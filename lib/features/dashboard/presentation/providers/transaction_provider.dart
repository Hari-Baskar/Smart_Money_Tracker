import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_money_tracker/core/models/transaction_model.dart';
import 'package:smart_money_tracker/core/services/sms_service.dart';
import 'package:smart_money_tracker/features/auth/presentation/providers/auth_provider.dart';
import 'package:smart_money_tracker/features/dashboard/data/repositories/firebase_transaction_repository.dart';
import 'package:smart_money_tracker/features/dashboard/domain/repositories/transaction_repository.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'subcategory_provider.dart';
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
// Real-time stream provider for the UI
final transactionsProvider = StreamProvider<List<TransactionModel>>((ref) {
  final authState = ref.watch(authStateProvider);
  final userId = authState.value?.id;

  if (userId == null) return Stream.value([]);

  final transactionsStream = ref.watch(transactionRepositoryProvider).watchTransactions(userId);
  final subcategoriesAsync = ref.watch(subcategoriesProvider);
  final subcategories = subcategoriesAsync.value ?? const [];

  return transactionsStream.map((transactions) {
    // Resolve subcategory names and filter out non-positive amounts
    // (Deduplication is now performed on ingestion at Level 1, 2, and 3)
    return transactions
        .where((t) => t.amount > 0)
        .map((t) => _resolveTransaction(t, subcategories))
        .toList();
  });
});

TransactionModel _resolveTransaction(TransactionModel t, List<SubcategoryModel> subcategories) {
  final resolvedCategory = _resolveCategoryName(t.category, subcategories);
  final resolvedSubcategory = _resolveSubcategoryName(t.subcategory, subcategories);
  
  final resolvedSplits = t.splits.map((split) {
    return TransactionSplit(
      amount: split.amount,
      category: _resolveCategoryName(split.category, subcategories),
      subcategory: _resolveSubcategoryName(split.subcategory, subcategories),
      notes: split.notes,
      date: split.date,
    );
  }).toList();

  return t.copyWith(
    category: resolvedCategory,
    subcategory: resolvedSubcategory,
    splits: resolvedSplits,
  );
}

bool _isDefaultCategory(String category) {
  return const ['Food', 'Travel', 'Shopping', 'Bills', 'Entertainment', 'Health', 'Investment', 'Other', 'Unknown'].contains(category);
}

bool _isUuid(String str) {
  final regExp = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );
  return regExp.hasMatch(str);
}

bool _isDefaultSubcategoryId(String str) {
  final regExp = RegExp(r'^[a-z]\d+$');
  return regExp.hasMatch(str);
}

String _resolveCategoryName(String categoryIdOrName, List<SubcategoryModel> subcategories) {
  if (_isDefaultCategory(categoryIdOrName)) {
    return categoryIdOrName;
  }
  
  try {
    final match = subcategories.firstWhere(
      (sub) => sub.id == categoryIdOrName && sub.isCustom && sub.name == 'General',
    );
    return match.parentCategory;
  } catch (_) {
    if (_isUuid(categoryIdOrName)) {
      return 'Unknown';
    }
    return categoryIdOrName;
  }
}

String _resolveSubcategoryName(String subcategoryIdOrName, List<SubcategoryModel> subcategories) {
  try {
    final match = subcategories.firstWhere((sub) => sub.id == subcategoryIdOrName);
    return match.name;
  } catch (_) {
    if (_isUuid(subcategoryIdOrName) || _isDefaultSubcategoryId(subcategoryIdOrName)) {
      return 'General';
    }
    return subcategoryIdOrName;
  }
}



final transactionsInDateRangeProvider = StreamProvider.family<List<TransactionModel>, DateTimeRange>((ref, range) {
  final authState = ref.watch(authStateProvider);
  final userId = authState.value?.id;

  if (userId == null) return Stream.value([]);

  final transactionsStream = ref
      .watch(transactionRepositoryProvider)
      .watchTransactionsInDateRange(userId, range.start, range.end);
      
  final subcategoriesAsync = ref.watch(subcategoriesProvider);
  final subcategories = subcategoriesAsync.value ?? const [];

  return transactionsStream.map((transactions) {
    return transactions
        .where((t) => t.amount > 0)
        .map((t) => _resolveTransaction(t, subcategories))
        .toList();
  });
});

final todayTransactionsProvider = Provider<AsyncValue<List<TransactionModel>>>((ref) {
  final now = DateTime.now();
  final startOfToday = DateTime(now.year, now.month, now.day);
  final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
  final todayRange = DateTimeRange(start: startOfToday, end: endOfToday);

  return ref.watch(transactionsInDateRangeProvider(todayRange));
});

final yesterdayTransactionsProvider = Provider<AsyncValue<List<TransactionModel>>>((ref) {
  final now = DateTime.now();
  final yesterday = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 1));
  final startOfYesterday = DateTime(yesterday.year, yesterday.month, yesterday.day);
  final endOfYesterday = DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59, 999);
  final yesterdayRange = DateTimeRange(start: startOfYesterday, end: endOfYesterday);

  return ref.watch(transactionsInDateRangeProvider(yesterdayRange));
});

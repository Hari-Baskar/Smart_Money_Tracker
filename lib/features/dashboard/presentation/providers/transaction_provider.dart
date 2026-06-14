import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_money_tracker/core/models/transaction_model.dart';
import 'package:smart_money_tracker/core/services/sms_service.dart';
import 'package:smart_money_tracker/features/auth/presentation/providers/auth_provider.dart';
import 'package:smart_money_tracker/features/dashboard/data/datasources/dashboard_local_data_source.dart';
import 'package:smart_money_tracker/features/dashboard/data/repositories/local_first_transaction_repository.dart';
import 'package:smart_money_tracker/features/dashboard/domain/repositories/transaction_repository.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'subcategory_provider.dart';
import 'package:smart_money_tracker/features/sms_disclosure/presentation/providers/sms_disclosure_provider.dart';

import 'package:smart_money_tracker/core/models/custom_asset_model.dart';
import 'package:smart_money_tracker/core/constants/payment_constants.dart';
import 'custom_asset_provider.dart';

import 'package:smart_money_tracker/features/dashboard/presentation/providers/datasource_provider.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/providers/user_bank_provider.dart';

import 'package:smart_money_tracker/core/services/update_service.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  final updateState = ref.watch(updateProvider).value;
  return LocalFirstTransactionRepository(
    ref.read(dashboardLocalDataSourceProvider),
    ref.read(dashboardRemoteDataSourceProvider),
    ref.read(userBankRepositoryProvider),
    config: updateState?.config,
  );
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
      print(
        'SMS Scanning / Sync is blocked: Consented = $hasConsented, Permission = $isPermissionGranted',
      );
      return;
    }

    final smsService = ref.read(smsServiceProvider);
    final repository = ref.read(transactionRepositoryProvider);

    // 1. Initial sync (Fetch recent) - optimized to run in parallel rather than sequential waits
    try {
      final transactions = await smsService.fetchRecentTransactions();
      if (transactions.isNotEmpty) {
        await Future.wait(
          transactions.map((t) => repository.saveTransaction(userId, t)),
        );
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
        print(
          'Manual sync blocked: Consented = $hasConsented, Permission = $isPermissionGranted',
        );
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
        print(
          'Manual sync yesterday blocked: Consented = $hasConsented, Permission = $isPermissionGranted',
        );
        return;
      }

      state = const AsyncLoading();
      try {
        final smsService = ref.read(smsServiceProvider);
        final repository = ref.read(transactionRepositoryProvider);

        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        final transactions = await smsService.fetchTransactionsForDate(
          yesterday,
        );

        if (transactions.isNotEmpty) {
          await Future.wait(
            transactions.map((t) => repository.saveTransaction(userId, t)),
          );
        }
      } catch (e) {
        print('Yesterday Sync Error: $e');
      }
      state = const AsyncData(null);
    }
  }

  Future<void> syncByDate(DateTime date) async {
    final authState = ref.read(authStateProvider);
    final userId = authState.value?.id;
    if (userId != null) {
      final consentRepository = ref.read(smsConsentRepositoryProvider);
      final hasConsented = await consentRepository.hasConsented();
      final isPermissionGranted = await Permission.sms.isGranted;

      if (!hasConsented || !isPermissionGranted) {
        print(
          'Manual sync by date blocked: Consented = $hasConsented, Permission = $isPermissionGranted',
        );
        return;
      }

      state = const AsyncLoading();
      try {
        final smsService = ref.read(smsServiceProvider);
        final repository = ref.read(transactionRepositoryProvider);

        final transactions = await smsService.fetchTransactionsForDate(date);

        if (transactions.isNotEmpty) {
          await Future.wait(
            transactions.map((t) => repository.saveTransaction(userId, t)),
          );
        }
      } catch (e) {
        print('Sync By Date Error: $e');
      }
      state = const AsyncData(null);
    }
  }

  Future<void> deleteTransaction(String transactionId) async {
    final authState = ref.read(authStateProvider);
    final userId = authState.value?.id;
    if (userId != null) {
      try {
        await ref
            .read(transactionRepositoryProvider)
            .deleteTransaction(userId, transactionId);
      } catch (e) {
        print('Error deleting transaction: $e');
      }
    }
  }

  Future<DateTime?> fetchOlderTransactions() async {
    final authState = ref.read(authStateProvider);
    final userId = authState.value?.id;
    if (userId != null) {
      try {
        final oldestDate = await ref.read(transactionRepositoryProvider).fetchOlderTransactions(userId);
        return oldestDate;
      } catch (e) {
        print('Fetch Older Error: $e');
        return null;
      }
    }
    return null;
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

  final transactionsStream = ref
      .watch(transactionRepositoryProvider)
      .watchTransactions(userId);
  final subcategoriesAsync = ref.watch(subcategoriesProvider);
  final subcategories = subcategoriesAsync.value ?? const [];
  final categoriesAsync = ref.watch(categoriesProvider);
  final categories = categoriesAsync.value ?? const [];
  final customAssetsAsync = ref.watch(customAssetsProvider);
  final customAssets = customAssetsAsync.value ?? const [];

  return transactionsStream.map((transactions) {
    return transactions.where((t) => t.amount > 0).toList();
  });
});

final transactionsInDateRangeProvider =
    StreamProvider.family<List<TransactionModel>, DateTimeRange>((ref, range) {
      final authState = ref.watch(authStateProvider);
      final userId = authState.value?.id;

      if (userId == null) return Stream.value([]);

      final transactionsStream = ref
          .watch(transactionRepositoryProvider)
          .watchTransactionsInDateRange(userId, range.start, range.end);

      final subcategoriesAsync = ref.watch(subcategoriesProvider);
      final subcategories = subcategoriesAsync.value ?? const [];
      final categoriesAsync = ref.watch(categoriesProvider);
      final categories = categoriesAsync.value ?? const [];
      final customAssetsAsync = ref.watch(customAssetsProvider);
      final customAssets = customAssetsAsync.value ?? const [];

      return transactionsStream.map((transactions) {
        return transactions.where((t) => t.amount > 0).toList();
      });
    });

final todayTransactionsProvider = Provider<AsyncValue<List<TransactionModel>>>((
  ref,
) {
  final now = DateTime.now();
  final startOfToday = DateTime(now.year, now.month, now.day);
  final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
  final todayRange = DateTimeRange(start: startOfToday, end: endOfToday);

  return ref.watch(transactionsInDateRangeProvider(todayRange));
});

final yesterdayTransactionsProvider =
    Provider<AsyncValue<List<TransactionModel>>>((ref) {
      final now = DateTime.now();
      final yesterday = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(const Duration(days: 1));
      final startOfYesterday = DateTime(
        yesterday.year,
        yesterday.month,
        yesterday.day,
      );
      final endOfYesterday = DateTime(
        yesterday.year,
        yesterday.month,
        yesterday.day,
        23,
        59,
        59,
        999,
      );
      final yesterdayRange = DateTimeRange(
        start: startOfYesterday,
        end: endOfYesterday,
      );

      return ref.watch(transactionsInDateRangeProvider(yesterdayRange));
    });

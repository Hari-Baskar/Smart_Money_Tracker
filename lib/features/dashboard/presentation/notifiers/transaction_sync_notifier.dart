import 'dart:async';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:smart_money_tracker/features/auth/presentation/providers/auth_provider.dart';
import 'package:smart_money_tracker/features/sms_disclosure/presentation/providers/sms_disclosure_provider.dart';
import '../providers/transaction_provider.dart';

class TransactionSyncNotifier extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() async {
    final authState = ref.watch(authStateProvider);
    final userId = authState.value?.id;

    if (userId != null) {
      final consentRepository = ref.read(smsConsentRepositoryProvider);
      final hasConsented = await consentRepository.hasConsented();
      final isPermissionGranted = await Permission.sms.isGranted;

      if (hasConsented && isPermissionGranted) {
        _syncAndListen(userId);
      }
    }
  }

  bool _isListening = false;

  Future<void> _syncAndListen(String userId) async {
    final consentRepository = ref.read(smsConsentRepositoryProvider);
    final hasConsented = await consentRepository.hasConsented();
    final isPermissionGranted = await Permission.sms.isGranted;

    if (!hasConsented || !isPermissionGranted) {
      print('SMS Scanning / Sync is blocked: Consented = $hasConsented, Permission = $isPermissionGranted');
      return;
    }

    final smsService = ref.read(smsServiceProvider);
    final repository = ref.read(transactionRepositoryProvider);

    try {
      final transactions = await smsService.fetchRecentTransactions();
      if (transactions.isNotEmpty) {
        await Future.wait(transactions.map((t) => repository.saveTransaction(userId, t)));
      }
    } catch (e) {
      print('Sync Error: $e');
    }

    if (!_isListening) {
      smsService.listenToIncomingSms((transaction) async {
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
        
        if (transactions.isNotEmpty) {
          await Future.wait(transactions.map((t) => repository.saveTransaction(userId, t)));
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
      try {
        await ref
            .read(transactionRepositoryProvider)
            .deleteTransaction(userId, transactionId);
      } catch (e) {
        print('Error deleting transaction: $e');
      }
    }
  }
}

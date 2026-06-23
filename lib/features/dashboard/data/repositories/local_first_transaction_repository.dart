import 'dart:async';
import 'package:smart_money_tracker/core/models/transaction_model.dart';
import 'package:smart_money_tracker/features/dashboard/domain/repositories/transaction_repository.dart';
import 'package:smart_money_tracker/features/dashboard/data/repositories/user_bank_repository.dart';
import 'package:smart_money_tracker/core/services/notification_service.dart';
import '../datasources/dashboard_local_data_source.dart';
import '../datasources/dashboard_remote_data_source.dart';
import '../datasources/sync_range_manager.dart';
import 'package:smart_money_tracker/core/services/analytics_service.dart';
import 'package:smart_money_tracker/core/models/app_config_model.dart';

class LocalFirstTransactionRepository implements TransactionRepository {
  final DashboardLocalDataSource _localDataSource;
  final DashboardRemoteDataSource _remoteDataSource;
  final UserBankRepository _userBankRepo;
  final SyncRangeManager _syncRangeManager = SyncRangeManager();
  final AppConfig? config;

  LocalFirstTransactionRepository(
    this._localDataSource,
    this._remoteDataSource,
    this._userBankRepo, {
    this.config,
  });

  @override
  Future<int> getLocalTransactionCount(String userId) async {
    return await _localDataSource.getTransactionCount(userId);
  }

  @override
  Future<int> getRemoteTransactionCount(String userId) async {
    return await _remoteDataSource.getTransactionCount(userId);
  }

  @override
  Future<void> restoreTransactions(String userId) async {
    try {
      print('Starting initial/delta transaction restore...');
      final trace = await AnalyticsService.startTrace('explicit_sync_trace');
      
      final newestDate = await _localDataSource.getNewestTransactionDate(userId);
      List<Map<String, dynamic>> transactionsData;

      if (newestDate != null) {
        // Delta sync: fetch only NEW transactions added from another device
        print('Fetching transactions newer than $newestDate');
        final limit = config?.paginationInitialFetchLimit ?? 500;
        
        // Optimize: Only fetch what we are missing since our last local data!
        // This drops the Firebase reads from 500 down to exactly the number of new transactions.
        transactionsData = await _remoteDataSource.getTransactionsInDateRange(
          userId, 
          newestDate, 
          DateTime.now().add(const Duration(days: 1)),
          limit: limit,
        );
      } else {
        final limit = config?.paginationInitialFetchLimit ?? 500;
        print('No local data found. Fetching latest $limit remote transactions.');
        transactionsData = await _remoteDataSource.getTransactions(userId, limit: limit);
      }

      AnalyticsService.logRemoteDbHit(action: 'explicit_sync_read');

      if (transactionsData.isNotEmpty) {
        final transactions = transactionsData
            .map((data) => TransactionModel.fromMap(data))
            .toList();
        
        await _localDataSource.saveTransactionsBatch(userId, transactions);
        AnalyticsService.logLocalDbHit(action: 'write_batch');

        // Mark the entire range up to now as safely synced in our tracker
        final fetchedOldest = transactions.last.date;
        await _syncRangeManager.addSyncedRange(userId, fetchedOldest, DateTime.now());
      } else {
        // If empty, there is zero data in cloud, so we mark all history as safely synced
        await _syncRangeManager.addSyncedRange(userId, DateTime(2000), DateTime.now());
      }
      
      final syncKey = 'has_completed_initial_sync_$userId';
      await _localDataSource.setBool(syncKey, true);
      
      await AnalyticsService.stopTrace(trace);
      print('Restore successfully completed.');
      await _updateLocalReminderState(userId);
    } catch (e) {
      print('Failed to perform explicit restore: $e');
      rethrow;
    }
  }

  @override
  Future<DateTime?> fetchOlderTransactions(String userId, {int? limit}) async {
    try {
      final oldestDate = await _localDataSource.getOldestTransactionDate(userId);
      if (oldestDate == null) {
         // No local data, call restore instead
         await restoreTransactions(userId);
         return null;
      }

      final actualLimit = limit ?? config?.paginationLoadMoreLimit ?? 20;

      print('Fetching older transactions before $oldestDate...');
      final transactionsData = await _remoteDataSource.getTransactionsBeforeDate(
        userId, 
        oldestDate, 
        limit: actualLimit,
      );

      AnalyticsService.logRemoteDbHit(action: 'fetch_older_read');

      if (transactionsData.isNotEmpty) {
        final transactions = transactionsData
            .map((data) => TransactionModel.fromMap(data))
            .toList();
        
        await _localDataSource.saveTransactionsBatch(userId, transactions);
        AnalyticsService.logLocalDbHit(action: 'write_batch_older');

        final fetchedOldestDate = transactions.last.date;
        // We must expand the Sync Range Tracker backwards!
        _syncRangeManager.addSyncedRange(userId, fetchedOldestDate, oldestDate);
        
        return fetchedOldestDate;
      }
      return null;
    } catch (e) {
      print('Failed to fetch older transactions: $e');
      return null;
    }
  }

  Future<void> syncDateRange(String userId, DateTime start, DateTime end) async {
    final requested = SyncDateRange(start, end);
    final syncedRanges = await _syncRangeManager.getSyncedRanges(userId);
    
    final gaps = _syncRangeManager.calculateMissingGaps(requested, syncedRanges);
    
    if (gaps.isEmpty) {
      print('Date range already fully synced.');
      return; 
    }
    
    for (var gap in gaps) {
      print('Fetching missing gap from Firebase: ${gap.start} to ${gap.end}');
      final transactionsData = await _remoteDataSource.getTransactionsInDateRange(
        userId,
        gap.start,
        gap.end,
      );
      
      if (transactionsData.isNotEmpty) {
        final transactions = transactionsData
            .map((data) => TransactionModel.fromMap(data))
            .toList();
        
        await _localDataSource.saveTransactionsBatch(userId, transactions);
        AnalyticsService.logLocalDbHit(action: 'write_batch_gap_sync');
      }
      
      await _syncRangeManager.addSyncedRange(userId, gap.start, gap.end);
    }
  }

  Future<void> _updateLocalReminderState(String userId) async {
    try {
      final now = DateTime.now();
      final startOfToday = DateTime(now.year, now.month, now.day);
      final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
      
      final todayTransactions = await _localDataSource.getTransactionsInDateRange(
        userId,
        startOfToday,
        endOfToday,
      );
      AnalyticsService.logLocalDbHit(action: 'read_reminder_state');

      final hasTransactions = todayTransactions.isNotEmpty;
      final hasUnknown = todayTransactions.any(
        (t) => t.category == 'Unknown' || t.category.toLowerCase() == 'unknown',
      );

      await NotificationService.updateDailyReminderState(
        hasTransactionsToday: hasTransactions,
        hasUnknownTransactionsToday: hasUnknown,
      );
    } catch (e) {
      print('Error updating local notification reminder state: $e');
    }
  }

  @override
  Future<void> saveTransaction(String userId, TransactionModel transaction) async {
    // Auto-clear local SharedPreferences cache when the day changes (New Day reset)
    final todayStr = "${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}";
    final lastSavedDate = await _localDataSource.getString('last_saved_date');
    if (lastSavedDate != null && lastSavedDate != todayStr) {
      await _localDataSource.remove('edited_transaction_ids');
      await _localDataSource.remove('high_quality_transaction_ids');
    }
    await _localDataSource.setString('last_saved_date', todayStr);
    
    final editedList = await _localDataSource.getStringList('edited_transaction_ids') ?? [];

    // 1. If this is a manual user edit, save it and record its ID in our local edited cache
    if (transaction.isEdited) {
      if (!editedList.contains(transaction.id)) {
        editedList.add(transaction.id);
        await _localDataSource.setStringList('edited_transaction_ids', editedList);
      }
      
      // Save locally first for instant UI response
      await _localDataSource.saveTransaction(userId, transaction);
      AnalyticsService.logLocalDbHit(action: 'write');
      
      // Sync to cloud in background
      _remoteDataSource.saveTransaction(userId, transaction.id, transaction.toMap()).then((_) {
        AnalyticsService.logRemoteDbHit(action: 'write');
      }).catchError((e) {
        print('Error syncing edit write to Firestore: $e');
      });
      await _updateLocalReminderState(userId);
      return;
    }

    // 2. If it is NOT a manual user edit, skip saving if we know it was edited in the past
    if (editedList.contains(transaction.id)) {
      return; // Skip saving to protect manual user edits (0 remote reads/writes!)
    }

    // 3. Local-Cache Merchant Quality Check
    final highQualityList = await _localDataSource.getStringList('high_quality_transaction_ids') ?? [];
    final isIncomingGeneric = _isGenericMerchant(transaction.merchant);

    if (isIncomingGeneric && highQualityList.contains(transaction.id)) {
      return; // Skip saving (0 remote reads/writes!)
    }

    // If the incoming merchant is specific and high-quality, record it locally
    if (!isIncomingGeneric && !highQualityList.contains(transaction.id)) {
      highQualityList.add(transaction.id);
      await _localDataSource.setStringList('high_quality_transaction_ids', highQualityList);
    }

    // Save to local SQLite database instantly (0 remote reads/writes!)
    await _localDataSource.saveTransaction(userId, transaction);
    AnalyticsService.logLocalDbHit(action: 'write');

    // Sync write blindly using merge options to Firestore in background
    _remoteDataSource.saveTransaction(userId, transaction.id, transaction.toMap(), merge: true).then((_) {
      AnalyticsService.logRemoteDbHit(action: 'write');
    }).catchError((e) {
      print('Error syncing write to Firestore: $e');
    });

    // Background: update the user's detected bank list (fire-and-forget)
    if (transaction.bankId != null && transaction.bankId!.isNotEmpty) {
      _userBankRepo.addBankId(userId, transaction.bankId!).catchError((_) {});
    }

    await _updateLocalReminderState(userId);
  }

  bool _isGenericMerchant(String merchant) {
    final upper = merchant.toUpperCase();
    return upper == 'UNKNOWN' || 
        upper == 'OTHER' || 
        upper.contains('YOUR BANK') || 
        upper == 'BANK TRANSACTION';
  }

  @override
  Future<void> deleteTransaction(String userId, String transactionId) async {
    // Delete locally first
    await _localDataSource.deleteTransaction(userId, transactionId);
    AnalyticsService.logLocalDbHit(action: 'delete');

    // Delete remotely in background
    _remoteDataSource.deleteTransaction(userId, transactionId).then((_) {
      AnalyticsService.logRemoteDbHit(action: 'delete');
    }).catchError((e) {
      print('Error syncing delete to Firestore: $e');
    });

    try {
      final editedList = await _localDataSource.getStringList('edited_transaction_ids') ?? [];
      if (editedList.contains(transactionId)) {
        editedList.remove(transactionId);
        await _localDataSource.setStringList('edited_transaction_ids', editedList);
      }

      final highQualityList = await _localDataSource.getStringList('high_quality_transaction_ids') ?? [];
      if (highQualityList.contains(transactionId)) {
        highQualityList.remove(transactionId);
        await _localDataSource.setStringList('high_quality_transaction_ids', highQualityList);
      }
    } catch (e) {
      print('Error removing deleted transaction from local cache: $e');
    }

    await _updateLocalReminderState(userId);
  }

  @override
  Future<List<TransactionModel>> getTransactions(String userId) async {
    final txns = await _localDataSource.getTransactions(userId);
    AnalyticsService.logLocalDbHit(action: 'read_all');
    return txns;
  }

  @override
  Stream<List<TransactionModel>> watchTransactions(String userId) {
    // Stream controller that queries local SQLite DB and yields results on updates
    final controller = StreamController<List<TransactionModel>>();
    StreamSubscription? dbSubscription;

    void updateList() async {
      try {
        final txns = await _localDataSource.getTransactions(userId);
        AnalyticsService.logLocalDbHit(action: 'read_stream');
        if (!controller.isClosed) {
          controller.add(txns);
        }
      } catch (e) {
        if (!controller.isClosed) {
          controller.addError(e);
        }
      }
    }

    controller.onListen = () {
      // Trigger initial load immediately to populate the stream right away
      updateList();
      dbSubscription = _localDataSource.onChange.listen((_) => updateList());
    };

    controller.onCancel = () {
      dbSubscription?.cancel();
      controller.close();
    };

    return controller.stream;
  }

  @override
  Stream<List<TransactionModel>> watchTransactionsInDateRange(String userId, DateTime start, DateTime end) {
    final controller = StreamController<List<TransactionModel>>();
    StreamSubscription? dbSubscription;

    void updateList() async {
      try {
        final txns = await _localDataSource.getTransactionsInDateRange(userId, start, end);
        AnalyticsService.logLocalDbHit(action: 'read_stream_range');
        if (!controller.isClosed) {
          controller.add(txns);
        }
      } catch (e) {
        if (!controller.isClosed) {
          controller.addError(e);
        }
      }
    }

    controller.onListen = () {
      // Trigger initial load immediately to populate the stream right away
      updateList();
      dbSubscription = _localDataSource.onChange.listen((_) => updateList());
    };

    controller.onCancel = () {
      dbSubscription?.cancel();
      controller.close();
    };

    return controller.stream;
  }
}

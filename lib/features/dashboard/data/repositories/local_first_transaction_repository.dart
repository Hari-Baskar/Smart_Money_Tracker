import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_money_tracker/core/models/transaction_model.dart';
import 'package:smart_money_tracker/core/services/local_database_helper.dart';
import 'package:smart_money_tracker/features/dashboard/domain/repositories/transaction_repository.dart';
import 'package:smart_money_tracker/features/dashboard/data/repositories/user_bank_repository.dart';

class LocalFirstTransactionRepository implements TransactionRepository {
  final FirebaseFirestore _firestore;
  late final UserBankRepository _userBankRepo;
  final LocalDatabaseHelper _dbHelper = LocalDatabaseHelper.instance;

  LocalFirstTransactionRepository(this._firestore) {
    _userBankRepo = UserBankRepository(_firestore);
  }

  // Check if we need to do a one-time migration of Firestore data to SQLite
  Future<void> initializeSync(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final syncKey = 'has_completed_initial_sync_$userId';
    final hasSynced = prefs.getBool(syncKey) ?? false;

    if (!hasSynced) {
      try {
        print('Starting one-time remote Firestore migration to SQLite...');
        // Pull all documents from Firestore
        final snapshot = await _firestore
            .collection('users')
            .doc(userId)
            .collection('transactions')
            .get();

        if (snapshot.docs.isNotEmpty) {
          final transactions = snapshot.docs
              .map((doc) => TransactionModel.fromMap(doc.data()))
              .toList();
          
          await _dbHelper.saveTransactionsBatch(userId, transactions);
        }
        await prefs.setBool(syncKey, true);
        print('One-time remote Firestore migration successfully completed.');
      } catch (e) {
        print('Failed to perform initial Firestore to SQLite sync: $e');
      }
    }
  }

  @override
  Future<void> saveTransaction(String userId, TransactionModel transaction) async {
    final docRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .doc(transaction.id);

    final prefs = await SharedPreferences.getInstance();

    // Auto-clear local SharedPreferences cache when the day changes (New Day reset)
    final todayStr = "${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}";
    final lastSavedDate = prefs.getString('last_saved_date');
    if (lastSavedDate != null && lastSavedDate != todayStr) {
      await prefs.remove('edited_transaction_ids');
      await prefs.remove('high_quality_transaction_ids');
    }
    await prefs.setString('last_saved_date', todayStr);
    
    final editedList = prefs.getStringList('edited_transaction_ids') ?? [];

    // 1. If this is a manual user edit, save it and record its ID in our local edited cache
    if (transaction.isEdited) {
      if (!editedList.contains(transaction.id)) {
        editedList.add(transaction.id);
        await prefs.setStringList('edited_transaction_ids', editedList);
      }
      
      // Save locally first for instant UI response
      await _dbHelper.saveTransaction(userId, transaction);
      
      // Sync to cloud in background
      docRef.set(transaction.toMap()).catchError((e) {
        print('Error syncing edit write to Firestore: $e');
      });
      return;
    }

    // 2. If it is NOT a manual user edit, skip saving if we know it was edited in the past
    if (editedList.contains(transaction.id)) {
      return; // Skip saving to protect manual user edits (0 remote reads/writes!)
    }

    // 3. Local-Cache Merchant Quality Check
    final highQualityList = prefs.getStringList('high_quality_transaction_ids') ?? [];
    final isIncomingGeneric = _isGenericMerchant(transaction.merchant);

    if (isIncomingGeneric && highQualityList.contains(transaction.id)) {
      return; // Skip saving (0 remote reads/writes!)
    }

    // If the incoming merchant is specific and high-quality, record it locally
    if (!isIncomingGeneric && !highQualityList.contains(transaction.id)) {
      highQualityList.add(transaction.id);
      await prefs.setStringList('high_quality_transaction_ids', highQualityList);
    }

    // Save to local SQLite database instantly (0 remote reads/writes!)
    await _dbHelper.saveTransaction(userId, transaction);

    // Sync write blindly using merge options to Firestore in background
    docRef.set(transaction.toMap(), SetOptions(merge: true)).catchError((e) {
      print('Error syncing write to Firestore: $e');
    });

    // Background: update the user's detected bank list (fire-and-forget)
    if (transaction.bankId != null && transaction.bankId!.isNotEmpty) {
      _userBankRepo.addBankId(userId, transaction.bankId!).catchError((_) {});
    }
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
    await _dbHelper.deleteTransaction(userId, transactionId);

    // Delete remotely in background
    _firestore
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .doc(transactionId)
        .delete()
        .catchError((e) {
          print('Error syncing delete to Firestore: $e');
        });

    try {
      final prefs = await SharedPreferences.getInstance();
      
      final editedList = prefs.getStringList('edited_transaction_ids') ?? [];
      if (editedList.contains(transactionId)) {
        editedList.remove(transactionId);
        await prefs.setStringList('edited_transaction_ids', editedList);
      }

      final highQualityList = prefs.getStringList('high_quality_transaction_ids') ?? [];
      if (highQualityList.contains(transactionId)) {
        highQualityList.remove(transactionId);
        await prefs.setStringList('high_quality_transaction_ids', highQualityList);
      }
    } catch (e) {
      print('Error removing deleted transaction from local cache: $e');
    }
  }

  @override
  Future<List<TransactionModel>> getTransactions(String userId) async {
    await initializeSync(userId);
    return await _dbHelper.getTransactions(userId);
  }

  @override
  Stream<List<TransactionModel>> watchTransactions(String userId) {
    // Stream controller that queries local SQLite DB and yields results on updates
    final controller = StreamController<List<TransactionModel>>();
    StreamSubscription? dbSubscription;

    void updateList() async {
      try {
        final txns = await _dbHelper.getTransactions(userId);
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
      // Trigger initial load and run migration sync in background
      initializeSync(userId).then((_) => updateList());
      
      dbSubscription = _dbHelper.onChange.listen((_) => updateList());
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
        final txns = await _dbHelper.getTransactionsInDateRange(userId, start, end);
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
      initializeSync(userId).then((_) => updateList());
      dbSubscription = _dbHelper.onChange.listen((_) => updateList());
    };

    controller.onCancel = () {
      dbSubscription?.cancel();
      controller.close();
    };

    return controller.stream;
  }
}

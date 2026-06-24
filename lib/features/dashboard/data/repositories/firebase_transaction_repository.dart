import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_money_tracker/core/models/transaction_model.dart';

import 'package:smart_money_tracker/features/dashboard/data/datasources/dashboard_local_data_source.dart';
import 'package:smart_money_tracker/features/dashboard/data/datasources/dashboard_remote_data_source.dart';
import 'package:smart_money_tracker/features/dashboard/domain/repositories/transaction_repository.dart';
import 'package:smart_money_tracker/features/dashboard/data/repositories/user_bank_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FirebaseTransactionRepository implements TransactionRepository {
  final FirebaseFirestore _firestore;
  late final UserBankRepository _userBankRepo;

  FirebaseTransactionRepository(this._firestore) {
    _userBankRepo = UserBankRepository(
      DashboardLocalDataSource(),
      DashboardRemoteDataSource(_firestore),
    );
  }

  @override
  Future<void> saveTransaction(
    String userId,
    TransactionModel transaction,
  ) async {
    final docRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .doc(transaction.id);

    final prefs = await SharedPreferences.getInstance();

    // Auto-clear local SharedPreferences cache when the day changes (New Day reset)
    final todayStr =
        "${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}";
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
      await docRef.set(transaction.toMap());
      return;
    }

    // 2. If it is NOT a manual user edit, skip saving if we know it was edited in the past
    if (editedList.contains(transaction.id)) {
      return; // Skip saving to protect manual user edits (0 remote reads/writes!)
    }

    // 3. Robust Fallback check: If cache was cleared or user has another device,
    // read Firestore to check if this transaction is already edited.
    try {
      final docSnapshot = await docRef.get();
      if (docSnapshot.exists) {
        final existingData = docSnapshot.data();
        if (existingData != null && existingData['isEdited'] == true) {
          // Update the local cache so we don't have to perform remote reads again
          if (!editedList.contains(transaction.id)) {
            editedList.add(transaction.id);
            await prefs.setStringList('edited_transaction_ids', editedList);
          }
          return; // Skip saving to protect manual user edits
        }
      }
    } catch (e) {
      print('Error checking edit status from Firestore: $e');
    }

    // 2. Local-Cache Merchant Quality Check
    // If a high-quality merchant details were already saved, do not overwrite them with generic bank descriptors
    final highQualityList =
        prefs.getStringList('high_quality_transaction_ids') ?? [];
    final isIncomingGeneric = _isGenericMerchant(transaction.merchant);

    if (isIncomingGeneric && highQualityList.contains(transaction.id)) {
      return; // Skip saving. A high-quality GPay/UPI merchant was already written (0 remote reads/writes!)
    }

    // If the incoming merchant is specific and high-quality, record it locally
    if (!isIncomingGeneric && !highQualityList.contains(transaction.id)) {
      highQualityList.add(transaction.id);
      await prefs.setStringList(
        'high_quality_transaction_ids',
        highQualityList,
      );
    }

    // 3. Write blindly using merge options to Firestore (0 remote reads!)
    await docRef.set(transaction.toMap(), SetOptions(merge: true));

    // 4. Background: update the user's detected bank list (fire-and-forget)
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
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .doc(transactionId)
        .delete();

    try {
      final prefs = await SharedPreferences.getInstance();

      final editedList = prefs.getStringList('edited_transaction_ids') ?? [];
      if (editedList.contains(transactionId)) {
        editedList.remove(transactionId);
        await prefs.setStringList('edited_transaction_ids', editedList);
      }

      final highQualityList =
          prefs.getStringList('high_quality_transaction_ids') ?? [];
      if (highQualityList.contains(transactionId)) {
        highQualityList.remove(transactionId);
        await prefs.setStringList(
          'high_quality_transaction_ids',
          highQualityList,
        );
      }
    } catch (e) {
      print('Error removing deleted transaction from local cache: $e');
    }
  }

  @override
  Future<void> deleteAllTransactions(String userId) async {
    final collection = _firestore
        .collection('users')
        .doc(userId)
        .collection('transactions');
    
    var snapshots = await collection.limit(500).get();
    while (snapshots.docs.isNotEmpty) {
      final batch = _firestore.batch();
      for (final doc in snapshots.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      snapshots = await collection.limit(500).get();
    }
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('edited_transaction_ids');
      await prefs.remove('high_quality_transaction_ids');
    } catch (e) {
      print('Error clearing transaction local cache: $e');
    }
  }

  @override
  Future<List<TransactionModel>> getTransactions(String userId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .orderBy('date', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => TransactionModel.fromMap(doc.data()))
        .toList();
  }

  @override
  Stream<List<TransactionModel>> watchTransactions(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => TransactionModel.fromMap(doc.data()))
              .toList(),
        );
  }

  @override
  Stream<List<TransactionModel>> watchTransactionsInDateRange(
    String userId,
    DateTime start,
    DateTime end,
  ) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .where('date', isGreaterThanOrEqualTo: start.toIso8601String())
        .where('date', isLessThanOrEqualTo: end.toIso8601String())
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => TransactionModel.fromMap(doc.data()))
              .toList(),
        );
  }

  @override
  Future<int> getLocalTransactionCount(String userId) async {
    return 0; // Not applicable for purely remote repository
  }

  @override
  Future<int> getRemoteTransactionCount(String userId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  @override
  Future<void> restoreTransactions(String userId) async {
    // No-op for purely remote repository
  }

  @override
  Future<DateTime?> fetchOlderTransactions(String userId, {int limit = 20}) async {
    // No-op for purely remote repository as watchTransactions handles it
    return null;
  }

  @override
  Future<void> syncDateRange(String userId, DateTime start, DateTime end) async {
    // No-op for purely remote repository
  }
}

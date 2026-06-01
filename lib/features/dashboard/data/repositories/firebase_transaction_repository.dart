import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_money_tracker/core/models/transaction_model.dart';
import 'package:smart_money_tracker/features/dashboard/domain/repositories/transaction_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FirebaseTransactionRepository implements TransactionRepository {
  final FirebaseFirestore _firestore;

  FirebaseTransactionRepository(this._firestore);

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
    
    // Check if this transaction has been manually edited by the user in the past
    final editedList = prefs.getStringList('edited_transaction_ids') ?? [];
    if (editedList.contains(transaction.id)) {
      return; // Skip saving to protect manual user edits (0 remote reads/writes!)
    }

    // 1. If this is a manual user edit, save it and record its ID in our local edited cache
    if (transaction.isEdited) {
      if (!editedList.contains(transaction.id)) {
        editedList.add(transaction.id);
        await prefs.setStringList('edited_transaction_ids', editedList);
      }
      await docRef.set(transaction.toMap());
      return;
    }

    // 2. Local-Cache Merchant Quality Check
    // If a high-quality merchant details were already saved, do not overwrite them with generic bank descriptors
    final highQualityList = prefs.getStringList('high_quality_transaction_ids') ?? [];
    final isIncomingGeneric = _isGenericMerchant(transaction.merchant);

    if (isIncomingGeneric && highQualityList.contains(transaction.id)) {
      return; // Skip saving. A high-quality GPay/UPI merchant was already written (0 remote reads/writes!)
    }

    // If the incoming merchant is specific and high-quality, record it locally
    if (!isIncomingGeneric && !highQualityList.contains(transaction.id)) {
      highQualityList.add(transaction.id);
      await prefs.setStringList('high_quality_transaction_ids', highQualityList);
    }

    // 3. Write blindly using merge options to Firestore (0 remote reads!)
    await docRef.set(transaction.toMap(), SetOptions(merge: true));
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
  }

  @override
  Future<List<TransactionModel>> getTransactions(String userId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .orderBy('date', descending: true)
        .get();

    return snapshot.docs.map((doc) => TransactionModel.fromMap(doc.data())).toList();
  }

  @override
  Stream<List<TransactionModel>> watchTransactions(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => TransactionModel.fromMap(doc.data())).toList());
  }

  @override
  Stream<List<TransactionModel>> watchTransactionsInDateRange(String userId, DateTime start, DateTime end) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .where('date', isGreaterThanOrEqualTo: start.toIso8601String())
        .where('date', isLessThanOrEqualTo: end.toIso8601String())
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => TransactionModel.fromMap(doc.data())).toList());
  }
}

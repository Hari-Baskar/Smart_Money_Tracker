import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker/core/models/transaction_model.dart';
import 'package:expense_tracker/features/dashboard/domain/repositories/transaction_repository.dart';

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

    if (transaction.isEdited) {
      await docRef.set(transaction.toMap());
      return;
    }

    final doc = await docRef.get();
    if (doc.exists) {
      final existingData = doc.data();
      if (existingData != null && existingData['isEdited'] == true) {
        return; // Don't overwrite user edits
      }
    }

    await docRef.set(transaction.toMap());
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
}

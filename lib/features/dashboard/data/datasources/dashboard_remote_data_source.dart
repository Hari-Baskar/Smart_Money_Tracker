import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardRemoteDataSource {
  final FirebaseFirestore _firestore;

  DashboardRemoteDataSource(this._firestore);

  // ── Transactions ───────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getTransactions(String userId, {int limit = 500}) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .orderBy('date', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<int> getTransactionCount(String userId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  Future<List<Map<String, dynamic>>> getTransactionsBeforeDate(
    String userId, 
    DateTime date, {
    int limit = 50,
  }) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .where('date', isLessThan: date.toIso8601String())
        .orderBy('date', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<List<Map<String, dynamic>>> getTransactionsInDateRange(
    String userId, 
    DateTime start, 
    DateTime end, {
    int limit = 1000,
  }) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .where('date', isGreaterThanOrEqualTo: start.toIso8601String())
        .where('date', isLessThanOrEqualTo: end.toIso8601String())
        .orderBy('date', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<void> saveTransaction(
    String userId, 
    String id, 
    Map<String, dynamic> data, {
    bool merge = false,
  }) async {
    final docRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .doc(id);
    if (merge) {
      await docRef.set(data, SetOptions(merge: true));
    } else {
      await docRef.set(data);
    }
  }

  Future<void> deleteTransaction(String userId, String id) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .doc(id)
        .delete();
  }

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
  }

  // ── Categories ─────────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getCategories(String userId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('categories')
        .get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<void> saveCategory(String userId, String id, Map<String, dynamic> data) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('categories')
        .doc(id)
        .set(data);
  }

  Future<void> deleteCategory(String userId, String id) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('categories')
        .doc(id)
        .delete();
  }

  // ── Subcategories ──────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getSubcategories(String userId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('subcategories')
        .get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<void> saveSubcategory(String userId, String id, Map<String, dynamic> data) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('subcategories')
        .doc(id)
        .set(data);
  }

  Future<void> deleteSubcategory(String userId, String id) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('subcategories')
        .doc(id)
        .delete();
  }

  // ── Custom Assets ──────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getCustomAssets(String userId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('custom_assets')
        .get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<void> saveCustomAsset(String userId, String id, Map<String, dynamic> data) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('custom_assets')
        .doc(id)
        .set(data);
  }

  Future<void> deleteCustomAsset(String userId, String id) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('custom_assets')
        .doc(id)
        .delete();
  }

  // ── User Bank IDs ──────────────────────────────────────────────────────────
  Future<List<String>> getUserBankIds(String userId) async {
    final doc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('profile')
        .doc('settings')
        .get();

    if (doc.exists) {
      final data = doc.data();
      return List<String>.from(data?['userBankIds'] ?? []);
    }
    return [];
  }

  Future<void> saveUserBankIds(String userId, List<String> bankIds) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('profile')
        .doc('settings')
        .set({'userBankIds': bankIds}, SetOptions(merge: true));
  }

  Future<List<String>> deriveBankIdsFromTransactions(String userId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .get();

    return snapshot.docs
        .map((doc) => doc.data()['bankId'] as String?)
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();
  }
}

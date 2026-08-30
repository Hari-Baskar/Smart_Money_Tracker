import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_money_tracker/core/models/budget_model.dart';
import 'package:smart_money_tracker/core/services/local_database_helper.dart';

class BudgetRepository {
  final LocalDatabaseHelper _dbHelper = LocalDatabaseHelper.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> saveBudget(String uid, BudgetModel budget) async {
    // Save to local SQLite
    await _dbHelper.saveBudget(uid, budget);
    
    // Sync specifically requested fields to Firebase
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('budgets')
          .doc(budget.id)
          .set({
        'id': budget.id,
        'name': budget.name,
        'categoryId': budget.categoryId,
        'amount': budget.amount,
        'period': budget.period.name,
        if (budget.startDate != null) 'startDate': budget.startDate!.toIso8601String(),
        if (budget.endDate != null) 'endDate': budget.endDate!.toIso8601String(),
        'isStopped': budget.isStopped,
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error saving budget to Firebase: $e');
    }
  }

  Future<List<BudgetModel>> getBudgets(String uid) async {
    return await _dbHelper.getBudgets(uid);
  }

  Future<void> deleteBudget(String uid, String id) async {
    // Delete locally
    await _dbHelper.deleteBudget(uid, id);
    
    // Delete from Firebase
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('budgets')
          .doc(id)
          .delete();
    } catch (e) {
      print('Error deleting budget from Firebase: $e');
    }
  }

  Future<void> syncBudgetsFromFirebase(String uid) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('budgets')
          .get();
          
      // Fetch categories for fallback names
      final categories = await _dbHelper.getCategories(uid);
          
      for (var doc in snapshot.docs) {
        final data = doc.data();
        
        String fallbackName = 'Overall Budget';
        if (data['categoryId'] != null) {
          try {
            final category = categories.firstWhere((c) => c.id == data['categoryId']);
            fallbackName = '${category.name} Budget';
          } catch (_) {
            fallbackName = 'Category Budget';
          }
        }
        
        final budget = BudgetModel(
          id: data['id'],
          name: data['name'] ?? fallbackName,
          categoryId: data['categoryId'],
          amount: (data['amount'] as num).toDouble(),
          period: BudgetPeriod.values.firstWhere(
            (e) => e.name == data['period'],
            orElse: () => BudgetPeriod.monthly,
          ),
          startDate: data['startDate'] != null ? DateTime.parse(data['startDate']) : null,
          endDate: data['endDate'] != null ? DateTime.parse(data['endDate']) : null,
          isStopped: data['isStopped'] ?? false,
        );
        await _dbHelper.saveBudget(uid, budget);
      }
    } catch (e) {
      print('Error syncing budgets from Firebase: $e');
    }
  }

  Stream<void> get onBudgetsChanged => _dbHelper.onChange;
}

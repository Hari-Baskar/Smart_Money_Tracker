import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_money_tracker/core/models/transaction_model.dart';
import 'package:uuid/uuid.dart';

class TestDataService {
  static Future<void> generate1000Transactions(String userId) async {
    final firestore = FirebaseFirestore.instance;
    final random = Random();
    const uuid = Uuid();
    
    final categories = ['Food', 'Transport', 'Entertainment', 'Shopping', 'Utilities'];
    final merchants = ['Walmart', 'Uber', 'Netflix', 'Amazon', 'Electric Co', 'Starbucks', 'Gas Station'];
    
    // We will use batches since Firestore limit is 500 writes per batch
    WriteBatch batch1 = firestore.batch();
    WriteBatch batch2 = firestore.batch();
    
    final now = DateTime.now();
    
    for (int i = 0; i < 1000; i++) {
      // Spread across the last 3 years (1095 days)
      final daysAgo = random.nextInt(1095);
      final date = now.subtract(Duration(days: daysAgo, hours: random.nextInt(24), minutes: random.nextInt(60)));
      
      final transaction = TransactionModel(
        id: uuid.v4(),
        amount: (random.nextDouble() * 100) + 5, // Random amount between 5 and 105
        merchant: merchants[random.nextInt(merchants.length)],
        date: date,
        type: TransactionType.debit,
        category: categories[random.nextInt(categories.length)],
        subcategory: 'General',
        rawSms: 'Test SMS data',
        splits: [],
        isEdited: false,
      );
      
      final docRef = firestore
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .doc(transaction.id);
          
      if (i < 500) {
        batch1.set(docRef, transaction.toMap());
      } else {
        batch2.set(docRef, transaction.toMap());
      }
    }
    
    await batch1.commit();
    await batch2.commit();
  }
}

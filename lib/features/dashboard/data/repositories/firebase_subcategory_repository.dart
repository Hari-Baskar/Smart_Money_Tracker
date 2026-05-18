import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_money_tracker/core/models/transaction_model.dart';
import '../../domain/repositories/subcategory_repository.dart';

class FirebaseSubcategoryRepository implements SubcategoryRepository {
  final FirebaseFirestore _firestore;

  FirebaseSubcategoryRepository(this._firestore);

  @override
  Future<List<SubcategoryModel>> getSubcategories(String userId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('subcategories')
        .get();

    return snapshot.docs
        .map((doc) => SubcategoryModel.fromMap(doc.data()))
        .toList();
  }

  @override
  Future<void> saveSubcategory(String userId, SubcategoryModel subcategory) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('subcategories')
        .doc(subcategory.id)
        .set(subcategory.toMap());
  }

  @override
  Future<void> deleteSubcategory(String userId, String subcategoryId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('subcategories')
        .doc(subcategoryId)
        .delete();
  }
}

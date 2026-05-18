import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_money_tracker/core/models/transaction_model.dart';
import 'package:smart_money_tracker/features/auth/presentation/providers/auth_provider.dart';
import 'package:smart_money_tracker/features/dashboard/data/repositories/firebase_subcategory_repository.dart';
import 'package:smart_money_tracker/features/dashboard/domain/repositories/subcategory_repository.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:uuid/uuid.dart';

final subcategoryRepositoryProvider = Provider<SubcategoryRepository>((ref) {
  return FirebaseSubcategoryRepository(FirebaseFirestore.instance);
});

final subcategoriesProvider = AsyncNotifierProvider<SubcategoryNotifier, List<SubcategoryModel>>(() {
  return SubcategoryNotifier();
});

class SubcategoryNotifier extends AsyncNotifier<List<SubcategoryModel>> {
  @override
  Future<List<SubcategoryModel>> build() async {
    final authState = ref.watch(authStateProvider);
    final userId = authState.value?.id;
    if (userId == null) return [];

    final custom = await ref.read(subcategoryRepositoryProvider).getSubcategories(userId);
    return [..._defaultSubcategories, ...custom];
  }

  static final List<SubcategoryModel> _defaultSubcategories = [
    // Food
    SubcategoryModel(id: 'f1', name: 'Restaurant', parentCategory: 'Food'),
    SubcategoryModel(id: 'f2', name: 'Snacks', parentCategory: 'Food'),
    SubcategoryModel(id: 'f3', name: 'Groceries', parentCategory: 'Food'),
    SubcategoryModel(id: 'f4', name: 'Drinks', parentCategory: 'Food'),
    SubcategoryModel(id: 'f5', name: 'Delivery', parentCategory: 'Food'),
    // Travel
    SubcategoryModel(id: 't1', name: 'Fuel', parentCategory: 'Travel'),
    SubcategoryModel(id: 't2', name: 'Taxi/Uber', parentCategory: 'Travel'),
    SubcategoryModel(id: 't3', name: 'Parking', parentCategory: 'Travel'),
    SubcategoryModel(id: 't4', name: 'Bus/Train', parentCategory: 'Travel'),
    // Shopping
    SubcategoryModel(id: 's1', name: 'Clothing', parentCategory: 'Shopping'),
    SubcategoryModel(id: 's2', name: 'Electronics', parentCategory: 'Shopping'),
    SubcategoryModel(id: 's3', name: 'Home', parentCategory: 'Shopping'),
    SubcategoryModel(id: 's4', name: 'Gifts', parentCategory: 'Shopping'),
    // Bills
    SubcategoryModel(id: 'b1', name: 'Rent', parentCategory: 'Bills'),
    SubcategoryModel(id: 'b2', name: 'Electricity', parentCategory: 'Bills'),
    SubcategoryModel(id: 'b3', name: 'Internet', parentCategory: 'Bills'),
    SubcategoryModel(id: 'b4', name: 'Mobile', parentCategory: 'Bills'),
    SubcategoryModel(id: 'b5', name: 'Insurance', parentCategory: 'Bills'),
    // Entertainment
    SubcategoryModel(id: 'e1', name: 'Movies', parentCategory: 'Entertainment'),
    SubcategoryModel(id: 'e2', name: 'Games', parentCategory: 'Entertainment'),
    SubcategoryModel(id: 'e3', name: 'Streaming', parentCategory: 'Entertainment'),
    // Health
    SubcategoryModel(id: 'h1', name: 'Doctor', parentCategory: 'Health'),
    SubcategoryModel(id: 'h2', name: 'Pharmacy', parentCategory: 'Health'),
    SubcategoryModel(id: 'h3', name: 'Fitness', parentCategory: 'Health'),
    // Investment
    SubcategoryModel(id: 'i1', name: 'Stocks', parentCategory: 'Investment'),
    SubcategoryModel(id: 'i2', name: 'Mutual Funds', parentCategory: 'Investment'),
    SubcategoryModel(id: 'i3', name: 'Gold', parentCategory: 'Investment'),
    // Other
    SubcategoryModel(id: 'o1', name: 'General', parentCategory: 'Other'),
    SubcategoryModel(id: 'o2', name: 'Maintenance', parentCategory: 'Other'),
    SubcategoryModel(id: 'o3', name: 'Services', parentCategory: 'Other'),
  ];

  Future<void> addSubcategory(String name, String parentCategory) async {
    final authState = ref.read(authStateProvider);
    final userId = authState.value?.id;
    if (userId == null) return;

    final sub = SubcategoryModel(
      id: const Uuid().v4(),
      name: name,
      parentCategory: parentCategory,
      isCustom: true,
    );

    await ref.read(subcategoryRepositoryProvider).saveSubcategory(userId, sub);
    ref.invalidateSelf();
  }
}

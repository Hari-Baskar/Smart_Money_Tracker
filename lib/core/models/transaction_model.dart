class TransactionSplit {
  final double amount;
  final String category;
  final String subcategory;
  final String? notes;
  final DateTime? date;
 
  TransactionSplit({
    required this.amount,
    required this.category,
    this.subcategory = 'General',
    this.notes,
    this.date,
  });
 
  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'category': category,
      'subcategory': subcategory,
      'notes': notes,
      'date': date?.toIso8601String(),
    };
  }
 
  factory TransactionSplit.fromMap(Map<String, dynamic> map) {
    return TransactionSplit(
      amount: (map['amount'] ?? 0.0).toDouble(),
      category: map['category'] ?? 'Other',
      subcategory: map['subcategory'] ?? 'General',
      notes: map['notes'],
      date: map['date'] != null ? DateTime.parse(map['date']) : null,
    );
  }
}
 
class CategoryModel {
  final String id;
  final String name;
  final bool isCustom;
  final bool isIncome;
  final bool isArchived;

  CategoryModel({
    required this.id,
    required this.name,
    this.isCustom = false,
    this.isIncome = false,
    this.isArchived = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'isCustom': isCustom ? 1 : 0,
      'isIncome': isIncome ? 1 : 0,
      'isArchived': isArchived ? 1 : 0,
    };
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      isCustom: map['isCustom'] == 1 || map['isCustom'] == true,
      isIncome: map['isIncome'] == 1 || map['isIncome'] == true,
      isArchived: map['isArchived'] == 1 || map['isArchived'] == true,
    );
  }
}

class SubcategoryModel {
  final String id;
  final String name;
  final String parentCategoryId;
  final bool isCustom;
  final bool isIncome;
  final bool isArchived;
 
  SubcategoryModel({
    required this.id,
    required this.name,
    required this.parentCategoryId,
    this.isCustom = false,
    this.isIncome = false,
    this.isArchived = false,
  });
 
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'parentCategoryId': parentCategoryId,
      'isCustom': isCustom,
      'isIncome': isIncome,
      'isArchived': isArchived,
    };
  }
 
  factory SubcategoryModel.fromMap(Map<String, dynamic> map) {
    return SubcategoryModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      parentCategoryId: map['parentCategoryId'] ?? map['parentCategory'] ?? 'Other',
      isCustom: map['isCustom'] == 1 || map['isCustom'] == true,
      isIncome: map['isIncome'] == 1 || map['isIncome'] == true,
      isArchived: map['isArchived'] == 1 || map['isArchived'] == true,
    );
  }
}

enum TransactionType { debit, credit, unknown }

class TransactionModel {
  final String id;
  final double amount;
  final String merchant;
  final DateTime date;
  final TransactionType type;
  final String category;
  final String subcategory;
  final String rawSms;
  final List<TransactionSplit> splits;
  final bool isEdited;
  final String? reference;
  final String? bankId;
  final String? paymentMethodId;
 
  TransactionModel({
    required this.id,
    required this.amount,
    required this.merchant,
    required this.date,
    required this.type,
    required this.category,
    this.subcategory = 'General',
    required this.rawSms,
    this.splits = const [],
    this.isEdited = false,
    this.reference,
    this.bankId,
    this.paymentMethodId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'merchant': merchant,
      'date': date.toIso8601String(),
      'type': type.name,
      'category': category,
      'subcategory': subcategory,
      'rawSms': rawSms,
      'splits': splits.map((x) => x.toMap()).toList(),
      'isEdited': isEdited,
      'reference': reference,
      'bankId': bankId,
      'paymentMethodId': paymentMethodId,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      merchant: map['merchant'] ?? '',
      date: DateTime.parse(map['date']),
      type: TransactionType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => TransactionType.unknown,
      ),
      category: map['category'] ?? 'Other',
      subcategory: map['subcategory'] ?? 'General',
      rawSms: map['rawSms'] ?? '',
      splits: (map['splits'] as List? ?? [])
          .map((x) => TransactionSplit.fromMap(x as Map<String, dynamic>))
          .toList(),
      isEdited: map['isEdited'] ?? false,
      reference: map['reference'],
      bankId: map['bankId'],
      paymentMethodId: map['paymentMethodId'],
    );
  }

  TransactionModel copyWith({
    String? id,
    double? amount,
    String? merchant,
    DateTime? date,
    TransactionType? type,
    String? category,
    String? subcategory,
    String? rawSms,
    List<TransactionSplit>? splits,
    bool? isEdited,
    String? reference,
    String? bankId,
    String? paymentMethodId,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      merchant: merchant ?? this.merchant,
      date: date ?? this.date,
      type: type ?? this.type,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      rawSms: rawSms ?? this.rawSms,
      splits: splits ?? this.splits,
      isEdited: isEdited ?? this.isEdited,
      reference: reference ?? this.reference,
      bankId: bankId ?? this.bankId,
      paymentMethodId: paymentMethodId ?? this.paymentMethodId,
    );
  }
}

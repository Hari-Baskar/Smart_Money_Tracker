import 'package:uuid/uuid.dart';

enum BudgetPeriod { monthly, weekly, yearly, custom }

class BudgetModel {
  final String id;
  final String name;
  final double amount;
  final String? categoryId; // If null, applies to overall spending
  final String? subcategoryId; // If null, applies to the whole category
  final BudgetPeriod period;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isStopped;
  final bool isRecurring;
  final DateTime createdAt;

  BudgetModel({
    String? id,
    required this.name,
    required this.amount,
    this.categoryId,
    this.subcategoryId,
    this.period = BudgetPeriod.monthly,
    this.startDate,
    this.endDate,
    this.isStopped = false,
    this.isRecurring = true,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'categoryId': categoryId,
      'subcategoryId': subcategoryId,
      'period': period.name,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'isStopped': isStopped ? 1 : 0,
      'isRecurring': isRecurring ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory BudgetModel.fromMap(Map<String, dynamic> map) {
    return BudgetModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      categoryId: map['categoryId'],
      subcategoryId: map['subcategoryId'],
      period: BudgetPeriod.values.firstWhere(
        (e) => e.name == map['period'],
        orElse: () => BudgetPeriod.monthly,
      ),
      startDate: map['startDate'] != null ? DateTime.parse(map['startDate']) : null,
      endDate: map['endDate'] != null ? DateTime.parse(map['endDate']) : null,
      isStopped: map['isStopped'] == 1 || map['isStopped'] == true,
      isRecurring: map['isRecurring'] == null ? true : (map['isRecurring'] == 1 || map['isRecurring'] == true),
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now(),
    );
  }

  BudgetModel copyWith({
    String? id,
    String? name,
    double? amount,
    String? categoryId,
    bool clearCategoryId = false,
    String? subcategoryId,
    bool clearSubcategoryId = false,
    BudgetPeriod? period,
    DateTime? startDate,
    bool clearStartDate = false,
    DateTime? endDate,
    bool clearEndDate = false,
    bool? isStopped,
    bool? isRecurring,
    DateTime? createdAt,
  }) {
    return BudgetModel(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      categoryId: clearCategoryId ? null : (categoryId ?? this.categoryId),
      subcategoryId: clearSubcategoryId ? null : (subcategoryId ?? this.subcategoryId),
      period: period ?? this.period,
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      isStopped: isStopped ?? this.isStopped,
      isRecurring: isRecurring ?? this.isRecurring,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

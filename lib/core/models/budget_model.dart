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
  }) : id = id ?? const Uuid().v4();

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
    );
  }

  BudgetModel copyWith({
    String? id,
    String? name,
    double? amount,
    String? categoryId,
    String? subcategoryId,
    BudgetPeriod? period,
    DateTime? startDate,
    DateTime? endDate,
    bool? isStopped,
    bool? isRecurring,
  }) {
    return BudgetModel(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      subcategoryId: subcategoryId ?? this.subcategoryId,
      period: period ?? this.period,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isStopped: isStopped ?? this.isStopped,
      isRecurring: isRecurring ?? this.isRecurring,
    );
  }
}

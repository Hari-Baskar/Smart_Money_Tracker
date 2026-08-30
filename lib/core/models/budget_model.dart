import 'package:uuid/uuid.dart';

enum BudgetPeriod { monthly, weekly, yearly, custom }

class BudgetModel {
  final String id;
  final String name;
  final double amount;
  final String? categoryId; // If null, applies to overall spending
  final BudgetPeriod period;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isStopped;

  BudgetModel({
    String? id,
    required this.name,
    required this.amount,
    this.categoryId,
    this.period = BudgetPeriod.monthly,
    this.startDate,
    this.endDate,
    this.isStopped = false,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'categoryId': categoryId,
      'period': period.name,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'isStopped': isStopped ? 1 : 0,
    };
  }

  factory BudgetModel.fromMap(Map<String, dynamic> map) {
    return BudgetModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      categoryId: map['categoryId'],
      period: BudgetPeriod.values.firstWhere(
        (e) => e.name == map['period'],
        orElse: () => BudgetPeriod.monthly,
      ),
      startDate: map['startDate'] != null ? DateTime.parse(map['startDate']) : null,
      endDate: map['endDate'] != null ? DateTime.parse(map['endDate']) : null,
      isStopped: map['isStopped'] == 1 || map['isStopped'] == true,
    );
  }

  BudgetModel copyWith({
    String? id,
    String? name,
    double? amount,
    String? categoryId,
    BudgetPeriod? period,
    DateTime? startDate,
    DateTime? endDate,
    bool? isStopped,
  }) {
    return BudgetModel(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      period: period ?? this.period,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isStopped: isStopped ?? this.isStopped,
    );
  }
}

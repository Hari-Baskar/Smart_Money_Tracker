class BudgetInstanceModel {
  final String id;
  final String budgetId;
  final double amount;
  final DateTime startDate;
  final DateTime endDate;
  final bool isOverridden;
  final bool isStopped;
  final DateTime createdAt;

  BudgetInstanceModel({
    String? id,
    required this.budgetId,
    required this.amount,
    required this.startDate,
    required this.endDate,
    this.isOverridden = false,
    this.isStopped = false,
    DateTime? createdAt,
  })  : id = id ?? generateId(budgetId, startDate),
        createdAt = createdAt ?? DateTime.now();

  static String generateId(String budgetId, DateTime startDate) {
    return "${budgetId}_${startDate.year}_${startDate.month.toString().padLeft(2, '0')}_${startDate.day.toString().padLeft(2, '0')}";
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'budgetId': budgetId,
      'amount': amount,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'isOverridden': isOverridden ? 1 : 0,
      'isStopped': isStopped ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory BudgetInstanceModel.fromMap(Map<String, dynamic> map) {
    return BudgetInstanceModel(
      id: map['id'] ?? '',
      budgetId: map['budgetId'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      startDate: map['startDate'] != null
          ? DateTime.parse(map['startDate'])
          : DateTime.now(),
      endDate: map['endDate'] != null
          ? DateTime.parse(map['endDate'])
          : DateTime.now(),
      isOverridden: map['isOverridden'] == 1 || map['isOverridden'] == true,
      isStopped: map['isStopped'] == 1 || map['isStopped'] == true,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }

  BudgetInstanceModel copyWith({
    String? id,
    String? budgetId,
    double? amount,
    DateTime? startDate,
    DateTime? endDate,
    bool? isOverridden,
    bool? isStopped,
    DateTime? createdAt,
  }) {
    return BudgetInstanceModel(
      id: id ?? this.id,
      budgetId: budgetId ?? this.budgetId,
      amount: amount ?? this.amount,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isOverridden: isOverridden ?? this.isOverridden,
      isStopped: isStopped ?? this.isStopped,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

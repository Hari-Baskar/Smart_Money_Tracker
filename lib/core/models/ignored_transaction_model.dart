class IgnoredTransactionModel {
  final String id;
  final String rawSms;
  final DateTime date;
  final double amount;
  final String merchant;

  IgnoredTransactionModel({
    required this.id,
    required this.rawSms,
    required this.date,
    required this.amount,
    required this.merchant,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'rawSms': rawSms,
      'date': date.toIso8601String(),
      'amount': amount,
      'merchant': merchant,
    };
  }

  factory IgnoredTransactionModel.fromMap(Map<String, dynamic> map) {
    return IgnoredTransactionModel(
      id: map['id'] ?? '',
      rawSms: map['rawSms'] ?? '',
      date: DateTime.parse(map['date']),
      amount: (map['amount'] ?? 0.0).toDouble(),
      merchant: map['merchant'] ?? '',
    );
  }
}

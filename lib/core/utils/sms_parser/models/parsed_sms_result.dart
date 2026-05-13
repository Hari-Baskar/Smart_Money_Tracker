class ParsedSmsResult {
  final double? amount;
  final String? merchant;
  final String? category;
  final String? reference;
  final DateTime? date;
  final String? type; // debit/credit
  final double confidenceScore;
  final bool isAiFallback;

  ParsedSmsResult({
    this.amount,
    this.merchant,
    this.category,
    this.reference,
    this.date,
    this.type,
    this.confidenceScore = 0.0,
    this.isAiFallback = false,
  });
}

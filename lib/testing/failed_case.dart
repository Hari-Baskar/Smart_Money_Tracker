class FailedCase {
  final String originalSms;
  final String mutatedSms;
  final bool expected;
  final bool actual;
  final List<String> appliedMutations;

  FailedCase({
    required this.originalSms,
    required this.mutatedSms,
    required this.expected,
    required this.actual,
    required this.appliedMutations,
  });

  Map<String, dynamic> toJson() {
    return {
      'originalSms': originalSms,
      'mutatedSms': mutatedSms,
      'expected': expected,
      'actual': actual,
      'appliedMutations': appliedMutations,
    };
  }

  factory FailedCase.fromJson(Map<String, dynamic> json) {
    return FailedCase(
      originalSms: json['originalSms'],
      mutatedSms: json['mutatedSms'],
      expected: json['expected'],
      actual: json['actual'],
      appliedMutations: List<String>.from(json['appliedMutations']),
    );
  }
}

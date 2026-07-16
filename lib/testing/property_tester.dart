import 'dart:math';
import '../core/utils/sms_parser/engines/financial_detector.dart';
import 'failed_case.dart';
import 'sms_mutator.dart';

class PropertyTester {
  final SmsMutator mutator;
  final Random random;
  
  int totalTested = 0;
  int passed = 0;
  int failed = 0;
  List<FailedCase> failedCases = [];

  PropertyTester({required this.mutator, int? seed}) 
    : random = Random(seed ?? DateTime.now().millisecondsSinceEpoch);

  void runTests(String originalSms, bool expected, int mutationsPerMessage) {
    // Generate mutations
    final mutatedData = mutator.generateMutations(originalSms, mutationsPerMessage, random);

    for (var entry in mutatedData.entries) {
      String mutatedText = entry.key;
      List<String> rulesApplied = entry.value;

      totalTested++;
      bool actual = FinancialDetector.isFinancialSms(mutatedText, 'TEST_SENDER');

      if (actual == expected) {
        passed++;
      } else {
        failed++;
        failedCases.add(FailedCase(
          originalSms: originalSms,
          mutatedSms: mutatedText,
          expected: expected,
          actual: actual,
          appliedMutations: rulesApplied,
        ));
      }
    }
  }
}

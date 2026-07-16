import 'dart:convert';
import 'dart:io';
import 'property_tester.dart';

class ReportGenerator {
  static void printConsoleReport(PropertyTester tester, int totalOriginals, int mutationsPerMessage) {
    double accuracy = (tester.passed / tester.totalTested) * 100;

    print('\n=======================================');
    print(' MUTATION TESTING REPORT');
    print('=======================================');
    print('Total Original Messages : $totalOriginals');
    print('Mutations Per Message   : $mutationsPerMessage');
    print('---------------------------------------');
    print('Total Tested            : ${tester.totalTested}');
    print('Passed                  : ${tester.passed}');
    print('Failed                  : ${tester.failed}');
    print('Accuracy                : ${accuracy.toStringAsFixed(2)}%');
    print('=======================================\n');
  }

  static void saveFailedCases(PropertyTester tester, String outputPath) {
    if (tester.failedCases.isEmpty) {
      print('No failed cases to save.');
      return;
    }

    List<Map<String, dynamic>> jsonList = tester.failedCases.map((f) => f.toJson()).toList();
    File file = File(outputPath);
    // Format JSON with indent for readability
    String jsonString = const JsonEncoder.withIndent('  ').convert(jsonList);
    file.writeAsStringSync(jsonString);
    
    print('Saved ${tester.failedCases.length} failed cases to $outputPath');
  }
}

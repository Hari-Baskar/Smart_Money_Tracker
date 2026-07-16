import 'dart:convert';
import 'dart:io';
import 'sms_mutator.dart';
import 'property_tester.dart';
import 'report_generator.dart';

void main() {
  final file = File('assets/tests/original_sms.json');
  if (!file.existsSync()) {
    print('Test dataset not found at ${file.path}');
    return;
  }

  String content = file.readAsStringSync();
  List<dynamic> jsonList = jsonDecode(content);

  final mutator = SmsMutator();
  // Using a deterministic seed so reruns are perfectly reproducible 
  // (unless you change the rules or seed)
  final tester = PropertyTester(mutator: mutator, seed: 42);

  int mutationsPerMessage = 1000;

  print('Starting mutation testing...');
  for (var item in jsonList) {
    String original = item['message'];
    bool expected = item['expectedTransaction'];
    tester.runTests(original, expected, mutationsPerMessage);
  }

  ReportGenerator.printConsoleReport(tester, jsonList.length, mutationsPerMessage);
  ReportGenerator.saveFailedCases(tester, 'lib/testing/failed_cases.json');
}

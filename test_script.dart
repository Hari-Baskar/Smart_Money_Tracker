import 'dart:io';
import 'package:smart_money_tracker/core/utils/sms_parser.dart';

void main() async {
  final sms = 'Rs.8000.00 Credited to SB-xxx7502 AcBal:17438.83 CLRBal: 17438.83 [NEFT-UTIB- ] MARUNGAPURI on 09-06-2026 17:06:21.IOB.';
  final result = await SmsParser.parse(sms, 'VM-IOBMSG', date: DateTime.now());
  
  if (result != null) {
    print('SUCCESS!');
    print('Amount: ${result.amount}');
    print('Type: ${result.type}');
    print('Merchant: ${result.merchant}');
    print('Category: ${result.category}');
    print('Reference: ${result.reference}');
  } else {
    print('FAILED! Result is null');
  }
  exit(0);
}

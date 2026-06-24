import 'package:flutter_test/flutter_test.dart';
import 'package:smart_money_tracker/core/utils/sms_parser.dart';

void main() {
  test('Parses IOB Credit SMS correctly', () async {
    final sms = 'Rs.8000.00 Credited to SB-xxx7502 AcBal:17438.83 CLRBal: 17438.83 [NEFT-UTIB- ] MARUNGAPURI on 09-06-2026 17:06:21.IOB.';
    final result = await SmsParser.parse(sms, 'VM-IOBMSG', date: DateTime.now());
    
    expect(result, isNotNull);
    expect(result!.amount, 8000.0);
    expect(result.merchant, 'MARUNGAPURI');
  });

  test('Parses IOB Debit SMS with payee correctly', () async {
    final sms = 'Your a/c XXXXX02 debited for payee Mr Raman Periyasamy for Rs. 80.00 on 2026-05-09, ref 649581258929.If not you, report to your bank immediately-IOB.';
    final result = await SmsParser.parse(sms, 'BT-IOBCHN-S', date: DateTime.now());
    
    expect(result, isNotNull);
    expect(result!.amount, 80.0);
    expect(result.merchant, 'Raman Periyasamy');
    expect(result.reference, '649581258929');
  });

  test('Parses IOB Debit SMS with direct payee correctly', () async {
    final sms = 'payee Pollachi Pazhamuthir Nilayam for Rs. 27.00 on 2026-05-04, ref 122599502578.If not you, report to your bank immediately-IOB.';
    final result = await SmsParser.parse(sms, 'BT-IOBCHN-S', date: DateTime.now());
    
    expect(result, isNotNull);
    expect(result!.amount, 27.0);
    expect(result.merchant, 'Pollachi Pazhamuthir Nilayam');
    expect(result.reference, '122599502578');
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_money_tracker/core/utils/sms_parser.dart';

void main() {
  test('Parses IOB Credit SMS correctly', () async {
    final sms = 'Rs.8000.00 Credited to SB-xxx7502 AcBal:17438.83 CLRBal: 17438.83 [NEFT-UTIB- ] MARUNGAPURI on 09-06-2026 17:06:21.IOB.';
    final result = await SmsParser.parse(sms, 'VM-IOBMSG', date: DateTime.now());
    
    expect(result, isNotNull);
    expect(result!.amount, 8000.0);
  });

  test('Parses IOB Debit SMS with payee correctly', () async {
    final sms = 'Your a/c XXXXX02 debited for payee Mr Raman Periyasamy for Rs. 80.00 on 2026-05-09, ref 649581258929.If not you, report to your bank immediately-IOB.';
    final result = await SmsParser.parse(sms, 'BT-IOBCHN-S', date: DateTime.now());
    
    expect(result, isNotNull);
    expect(result!.amount, 80.0);
    expect(result.merchant, 'MR RAMAN PERIYASAMY');
    expect(result.reference, '649581258929');
  });

  test('Parses IOB Debit SMS with direct payee correctly', () async {
    final sms = 'payee Pollachi Pazhamuthir Nilayam for Rs. 27.00 on 2026-05-04, ref 122599502578.If not you, report to your bank immediately-IOB.';
    final result = await SmsParser.parse(sms, 'BT-IOBCHN-S', date: DateTime.now());
    
    expect(result, isNotNull);
    expect(result!.amount, 27.0);
    expect(result.merchant, 'POLLACHI PAZHAMUTHIR NILAYAM');
    expect(result.reference, '122599502578');
  });

  test('Ignores UPI-Mandate and funds blocked SMS', () async {
    final sms = 'Your UPI-Mandate is successfully created towards JioHotstar for Rs.149.00. Funds are blocked from A/C No. ##AccNum##.bb50e138c5fc46b99a4171a5ad777 - IOB Bank';
    final result = await SmsParser.parse(sms, 'BT-IOBCHN-S', date: DateTime.now());
    
    expect(result, isNull);
  });

  test('Ignores Cult.fit order awaiting confirmation SMS', () async {
    final sms = 'Dear customer, your payment of Rs.10690 for your cult.fit order is awaiting confirmation. Typically, it takes 5-10 minutes. Thank you for your patience!';
    final result = await SmsParser.parse(sms, 'JM-CULTFT', date: DateTime.now());
    
    expect(result, isNull);
  });

  test('Parses IOB Debit SMS with [UPI/129528 ] reference correctly', () async {
    final sms = 'Rs.10690.00 Debited to SB-xxx7502 AcBal:10361.04 CLRBal: 10361.04 [UPI/129528 ] MARUNGAPURI on 13-09-2026 12:13:07.IOB.';
    final result = await SmsParser.parse(sms, 'VM-IOBMSG', date: DateTime.now());
    
    expect(result, isNotNull);
    expect(result!.amount, 10690.0);
    expect(result.reference, '129528');
  });

  test('Parses IOB Debit SMS with payee DIVERSE RETAIL PVT LTD correctly', () async {
    final sms = 'Your a/c XXXXX02 debited for payee DIVERSE RETAIL PVT LTD for Rs. 10690.00 on 2026-09-13, ref 129528768255.If not you, report to your bank immediately-IOB.';
    final result = await SmsParser.parse(sms, 'BT-IOBCHN-S', date: DateTime.now());
    
    expect(result, isNotNull);
    expect(result!.amount, 10690.0);
    expect(result.merchant, 'DIVERSE RETAIL PVT LTD');
    expect(result.reference, '129528768255');
  });
}


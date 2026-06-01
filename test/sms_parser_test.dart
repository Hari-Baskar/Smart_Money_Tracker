import 'package:flutter_test/flutter_test.dart';
import 'package:smart_money_tracker/core/utils/sms_parser/engines/financial_detector.dart';
import 'package:smart_money_tracker/core/utils/sms_parser.dart';

void main() {
  group('Cheque Clearing SMS Filtering Tests', () {
    const chequeSms1 = 'Dear Customer, Cheque No. 2025560 for Rs. 100000, favouring T NAGAR COOP BANK, has been presented in your A/c No. XXXXXXXX0050 for clearing today. Please use our Positive Pay system to secure the payment. If not you, call 1800 2333.-Union Bank of India';
    const chequeSms2 = 'Dear Customer, Cheque No. 2025560 for Rs. 100000, favouring T NAGAR COOP BANK, has been presented in your A/c No. XXXXXXXX0050 for clearing today.';
    const sender = 'AD-UBIOIN';

    test('FinancialDetector should identify cheque clearing as a non-financial/junk SMS and filter it out', () {
      final isFinancial1 = FinancialDetector.isFinancialSms(chequeSms1.toLowerCase(), sender);
      expect(isFinancial1, isFalse);

      final isFinancial2 = FinancialDetector.isFinancialSms(chequeSms2.toLowerCase(), sender);
      expect(isFinancial2, isFalse);
    });

    test('SmsParser should return null (ignore) for cheque clearing warnings', () async {
      final transaction1 = await SmsParser.parse(chequeSms1, sender);
      expect(transaction1, isNull);

      final transaction2 = await SmsParser.parse(chequeSms2, sender);
      expect(transaction2, isNull);
    });
  });

  group('KVB NEFT Amount Parsing Tests', () {
    const String sms1 = 'A/c X2771 Debited INR 60,000.00 on 30-May-26 19:13:46*NEFT DR-KVBLH00262586680-Karthik Ba*DLite.Avl Bal INR 29,626.51.Not you?,call 18005721916-KVB';
    const String sms2 = 'Your NEFT Transfer of INR: 60,000.00 from A/c No:XX12771 to Karthik Balaji Murugasan Ref No : KVBLH00262586680 is settled. Avl Bal INR 29,626.51 -KVB';
    const String sender = 'KVB-BANK';

    test('SmsParser should parse exactly 60,000.00 for both messages and ignore the available balance', () async {
      final txn1 = await SmsParser.parse(sms1, sender);
      expect(txn1, isNotNull);
      expect(txn1!.amount, equals(60000.0));

      final txn2 = await SmsParser.parse(sms2, sender);
      expect(txn2, isNotNull);
      expect(txn2!.amount, equals(60000.0));
    });
  });
}

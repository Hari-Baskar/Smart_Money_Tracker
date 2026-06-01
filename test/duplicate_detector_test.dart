import 'package:flutter_test/flutter_test.dart';
import 'package:smart_money_tracker/core/models/transaction_model.dart';
import 'package:smart_money_tracker/core/utils/sms_parser.dart';
import 'package:smart_money_tracker/core/utils/sms_parser/engines/duplicate_detector.dart';

void main() {
  group('Transaction Deduplication Tests', () {
    final date = DateTime(2026, 5, 30, 19, 13, 46);

    test('Identical Stable ID from different SMS templates of same NEFT transaction', () async {
      // Debit SMS template
      const debitSms = 'A/c X2771 Debited INR 60,000.00 on 30-May-26 19:13:46*NEFT DR-KVBLH00262586680-Karthik Ba*DLite.Avl Bal INR 29,626.51.Not you?,call 18005721916-KVB';
      
      // Settlement SMS template
      const settlementSms = 'Your NEFT Transfer of INR: 60,000.00 from A/c No:XX12771 to Karthik Balaji Murugasan Ref No : KVBLH00262586680 is settled. Avl Bal INR 29,626.51 -KVB';

      final tx1 = await SmsParser.parse(debitSms, 'KVB-ALERT', date: date);
      final tx2 = await SmsParser.parse(settlementSms, 'KVB-ALERT', date: date);

      expect(tx1, isNotNull);
      expect(tx2, isNotNull);

      // Verify that reference number is successfully extracted by both
      expect(tx1!.reference, 'KVBLH00262586680');
      expect(tx2!.reference, 'KVBLH00262586680');

      // Verify they produce identical deterministic stable IDs
      expect(tx1.id, 'txn_ref_KVBLH00262586680');
      expect(tx2.id, 'txn_ref_KVBLH00262586680');
      expect(tx1.id, tx2.id);
    });

    test('UPI Ref extraction and Stable ID generation', () async {
      const upiSms = 'Your a/c no. XXXXXX1234 has been debited by Rs. 500.00 on 2026-05-30 via UPI to John Doe. UPI Ref No 314567890123. Avl Bal Rs. 5000.00';

      final tx = await SmsParser.parse(upiSms, 'BANK-UPI', date: date);

      expect(tx, isNotNull);
      expect(tx!.reference, '314567890123');
      expect(tx.id, 'txn_ref_314567890123');
    });

    test('Fallback to hash ID when no reference is present', () async {
      const simpleSms = 'A/c X1234 debited by Rs. 200 on 30-May-26.';
      
      final tx = await SmsParser.parse(simpleSms, 'BANK', date: date);

      expect(tx, isNotNull);
      expect(tx!.reference, isNull);
      
      // Should generate standard hash ID
      expect(tx.id.startsWith('txn_'), isTrue);
      expect(tx.id.contains('ref_'), isFalse);
    });
  });
}

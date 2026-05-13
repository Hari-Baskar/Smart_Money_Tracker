import 'package:telephony/telephony.dart';
import 'dart:convert';

/// SCANNER TOOL (Reverted to Telephony)
class SmsScannerNew {
  final Telephony telephony = Telephony.instance;
  
  Future<List<SmsMessage>> getTodaysMessages() async {
    try {
      // Fetch all inbox messages
      List<SmsMessage> messages = await telephony.getInboxSms(
        columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
        sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.DESC)],
      );

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Filter for messages received today
      return messages.where((msg) {
        if (msg.date == null) return false;
        final msgDate = DateTime.fromMillisecondsSinceEpoch(msg.date!);
        return msgDate.isAfter(today);
      }).toList();
    } catch (e) {
      print('Error reading SMS: $e');
      return [];
    }
  }

  Map<String, dynamic>? parseMessage(String body, String sender) {
    final text = body.toLowerCase();

    // 1. Flexible Amount Extraction
    final amountRegex = RegExp(r'(?:rs\.?|inr|₹)\s*([0-9,]+\.?[0-9]*)', caseSensitive: false);
    final amountMatch = amountRegex.firstMatch(text);
    
    if (amountMatch == null) return null;
    
    double? amount = double.tryParse(amountMatch.group(1)!.replaceAll(',', ''));

    // 2. Flexible Merchant Extraction
    final merchantRegex = RegExp(
      r'(?:payee|paid to|sent to|to|at|towards)\s+(.*?)\s+(?:for\s+rs|on|at|via|ref|bal)', 
      caseSensitive: false
    );
    
    final merchantMatch = merchantRegex.firstMatch(body);
    String merchant = merchantMatch?.group(1)?.trim() ?? sender.replaceAll(RegExp(r'^[A-Z]{2}-'), '');

    return {
      'merchant': merchant,
      'amount': amount,
      'is_debit': text.contains('debited') || text.contains('spent') || text.contains('paid'),
    };
  }
}

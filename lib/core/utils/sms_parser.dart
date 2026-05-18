import '../models/transaction_model.dart';
import 'sms_parser/models/parsed_sms_result.dart';
import 'sms_parser/engines/text_normalizer.dart';
import 'sms_parser/engines/financial_detector.dart';
import 'sms_parser/engines/rule_extraction_engine.dart';
import 'sms_parser/engines/merchant_normalizer.dart';
import 'sms_parser/engines/categorization_system.dart';
import 'sms_parser/engines/confidence_engine.dart';
import 'sms_parser/engines/duplicate_detector.dart';
import 'sms_parser/services/ai_fallback_service.dart';

class SmsParser {
  static Future<TransactionModel?> parse(String smsBody, String sender, {DateTime? date}) async {
    final normalizedBody = TextNormalizer.normalize(smsBody);

    // 1. Initial Quick Filter (Pre-AI)
    // If it's obviously an OTP or obviously a Credit, reject immediately to save AI tokens
    if (!FinancialDetector.isFinancialSms(normalizedBody, sender)) {
      return null;
    }

    // 2. Comprehensive AI Verification & Extraction
    final aiResult = await AiFallbackService.parseWithAi(smsBody);

    double? amount;
    String merchant = 'Bank Transaction';
    String type = 'debit';
    String category = 'Unknown';

    if (aiResult != null) {
      type = aiResult['type']?.toString().toLowerCase() ?? 'debit';
      if (type == 'junk') return null; // AI specifically rejected it
      
      amount = aiResult['amount']?.toDouble();
      merchant = aiResult['merchant']?.toString() ?? 'OTHER';
      category = aiResult['category']?.toString() ?? 'Unknown';
    }

    // 2.1 Override AI with local keyword check for robustness (The "Safety Net")
    // If we see strong credit keywords, force it to credit regardless of AI
    final creditKeywords = ['credited', 'received', 'added', 'deposited', 'refund', 'cashback'];
    final lowerBody = normalizedBody.toLowerCase();
    if (creditKeywords.any((kw) => lowerBody.contains(kw))) {
      type = 'credit';
    }

    // 3. Local Regex Fallback for Amount if AI failed
    if (amount == null || amount <= 0) {
      // Regex to find amounts like Rs. 80.00, Rs 280, INR 500
      final amountRegex = RegExp(r'(?:rs\.?|inr|₹)\s*([0-9,]+\.?[0-9]*)', caseSensitive: false);
      final match = amountRegex.firstMatch(smsBody);
      if (match != null && match.groupCount >= 1) {
        String amountStr = match.group(1)!.replaceAll(',', '');
        amount = double.tryParse(amountStr);
      }
    }

    if (amount == null || amount <= 0) return null; // Still couldn't find amount

    // Normalize "OTHER" or generic bank junk instead of rejecting
    if (merchant == 'OTHER' || 
        merchant == 'UNKNOWN' ||
        merchant.contains('YOUR BANK') || 
        merchant == 'Bank Transaction' ||
        merchant.length < 2) {
      
      // Attempt local extraction from body using common patterns
      String? extracted = _extractMerchantFromBody(smsBody);
      
      if (extracted != null) {
        merchant = extracted;
      } else if (sender.length > 2 && !sender.contains('.')) {
        // Fallback to sender ID (e.g. HDFCBK)
        merchant = sender.contains('-') ? sender.split('-').last : sender;
      } else {
        merchant = 'Bank Transaction';
      }
    }
    
    merchant = MerchantNormalizer.normalize(merchant, sender);

    if (category == 'Unknown' || category == 'Other') {
       // Local categorization as backup if AI is generic
       category = CategorizationSystem.categorize(merchant, normalizedBody);
    }

    // 5. Reference Number
    final reference = aiResult?['reference']?.toString();

    // 6. Duplicate Transaction Detector
    final stableId = DuplicateDetector.generateStableId(smsBody, date, amount);

    return TransactionModel(
      id: stableId,
      amount: amount,
      merchant: merchant,
      date: date ?? DateTime.now(),
      type: type == 'credit' ? TransactionType.credit : TransactionType.debit,
      category: category,
      rawSms: smsBody,
    );
  }

  static String? _extractMerchantFromBody(String body) {
    String? extractPattern(String pattern) {
      final match = RegExp(pattern, caseSensitive: false).firstMatch(body);
      if (match != null) {
        String name = match.group(1)?.trim() ?? '';
        
        // Stop at common connecting words or punctuation
        final stopWords = [' on ', ' via ', ' ref ', ' txn ', ' avail ', ' available '];
        for (final stop in stopWords) {
          final idx = name.toLowerCase().indexOf(stop);
          if (idx != -1) {
            name = name.substring(0, idx).trim();
          }
        }
        
        if (name.isNotEmpty && !_isGenericWord(name)) return name;
      }
      return null;
    }

    // Try common patterns
    String? result = extractPattern(r'paid to\s+([A-Za-z0-9\s&]{3,20})');
    result ??= extractPattern(r'sent to\s+([A-Za-z0-9\s&]{3,20})');
    result ??= extractPattern(r'to\s+([A-Za-z0-9\s&]{3,20})');
    result ??= extractPattern(r'at\s+([A-Za-z0-9\s&]{3,20})');
    result ??= extractPattern(r'for\s+([A-Za-z0-9\s&]{3,20})');

    return result;
  }

  static bool _isGenericWord(String word) {
    final lower = word.toLowerCase();
    if (lower.contains('your bank') || 
        lower.contains('account') || 
        lower.contains('card') || 
        lower.contains('immediately') || 
        lower.contains('balance') ||
        lower.length < 3) {
      return true;
    }
    return false;
  }
}




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
import 'sms_parser/engines/payment_detector.dart';

class SmsParser {
  static Future<TransactionModel?> parse(String smsBody, String sender, {DateTime? date}) async {
    final normalizedBody = TextNormalizer.normalize(smsBody);

    // 1. Initial Quick Filter (Pre-AI)
    // If it's obviously an OTP or non-financial message, reject immediately
    if (!FinancialDetector.isFinancialSms(normalizedBody, sender)) {
      return null;
    }

    // 2. High-Speed Local Regex Extraction First (0 Cost, Instant)
    final localAmount = RuleExtractionEngine.extractAmount(normalizedBody);
    final localType = RuleExtractionEngine.extractType(normalizedBody);
    final localReference = RuleExtractionEngine.extractReference(normalizedBody) ?? _extractReferenceNumber(smsBody);
    final localMerchantRaw = RuleExtractionEngine.extractMerchant(normalizedBody, sender);

    double? amount = localAmount;
    String type = localType;
    String? reference = localReference;
    String merchant = 'Bank Transaction';
    String category = 'Unknown';

    // A high-confidence local match has:
    // - A valid amount > 0
    // - A clear transaction type (debit or credit)
    // - EITHER a reference number (UPI Ref / UTR) OR a specific extracted merchant
    bool isLocalSuccess = amount != null && amount > 0 && type != 'unknown' && 
        ((reference != null && reference.length >= 4) || (localMerchantRaw != null && localMerchantRaw.length > 2));

    if (isLocalSuccess) {
      // 2.1 Clean and normalize merchant name locally
      String rawMerchant = localMerchantRaw ?? 'Bank Transaction';
      rawMerchant = rawMerchant.trim();
      final bareHonorific = RegExp(r'^(MS|MR|DR|CR)$', caseSensitive: false);

      if (rawMerchant == 'OTHER' || 
          rawMerchant == 'UNKNOWN' ||
          rawMerchant.contains('YOUR BANK') || 
          rawMerchant == 'Bank Transaction' ||
          rawMerchant.length < 2 ||
          bareHonorific.hasMatch(rawMerchant)) {
        
        String? extracted = _extractMerchantFromBody(smsBody);
        if (extracted != null) {
          merchant = extracted;
        } else if (sender.length > 2 && !sender.contains('.')) {
          merchant = sender.contains('-') ? sender.split('-').last : sender;
        } else {
          merchant = 'Bank Transaction';
        }
      } else {
        merchant = rawMerchant;
      }

      merchant = MerchantNormalizer.normalize(merchant, sender);

      // Categorize locally
      category = CategorizationSystem.categorize(merchant, normalizedBody);
    } else {
      // 3. Fallback to Gemini AI for complex, noisy, or multi-lingual SMS messages
      final aiResult = await AiFallbackService.parseWithAi(smsBody);

      if (aiResult != null) {
        final aiType = aiResult['type']?.toString().toLowerCase() ?? 'debit';
        if (aiType == 'junk') return null; // AI specifically rejected it
        
        type = aiType;
        amount = aiResult['amount']?.toDouble() ?? amount;
        merchant = aiResult['merchant']?.toString() ?? merchant;
        category = aiResult['category']?.toString() ?? category;
        reference = aiResult['reference']?.toString() ?? reference;
      } else {
        // AI is offline/errored, fallback to whatever we managed to grab locally
        if (amount == null || amount <= 0) {
          return null; // Reject if we couldn't even extract the amount
        }
        if (type == 'unknown') {
          type = 'debit'; // Fallback to debit
        }
      }
    }

    if (amount == null || amount <= 0) return null;

    // Final normalization checks for merchant name
    merchant = merchant.trim();
    final bareHonorific = RegExp(r'^(MS|MR|DR|CR)$', caseSensitive: false);
    if (merchant == 'OTHER' || 
        merchant == 'UNKNOWN' ||
        merchant.contains('YOUR BANK') || 
        merchant == 'Bank Transaction' ||
        merchant.length < 2 ||
        bareHonorific.hasMatch(merchant)) {
      
      String? extracted = _extractMerchantFromBody(smsBody);
      if (extracted != null) {
        merchant = extracted;
      } else if (sender.length > 2 && !sender.contains('.')) {
        merchant = sender.contains('-') ? sender.split('-').last : sender;
      } else {
        merchant = 'Bank Transaction';
      }
    }
    
    merchant = MerchantNormalizer.normalize(merchant, sender);

    if (category == 'Unknown' || category == 'Other') {
       category = CategorizationSystem.categorize(merchant, normalizedBody);
    }

    if (reference != null) {
      reference = reference.trim().toUpperCase();
    }

    // 4. Generate stable duplicate-proof ID using our Indian market hierarchy
    final stableId = DuplicateDetector.generateStableId(
      smsBody,
      date,
      amount,
      reference: reference,
      merchant: merchant,
      type: type,
    );

    final autoBankId = PaymentDetector.detectBank(sender, normalizedBody);
    final autoPaymentMethodId = PaymentDetector.detectPaymentMethod(sender, normalizedBody);

    return TransactionModel(
      id: stableId,
      amount: amount,
      merchant: merchant,
      date: date ?? DateTime.now(),
      type: type == 'credit' ? TransactionType.credit : TransactionType.debit,
      category: category,
      rawSms: smsBody,
      reference: reference,
      bankId: autoBankId,
      paymentMethodId: autoPaymentMethodId,
    );
  }

  static String? _extractReferenceNumber(String body) {
    // 1. Look for explicit reference label match
    // E.g. Ref No : KVBLH00262586680, upi ref no 123456, Ref: 12345
    final explicitRegex = RegExp(
      r'(?:ref(?:\s+no|\s+num)?\.?\s*:?|txn(?:\s+id)?\.?\s*:?|upi(?:\s+ref)?\.?\s*:?|reference(?:\s+no)?\.?\s*:?)\s*([a-z0-9]+)',
      caseSensitive: false,
    );
    final explicitMatch = explicitRegex.firstMatch(body);
    if (explicitMatch != null) {
      final ref = explicitMatch.group(1)?.trim();
      if (ref != null && ref.length >= 6) {
        return ref;
      }
    }

    // 2. Look for bank-specific patterns like DR-KVBLH... or Ref-KVBLH...
    final bankPatternRegex = RegExp(
      r'(?:dr|cr|ref|txn)-([a-z0-9]+)',
      caseSensitive: false,
    );
    final bankMatch = bankPatternRegex.firstMatch(body);
    if (bankMatch != null) {
      final ref = bankMatch.group(1)?.trim();
      if (ref != null && ref.length >= 6) {
        return ref;
      }
    }

    // 3. Fallback: search for long alphanumeric transaction references (e.g. KVBLH00262586680 or UTIBH...)
    // Banking references are typically 10-18 alphanumeric characters.
    final genericRegex = RegExp(
      r'\b([a-z]{4,5}[0-9]{6,15})\b',
      caseSensitive: false,
    );
    final genericMatch = genericRegex.firstMatch(body);
    if (genericMatch != null) {
      return genericMatch.group(1)?.trim();
    }

    // 4. UPI 12-digit transaction ID pattern
    final upi12Regex = RegExp(
      r'\b([0-9]{12})\b',
    );
    final upi12Match = upi12Regex.firstMatch(body);
    if (upi12Match != null) {
      return upi12Match.group(1)?.trim();
    }

    return null;
  }

  static String? _extractMerchantFromBody(String body) {
    String? extractPattern(String pattern) {
      final match = RegExp(pattern, caseSensitive: false).firstMatch(body);
      if (match != null) {
        String name = match.group(1)?.trim() ?? '';

        // Convert underscores used as word separators in bank-formatted names
        // e.g. MS_VIKRAANTH_AGENCYY_  →  MS VIKRAANTH AGENCYY
        name = name.replaceAll(RegExp(r'_+'), ' ').trim();

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

    // Payee pattern first — most specific, handles bank-formatted names like
    // "payee MS_VIKRAANTH_AGENCYY_" correctly, including underscore separators.
    String? result = extractPattern(
      r'payee\s+([A-Za-z0-9\s._\-&]{2,40}?)(?:\s+for(?:\s+rs\.?|\s+inr|\s+\d)|\s+on|\s+ref|$)',
    );
    result ??= extractPattern(r'favouring\s+([^,.\n]{3,30})');
    result ??= extractPattern(r'paid to\s+([A-Za-z0-9\s&]{3,30})');
    result ??= extractPattern(r'sent to\s+([A-Za-z0-9\s&]{3,30})');
    result ??= extractPattern(r'to\s+([A-Za-z0-9\s&]{3,30})');
    result ??= extractPattern(r'at\s+([A-Za-z0-9\s&]{3,30})');
    result ??= extractPattern(r'for\s+([A-Za-z0-9\s&]{3,30})');

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




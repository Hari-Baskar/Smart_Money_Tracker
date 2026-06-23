import 'dart:convert';
import 'package:crypto/crypto.dart';

class DuplicateDetector {
  static String generateStableId(
    String rawBody,
    DateTime? date,
    double amount, {
    String? reference,
    String merchant = 'UNKNOWN',
    String type = 'debit',
  }) {
    // 🥇 Level 1: Transaction Reference Number (UPI Ref / UTR / Ref No)
    if (reference != null && reference.trim().isNotEmpty) {
      final cleanedRef = reference.trim().toUpperCase();
      // Only use as deterministic ID if the reference number is substantial
      if (cleanedRef.length >= 4) {
        return 'txn_ref_$cleanedRef';
      }
    }

    // 🥈 Level 2: SMS Body Hash (For identical banker retries / duplicate message delivery)
    final bodyClean = rawBody.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
    final bytes = utf8.encode(bodyClean);
    final digest = sha256.convert(bytes);
    final bodyHash = digest.toString().substring(0, 16);

    if (date == null) {
      return 'txn_hash_$bodyHash';
    }

    // 🥉 Level 3: Fingerprint (Amount + Merchant + Type + Date truncated to day)
    // Prevents matching error for UPI micro-payments in rapid succession (tea, biscuit, parking)
    final dateString = "${date.year}-${date.month}-${date.day}";
    final cleanMerchant = merchant.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '');
    final fingerprintSource = "${amount.toInt()}|$cleanMerchant|${type.toLowerCase()}|$dateString";
    
    final fpBytes = utf8.encode(fingerprintSource);
    final fpDigest = sha256.convert(fpBytes);
    final fpHash = fpDigest.toString().substring(0, 16);

    return 'txn_fp_$fpHash';
  }
}

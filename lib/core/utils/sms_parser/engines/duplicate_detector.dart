import 'dart:convert';
import 'package:crypto/crypto.dart';

class DuplicateDetector {
  static String generateStableId(String rawBody, DateTime? date, double amount) {
    // Clean body to prevent minor formatting differences from causing duplicates
    final bodyClean = rawBody.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
    
    // Hash the message body for a deterministic ID
    final bytes = utf8.encode(bodyClean);
    final digest = sha256.convert(bytes);
    
    // Create composite key with timestamp (truncated to minute or hour if needed, but ms is fine since SMS exact time doesn't usually drift much for the same SMS), amount, and hash
    final timestamp = date?.millisecondsSinceEpoch ?? 0;
    return 'txn_${timestamp}_${amount.toInt()}_${digest.toString().substring(0, 16)}';
  }
}

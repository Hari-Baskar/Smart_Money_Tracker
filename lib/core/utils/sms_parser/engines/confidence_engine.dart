import '../models/parsed_sms_result.dart';

class ConfidenceEngine {
  static double calculateConfidence(ParsedSmsResult result) {
    double score = 0.0;
    
    // Amount is crucial for a transaction
    if (result.amount != null && result.amount! > 0) {
      score += 40.0;
    }
    
    // Knowing the merchant is highly important
    if (result.merchant != null && result.merchant != 'UNKNOWN') {
      score += 30.0;
    }
    
    // Direction of money flow
    if (result.type != null && result.type != 'unknown') {
      score += 15.0;
    }
    
    // Having a reference makes it a solid transaction
    if (result.reference != null) {
      score += 10.0;
    }
    
    // Date context
    if (result.date != null) {
      score += 5.0;
    }

    return score;
  }
}

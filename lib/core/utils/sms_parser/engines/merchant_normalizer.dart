class MerchantNormalizer {
  static String normalize(String? rawMerchant, String sender) {
    if (rawMerchant == null || rawMerchant.isEmpty || rawMerchant == 'OTHER' || rawMerchant == 'UNKNOWN' || rawMerchant.length <= 2) {
      return '-';
    }

    String clean = rawMerchant.toUpperCase().trim();
    
    // Remove quotes and common symbols that act as separators
    clean = clean.replaceAll(RegExp(r"""['"`´‘’“”\*_\-]+"""), ' ');
    
    // Clean up multiple spaces resulting from symbol replacement
    clean = clean.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    // Strip honorific prefixes only when followed by a single word (person name),
    // not for multi-word business names like MS VIKRAANTH AGENCYY
    final honorificPattern = RegExp(r'^(DR|CR|MR|MS)\s+(\S+)$');
    final honorificMatch = honorificPattern.firstMatch(clean);
    if (honorificMatch != null) {
      // It's a single-name person like "MS PRIYA" - strip the prefix
      clean = honorificMatch.group(2)!;
    }

    // Strip "PAYEE " and "MERCHANT " prefixes
    if (clean.startsWith('PAYEE ')) {
      clean = clean.substring(6).trim();
    } else if (clean.startsWith('MERCHANT ')) {
      clean = clean.substring(9).trim();
    }

    
    // Map known variants and verified businesses
    if (clean.contains('AMAZON')) return 'AMAZON';
    if (clean.contains('SWIGGY')) return 'SWIGGY';
    if (clean.contains('ZOMATO')) return 'ZOMATO';
    if (clean.contains('UBER')) return 'UBER';
    if (clean.contains('OLA')) return 'OLA';
    if (clean.contains('FLIPKART')) return 'FLIPKART';
    if (clean.contains('ZEPTO')) return 'ZEPTO';
    if (clean.contains('BLINKIT')) return 'BLINKIT';

    return clean;
  }

  // _extractFromSender removed as per user request to never store sender/location names
}


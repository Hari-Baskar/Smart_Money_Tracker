class MerchantNormalizer {
  static String normalize(String? rawMerchant, String sender) {
    if (rawMerchant == null || rawMerchant.isEmpty) {
      rawMerchant = _extractFromSender(sender);
    }
    
    if (rawMerchant == 'OTHER' || rawMerchant == 'UNKNOWN' || rawMerchant.length <= 2) return 'OTHER';

    String clean = rawMerchant.toUpperCase().trim();
    
    // Remove quotes and common symbols that act as separators
    clean = clean.replaceAll(RegExp(r"""['"`´‘’“”\*_\-]+"""), ' ');
    
    // Clean up multiple spaces resulting from symbol replacement
    clean = clean.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    // Specific cleanup for common prefixes
    if (clean.startsWith('DR ')) clean = clean.substring(3);
    if (clean.startsWith('CR ')) clean = clean.substring(3);
    if (clean.startsWith('MR ')) clean = clean.substring(3);
    if (clean.startsWith('MS ')) clean = clean.substring(3);

    
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

  static String _extractFromSender(String sender) {
    if (sender.length > 3) {
      String cleanSender = sender;
      if (sender.contains('-')) {
        cleanSender = sender.split('-').last;
      }
      final genericBanks = [
        'HDFCBK', 'ICICIB', 'SBIINB', 'KOTAKB', 'AXISBK', 
        'PAYTM', 'CANBK', 'PNBSMS', 'VODAFN', 'AIRTEL',
        'IDFCBK', 'BOIIND', 'IOBIND'
      ];
      
      if (!genericBanks.any((bank) => cleanSender.toUpperCase().contains(bank)) && cleanSender.length > 2) {
        return cleanSender.toUpperCase();
      }
    }
    return 'OTHER';
  }
}


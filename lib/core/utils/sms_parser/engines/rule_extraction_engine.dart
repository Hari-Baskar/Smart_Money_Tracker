class RuleExtractionEngine {
  static double? extractAmount(String text) {
    final patterns = [
      RegExp(r'(?:rs\.?|inr|amt|spent)\s*([\d,]+(?:\.\d{1,2})?)'),
      RegExp(r'debited\s*(?:by|for)?\s*(?:rs\.?)?\s*([\d,]+(?:\.\d{1,2})?)'),
      RegExp(r'credited\s*(?:with|by|for)?\s*(?:rs\.?)?\s*([\d,]+(?:\.\d{1,2})?)'),
      RegExp(r'(?:rs\.?)\s*([\d,]+(?:\.\d{1,2})?)\s*(?:debited|credited)'),
    ];

    for (var pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        String amtStr = match.group(1)!.replaceAll(',', '');
        return double.tryParse(amtStr);
      }
    }
    return null;
  }

  static String? extractMerchant(String text, String sender) {
    final patterns = [
      RegExp(r"""at\s+([a-z0-9\s*\.&'"-]+)(?:\.|\s+on|\s+ref|\s+using|$)"""),
      RegExp(r"""towards\s+([a-z0-9\s*\.&'"-]+)(?:\.|\s+on|\s+ref|\s+using|$)"""),
      RegExp(r"""vpa\s+([a-z0-9@\s*\.&'"-]+)(?:\.|\s+on|\s+ref|$)"""),
      RegExp(r"""to\s+([a-z0-9\s*\.&'"-]+)(?:\.|\s+on|\s+ref|$)"""),
      RegExp(r"""info:\s*([a-z0-9\s*\.&'"-]+)(?:\.|\s+on|\s+ref|$)"""),
      RegExp(r"""spent\s+on\s+([a-z0-9\s*\.&'"-]+)(?:\.|\s+on|\s+ref|$)"""),
      RegExp(r"""paid\s+to\s+([a-z0-9\s*\.&'"-]+)(?:\.|\s+on|\s+ref|$)"""),
      RegExp(r"""payee\s+([a-z0-9\s*\.&'"-]+)(?:\.|\s+for|\s+on|\s+ref|$)"""),
    ];

    for (var pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        String found = match.group(1)!.trim();
        if (found.endsWith(' on')) found = found.substring(0, found.length - 3);
        if (found.endsWith(' for rs')) found = found.substring(0, found.length - 7);
        if (found.length > 2) {
          return found;
        }
      }
    }
    return null;
  }

  static String extractType(String text) {
    final lower = text.toLowerCase();
    
    // Check for clear credit signals first
    bool hasClearCredit = false;
    if (['received', 'refund', 'cashback', 'deposited'].any((kw) => lower.contains(kw))) {
      hasClearCredit = true;
    }
    if (lower.contains('credited') && 
        !lower.contains('credited to payee') && 
        !lower.contains('credited to merchant') &&
        !lower.contains('credited to account of') &&
        !lower.contains('credited to a/c of')) {
      hasClearCredit = true;
    }
    if (lower.contains('added to wallet') || lower.contains('salary credited')) {
      hasClearCredit = true;
    }

    // Check for clear debit signals
    bool hasClearDebit = false;
    if (['spent', 'paid', 'withdrawn', 'sent to', 'debited'].any((kw) => lower.contains(kw))) {
      hasClearDebit = true;
    }

    if (hasClearCredit && !hasClearDebit) {
      return 'credit';
    } else if (hasClearDebit) {
      return 'debit';
    }
    return 'unknown';
  }

  static String? extractReference(String text) {
    final patterns = [
      RegExp(r'ref\s*(?:no\.?|num\.?)?\s*:?\s*([a-z0-9]+)'),
      RegExp(r'utr\s*(?:no\.?|num\.?)?\s*:?\s*([a-z0-9]+)'),
      RegExp(r'txn\s*(?:id|no\.?)?\s*:?\s*([a-z0-9]+)'),
    ];

    for (var pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return match.group(1)!.trim();
      }
    }
    return null;
  }
}

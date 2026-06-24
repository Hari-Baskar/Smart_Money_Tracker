class RuleExtractionEngine {
  static double? extractAmount(String text) {
    final lowerText = text.toLowerCase();
    final patterns = [
      RegExp(r'(?:rs\.?|inr|amt|spent)\s*:?\s*([\d,]+(?:\.\d{1,2})?)'),
      RegExp(r'debited\s*(?:by|for)?\s*(?:rs\.?)?\s*:?\s*([\d,]+(?:\.\d{1,2})?)'),
      RegExp(r'credited\s*(?:with|by|for)?\s*(?:rs\.?)?\s*:?\s*([\d,]+(?:\.\d{1,2})?)'),
      RegExp(r'(?:rs\.?)\s*:?\s*([\d,]+(?:\.\d{1,2})?)\s*(?:debited|credited)'),
    ];

    for (var pattern in patterns) {
      for (final match in pattern.allMatches(lowerText)) {
        final prefix = lowerText.substring(0, match.start);
        final lookback = prefix.substring(prefix.length > 30 ? prefix.length - 30 : 0);
        
        // Prevent matching "bal" inside names like "balaji" by using regex with word boundaries
        // and explicitly checking common balance acronyms like acbal, clrbal, avl bal.
        if (RegExp(r'\b(bal|balance)\b|acbal|clrbal|avl\s*bal|avail\s*bal').hasMatch(lookback)) {
          continue; // Skip available balance
        }
        String amtStr = match.group(1)!.replaceAll(',', '');
        final val = double.tryParse(amtStr);
        if (val != null && val > 0) {
          return val;
        }
      }
    }
    return null;
  }

  static String? extractMerchant(String text, String sender) {
    // If it's an ATM withdrawal, do not extract the location as the merchant
    if (text.toLowerCase().contains('atm withdrawal') || 
        text.toLowerCase().contains('cash withdrawal') || 
        text.toLowerCase().contains('[atm') || 
        text.toLowerCase().contains(' nfs ')) {
      return '-';
    }

    final patterns = [
      // Income/Credit Patterns
      RegExp(r"""received\s+from\s+([a-z0-9\s*\._\-&'"]+?)(?:\s+towards|\s+on|\s+ref|$)""", caseSensitive: false),
      RegExp(r"""credited\s+(?:by|from)\s+([a-z0-9\s*\._\-&'"]+?)(?:\s+on|\s+ref|$)""", caseSensitive: false),
      RegExp(r"""(?:received|credited|refunded)(?:.*?)?\bfrom\s+([a-z0-9\s*\._\-&'"]+?)(?:-[a-z0-9@!¡\-]+)?(?:\s+on|\s+ref|¡|\(|\[|$)""", caseSensitive: false),
      RegExp(r"""remitter\s*[:-]?\s*([a-z0-9\s*\._\-&'"]+?)(?:\s+on|\s+ref|$)""", caseSensitive: false),
      RegExp(r"""refund\s+from\s+([a-z0-9\s*\._\-&'"]+?)(?:\s+on|\s+ref|$)""", caseSensitive: false),
      
      // Expense/Debit Patterns
      RegExp(r"""favouring\s+([^,.\n]+)""", caseSensitive: false),
      RegExp(r"""vpa\s+([a-z0-9@\s*\.&'"-]+)(?:\.|\s+on|\s+ref|$)"""),
      RegExp(r"""paid\s+to\s+([a-z0-9\s*\.&'"-]+)(?:\.|\s+on|\s+ref|$)"""),
      // Payee pattern - includes underscores common in bank-formatted names (e.g. MS_VIKRAANTH_AGENCYY_)
      RegExp(r"""payee\s+([a-z0-9\s*\._\-&'"]+?)(?:\s+for(?:\s+rs\.?|\s+inr|\s+\d)|\s+on|\s+ref|$)""", caseSensitive: false),
    ];

    for (var pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        String found = match.group(1)!.trim();
        if (found.endsWith(' on')) found = found.substring(0, found.length - 3);
        if (found.endsWith(' for rs')) found = found.substring(0, found.length - 7);
        
        // Prevent extracting the amount as the merchant name (e.g., "rs.3000.00")
        final lowerFound = found.toLowerCase();
        final isAmount = lowerFound.startsWith('rs') || 
                         lowerFound.startsWith('inr') || 
                         RegExp(r'^[\d\.,]+$').hasMatch(found);
                         
        final isMaskedAccount = lowerFound.contains('xxx') || 
                                lowerFound.contains('***') ||
                                RegExp(r'(?:x|\*){2,}\d+').hasMatch(lowerFound) || 
                                RegExp(r'\d+(?:x|\*){2,}').hasMatch(lowerFound) ||
                                RegExp(r'\.{2,}\d+').hasMatch(lowerFound);
                         
        if (isAmount || isMaskedAccount) {
          continue; // It grabbed the amount or an account number, skip this pattern and try the next one
        }

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
    if (['received', 'refund', 'cashback', 'deposited', 'cr'].any((kw) => lower.contains(kw))) {
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
    if (['spent', 'paid', 'withdrawn', 'sent to', 'debited', 'payee', 'dr', 'withdrawal', 'pos', 'purchase', 'ecom'].any((kw) => lower.contains(kw))) {
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
      // Bracketed references (e.g. [OUD 022409] or [NEFT-UTIB-123])
      // Must contain at least one digit to avoid generic strings like [NEFT-UTIB- ] acting as a universal ID.
      RegExp(r'\[([a-z0-9\-\s]*\d[a-z0-9\-\s]*)\]', caseSensitive: false),
      RegExp(r'ref\s*(?:no\.?|num\.?|id)?\s*:?\s*([a-z0-9]+)', caseSensitive: false),
      RegExp(r'utr\s*(?:no\.?|num\.?)?\s*:?\s*([a-z0-9]+)', caseSensitive: false),
      RegExp(r'txn\s*(?:id|no\.?)?\s*:?\s*([a-z0-9]+)', caseSensitive: false),
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

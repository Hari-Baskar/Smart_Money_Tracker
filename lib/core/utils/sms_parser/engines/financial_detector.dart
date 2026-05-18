class FinancialDetector {
  static final Map<String, int> _keywords = {
    'debited': 10,
    'spent': 8,
    'paid': 8,
    'payed': 8,
    'sent': 8,
    'transferred': 8,
    'transfer': 7,
    'withdrawn': 8,
    'txn': 5,
    'upi': 5,
    'vpa': 5,
    'a/c': 4,
    'account': 4,
    'rs': 3,
    'towards': 4,
    'payment': 4,
    'transaction': 4,
    'ref': 3,
    'utr': 3,
  };

  static final List<String> _negativeKeywords = [
    'otp',
    'one time password',
    'verification code',
    'do not share',
    'security code',
    'promotional',
    'spam',
    'credited',
    'received',
    'deposited',
    'refund',
    'reward',
    'cashback',
    'balance enquiry',
    'declined',
    'failed',
    'insufficient funds',
    'credited to',
    'received from',
    'added to wallet',
    'collect request',
  ];

  static bool isFinancialSms(String normalizedSms, String sender) {
    final text = normalizedSms.toLowerCase();
    
    // 1. MUST have an amount indicator
    final hasAmountIndicator = text.contains('rs') || 
                               text.contains('inr') || 
                               text.contains('₹') || 
                               text.contains('amount');
    if (!hasAmountIndicator) return false;

    // 2. MUST be either a debit or a credit transaction
    final isCredit = [
      'credited', 'received', 'deposited', 'refund', 
      'reward', 'cashback', 'added to wallet', 'income', 'added'
    ].any((kw) => text.contains(kw));

    final hasDebitKeyword = [
      'debited', 'spent', 'paid', 'payed', 'sent', 
      'transferred', 'transfer', 'withdrawn', 'txn', 'payment', 
      'towards', 'vpa'
    ].any((kw) => text.contains(kw));
    
    if (!isCredit && !hasDebitKeyword) return false;

    // 3. MUST NOT be an OTP or Junk
    final isJunk = [
      'otp', 'one time password', 'verification code', 
      'security code', 'login', 'attempt'
    ].any((kw) => text.contains(kw));
    if (isJunk) return false;

    // 4. Exclude personal phone numbers (10+ digits)
    if (RegExp(r'^\+?[0-9]{10,}$').hasMatch(sender)) {
      return false;
    }

    return true; 
  }
}



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
    'balance enquiry',
    'available balance',
    'bal available',
    'declined',
    'failed',
    'cancelled',
    'canceled',
    'insufficient funds',
    'collect request',
    'requesting money',
    'requested rs',
    'presented for clearing',
    'for clearing today',
    'positive pay',
    'presented in your a/c',
    'recharge successful',
    'recharge of rs',
    'recharge done',
    'successful recharge',
    'plan activated',
    'pack activated',
    'recharge with',
    'recharge is successful',
    'up to rs',
    'up to ₹',
    'up to inr',
    'win up to',
    'earn up to',
    'get up to',
    'save up to',
    'earn laddoos',
    'earn rewards',
    'pre-approved',
    'pre approved',
    'scratch card',
    'scratchcard',
    'gift card',
    'gift voucher',
    'coupon code',
    'use code',
    'apply code',
    'offer valid',
    'valid till',
    'valid until',
    'exclusive offer',
    'special offer',
    'win cashback',
    'chance to win',
    'chance to get',
    'spin and win',
    'look out for',
    'hurry',
    'recharge now',
    'get flat',
    'congratulations',
    'unlocked',
    'click here',
    'save money',
    'balance expires',
    'expires on',
    't&c apply',
    't&c',
    'offers rs',
    'successfully revoked',
    'mandate revoked',
    'zepto cash',
    'initiated refund',
    'payment request',
    'reward points',
    'balance is',
    'upi lite balance',
    'scheduled for',
    'refund initiated',
    'will be credited',
    'under process',
    'is pending',
    'off on your',
    'due',
    'credit limit',
    'credit balance',
    'credit note',
    'credit voucher',
    'wallet loaded',
    'credit line',
    'loan can be',
    'quick loan',
    'personal loan',
    'apply now',
    'check if you qualify',
    'good news',
    'lifetime free',
    'guaranteed',
    'apply https',
    'apply http',
  ];

  static final RegExp _promotionalRegex = RegExp(
    r'(?:up\s*to|win|earn|save|get|chance to|valid till)\s+(?:flat|free|extra|up\s*to\s+)?(?:rs\.?|inr|₹)\s*\d+', 
    caseSensitive: false
  );

  static bool isFinancialSms(String normalizedSms, String sender) {
    final text = normalizedSms.toLowerCase();
    
    // 1. MUST have an amount indicator
    final hasAmountIndicator = text.contains('rs') || 
                               text.contains('inr') || 
                               text.contains('₹') || 
                               text.contains('amount') ||
                               text.contains('bill paid') ||
                               text.contains('payment received for your credit card') ||
                               text.contains('refund credited') ||
                               text.contains('salary credited') ||
                               text.contains('interest credited') ||
                               text.contains('top-up successful');
    if (!hasAmountIndicator) return false;

    // 2. MUST be either a debit or a credit transaction
    final isCredit = [
      'credited', 'credit', 'received', 'deposited', 'deposit', 'refund', 
      'reward', 'cashback', 'added to wallet', 'income', 'added', 'cr', 'disbursed', 'inward'
    ].any((kw) => RegExp(r'\b' + kw + r'\b').hasMatch(text));

    final hasDebitKeyword = [
      'debited', 'debit', 'spent', 'paid', 'payed', 'sent', 
      'transferred', 'transfer', 'withdrawn', 'txn', 'payment', 
      'towards', 'vpa', 'transaction', 'purchase', 'purchased',
      'charge', 'charged', 'payee', 'dr', 'withdrawal', 'pos', 'ecom', 'upi', 'imps', 'neft', 'rtgs', 'sip', 'outward'
    ].any((kw) => RegExp(r'\b' + kw + r'\b').hasMatch(text));
    
    if (!isCredit && !hasDebitKeyword) return false;

    // 3. MUST NOT be an OTP, Junk or Promotion
    final isJunk = _negativeKeywords.any((kw) => RegExp(r'\b' + kw + r'\b').hasMatch(text)) ||
                   _promotionalRegex.hasMatch(text);
    if (isJunk) return false;

    // 4. Exclude personal phone numbers (10+ digits)
    if (RegExp(r'^\+?[0-9]{10,}$').hasMatch(sender)) {
      return false;
    }

    return true; 
  }
}



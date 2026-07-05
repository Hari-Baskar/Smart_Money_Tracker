class CategorizationSystem {
  static final Map<String, String> _merchantToCategory = {
    'zomato': 'Food',
    'swiggy': 'Food',
    'uber': 'Travel',
    'ola': 'Travel',
    'amazon': 'Shopping',
    'flipkart': 'Shopping',
    'blinkit': 'Groceries',
    'zepto': 'Groceries',
    'bigbasket': 'Groceries',
    'netflix': 'Entertainment',
    'spotify': 'Entertainment',
    'hotstar': 'Entertainment',
    'airtel': 'Bills',
    'jio': 'Bills',
    'vi ': 'Bills',
    'bescom': 'Bills',
    'petrol': 'Fuel',
    'shell': 'Fuel',
    'hpcl': 'Fuel',
    'bpcl': 'Fuel',
    'atm': 'Cash Withdrawal',
    'starbucks': 'Food',
    'mcdonalds': 'Food',
    'kfc': 'Food',
  };

  static String categorize(String merchant, String normalizedBody, {String type = 'debit'}) {
    if (type == 'credit') {
      if (normalizedBody.contains('salary')) return 'Salary';
      if (normalizedBody.contains('refund')) return 'Refunds';
      return 'Other';
    }

    String merchantLower = merchant.toLowerCase();
    
    for (var entry in _merchantToCategory.entries) {
      final key = entry.key.trim();
      final regex = RegExp(r'\b' + key + r'\b');
      if (regex.hasMatch(merchantLower) || regex.hasMatch(normalizedBody)) {
        return entry.value;
      }
    }

    if (RegExp(r'\batm\b').hasMatch(normalizedBody) || RegExp(r'\bcash\b').hasMatch(normalizedBody)) {
      return 'Cash Withdrawal';
    }
    
    return 'Unknown';
  }
}


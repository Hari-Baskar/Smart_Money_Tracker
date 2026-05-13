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

  static String categorize(String merchant, String normalizedBody) {
    String merchantLower = merchant.toLowerCase();
    
    for (var entry in _merchantToCategory.entries) {
      if (merchantLower.contains(entry.key) || normalizedBody.contains(entry.key)) {
        return entry.value;
      }
    }

    if (normalizedBody.contains('atm') || normalizedBody.contains('cash')) {
      return 'Cash Withdrawal';
    }
    
    if (normalizedBody.contains('upi')) {
      return 'UPI Transfer';
    }
    
    return 'Unknown';
  }
}


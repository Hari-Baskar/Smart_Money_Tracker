class CategoryMapping {
  final String category;
  final String subcategory;

  const CategoryMapping(this.category, this.subcategory);
}

class CategorizationSystem {
  static final Map<String, CategoryMapping> _merchantToCategory = {
    'zomato': const CategoryMapping('Food', 'Delivery'),
    'swiggy': const CategoryMapping('Food', 'Delivery'),
    'starbucks': const CategoryMapping('Food', 'Restaurant'),
    'mcdonalds': const CategoryMapping('Food', 'Restaurant'),
    'kfc': const CategoryMapping('Food', 'Restaurant'),
    'blinkit': const CategoryMapping('Food', 'Groceries'),
    'zepto': const CategoryMapping('Food', 'Groceries'),
    'bigbasket': const CategoryMapping('Food', 'Groceries'),
    'uber': const CategoryMapping('Travel', 'Taxi/Uber'),
    'ola': const CategoryMapping('Travel', 'Taxi/Uber'),
    'petrol': const CategoryMapping('Travel', 'Fuel'),
    'shell': const CategoryMapping('Travel', 'Fuel'),
    'hpcl': const CategoryMapping('Travel', 'Fuel'),
    'bpcl': const CategoryMapping('Travel', 'Fuel'),
    'amazon': const CategoryMapping('Shopping', 'General'),
    'flipkart': const CategoryMapping('Shopping', 'General'),
    'netflix': const CategoryMapping('Entertainment', 'Streaming'),
    'spotify': const CategoryMapping('Entertainment', 'Streaming'),
    'hotstar': const CategoryMapping('Entertainment', 'Streaming'),
    'airtel': const CategoryMapping('Bills', 'Mobile'),
    'jio': const CategoryMapping('Bills', 'Mobile'),
    'vi ': const CategoryMapping('Bills', 'Mobile'),
    'bescom': const CategoryMapping('Bills', 'Electricity'),
    'atm': const CategoryMapping('Other', 'General'),
  };

  static CategoryMapping getMapping(String merchant, String normalizedBody, {String type = 'debit'}) {
    if (type == 'credit') {
      if (normalizedBody.contains('salary')) return const CategoryMapping('Salary', 'General');
      return const CategoryMapping('Other', 'General');
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
      return const CategoryMapping('Other', 'General');
    }
    
    return const CategoryMapping('Other', 'General');
  }

  static String categorize(String merchant, String normalizedBody, {String type = 'debit'}) {
    return getMapping(merchant, normalizedBody, type: type).category;
  }

  static String categorizeSubcategory(String merchant, String normalizedBody, {String type = 'debit'}) {
    return getMapping(merchant, normalizedBody, type: type).subcategory;
  }
}


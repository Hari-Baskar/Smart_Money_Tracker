class CategoryMapping {
  final String category;
  final String subcategory;

  const CategoryMapping(this.category, [this.subcategory = 'General']);
}

class CategorizationSystem {
  static final Map<String, CategoryMapping> _merchantToCategory = {
    'zomato': const CategoryMapping('Food'),
    'swiggy': const CategoryMapping('Food'),
    'starbucks': const CategoryMapping('Food'),
    'mcdonalds': const CategoryMapping('Food'),
    'kfc': const CategoryMapping('Food'),
    'blinkit': const CategoryMapping('Food'),
    'zepto': const CategoryMapping('Food'),
    'bigbasket': const CategoryMapping('Food'),
    'uber': const CategoryMapping('Travel'),
    'ola': const CategoryMapping('Travel'),
    'petrol': const CategoryMapping('Travel'),
    'shell': const CategoryMapping('Travel'),
    'hpcl': const CategoryMapping('Travel'),
    'bpcl': const CategoryMapping('Travel'),
    'amazon': const CategoryMapping('Shopping'),
    'flipkart': const CategoryMapping('Shopping'),
    'netflix': const CategoryMapping('Entertainment'),
    'spotify': const CategoryMapping('Entertainment'),
    'hotstar': const CategoryMapping('Entertainment'),
    'airtel': const CategoryMapping('Bills'),
    'jio': const CategoryMapping('Bills'),
    'vi ': const CategoryMapping('Bills'),
    'bescom': const CategoryMapping('Bills'),
    'atm': const CategoryMapping('Other'),
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
    return 'General';
  }
}


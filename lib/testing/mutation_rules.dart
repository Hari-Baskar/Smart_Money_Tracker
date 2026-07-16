import 'dart:math';

abstract class MutationRule {
  String get name;
  String apply(String text, Random random);
}

class CurrencyMutation implements MutationRule {
  @override
  String get name => 'CurrencyMutation';

  final List<String> _currencies = [
    'Rs.', 'Rs ', 'Rs', 'INR ', 'INR', '₹', '₹ ', ' INR',
  ];

  @override
  String apply(String text, Random random) {
    // Finds common currency indicators and replaces them
    final pattern = RegExp(r'(?:rs\.?|inr|₹)\s*', caseSensitive: false);
    return text.replaceAllMapped(pattern, (match) {
      if (random.nextDouble() > 0.5) return match.group(0)!; // 50% chance to mutate
      
      final choice = _currencies[random.nextInt(_currencies.length)];
      // Sometimes swap position if the match was a prefix to a number
      if (random.nextDouble() > 0.8 && !choice.contains('₹')) {
        return ''; // Will rely on a suffix rule or just be weird, but let's just replace safely
      }
      return choice;
    });
  }
}

class AmountMutation implements MutationRule {
  @override
  String get name => 'AmountMutation';

  @override
  String apply(String text, Random random) {
    // Find numbers that look like amounts
    final pattern = RegExp(r'(?:rs\.?|inr|₹)\s*(\d+(?:\.\d+)?)', caseSensitive: false);
    return text.replaceAllMapped(pattern, (match) {
      if (random.nextDouble() > 0.5) return match.group(0)!;

      final originalAmountStr = match.group(1)!;
      final originalFull = match.group(0)!;
      
      String newAmountStr;
      int r = random.nextInt(6);
      if (r == 0 && !originalAmountStr.contains('.')) {
        newAmountStr = '$originalAmountStr.00';
      } else if (r == 1 && !originalAmountStr.contains('.')) {
        newAmountStr = '$originalAmountStr.5';
      } else if (r == 2) {
        newAmountStr = '0.50';
      } else if (r == 3) {
        newAmountStr = '999999';
      } else if (r == 4) {
        newAmountStr = '1000000.25';
      } else {
        newAmountStr = '0$originalAmountStr'; // leading zero
      }
      
      return originalFull.replaceFirst(originalAmountStr, newAmountStr);
    });
  }
}

class AccountFormatMutation implements MutationRule {
  @override
  String get name => 'AccountFormatMutation';

  final List<String> _formats = [
    'XX', 'XXXX', '****', 'x', 'A/c XX', 'A/C XX', 'Account XX', 'Acct XX'
  ];

  @override
  String apply(String text, Random random) {
    final pattern = RegExp(r'\b(?:a/c\s*)?(?:x{2,}|\*{2,}|x)(\d{3,4})', caseSensitive: false);
    return text.replaceAllMapped(pattern, (match) {
      if (random.nextDouble() > 0.5) return match.group(0)!;
      final format = _formats[random.nextInt(_formats.length)];
      final digits = match.group(1)!;
      return '$format$digits';
    });
  }
}

class DebitWordMutation implements MutationRule {
  @override
  String get name => 'DebitWordMutation';

  final List<String> _words = [
    'debited', 'debit', 'deducted', 'withdrawn', 'spent', 'paid', 'DR', 'Dr', 'dr'
  ];

  @override
  String apply(String text, Random random) {
    final pattern = RegExp(r'\b(?:debited|debit|deducted|withdrawn|spent|paid|dr)\b', caseSensitive: false);
    return text.replaceAllMapped(pattern, (match) {
      if (random.nextDouble() > 0.5) return match.group(0)!;
      return _words[random.nextInt(_words.length)];
    });
  }
}

class CreditWordMutation implements MutationRule {
  @override
  String get name => 'CreditWordMutation';

  final List<String> _words = [
    'credited', 'credit', 'received', 'deposited', 'CR', 'cr', 'Cr'
  ];

  @override
  String apply(String text, Random random) {
    final pattern = RegExp(r'\b(?:credited|credit|received|deposited|cr)\b', caseSensitive: false);
    return text.replaceAllMapped(pattern, (match) {
      if (random.nextDouble() > 0.5) return match.group(0)!;
      return _words[random.nextInt(_words.length)];
    });
  }
}

class MerchantMutation implements MutationRule {
  @override
  String get name => 'MerchantMutation';

  final Map<String, List<String>> _merchants = {
    'amazon': ['Amazon', 'AMAZON', 'amazon', 'Amazon India', 'Amazon.in', 'AMZN'],
    'swiggy': ['Swiggy', 'SWIGGY', 'swiggy', 'Swiggy.com'],
    'zomato': ['Zomato', 'ZOMATO', 'zomato'],
    'zepto': ['Zepto', 'ZEPTO', 'zepto'],
    'google play': ['Google Play', 'GOOGLE PLAY', 'google play', 'GooglePlay'],
    'netflix': ['Netflix', 'NETFLIX', 'netflix', 'Netflix.com'],
    'spotify': ['Spotify', 'SPOTIFY', 'spotify', 'Spotify Premium'],
    'phonepe': ['PhonePe', 'PHONEPE', 'phonepe'],
    'paytm': ['Paytm', 'PAYTM', 'paytm'],
    'cred': ['CRED', 'Cred', 'cred', 'CRED Club'],
    'uber': ['Uber', 'UBER', 'uber', 'Uber BV']
  };

  @override
  String apply(String text, Random random) {
    String res = text;
    for (var key in _merchants.keys) {
      final pattern = RegExp(r'\b' + key + r'\b', caseSensitive: false);
      res = res.replaceAllMapped(pattern, (match) {
        if (random.nextDouble() > 0.5) return match.group(0)!;
        final list = _merchants[key]!;
        return list[random.nextInt(list.length)];
      });
    }
    return res;
  }
}

class WhitespaceMutation implements MutationRule {
  @override
  String get name => 'WhitespaceMutation';

  final List<String> _spaces = ['  ', '   ', '\t', '\n', ' '];

  @override
  String apply(String text, Random random) {
    if (random.nextDouble() > 0.7) return text;
    return text.replaceAllMapped(RegExp(r' '), (match) {
      if (random.nextDouble() > 0.8) {
        return _spaces[random.nextInt(_spaces.length)];
      }
      return ' ';
    });
  }
}

class PunctuationMutation implements MutationRule {
  @override
  String get name => 'PunctuationMutation';

  final List<String> _puncts = ['.', ':', ';', ',', '*', '/'];

  @override
  String apply(String text, Random random) {
    if (random.nextDouble() > 0.5) return text;
    // Replace dots with other punctuation randomly
    return text.replaceAllMapped(RegExp(r'\.'), (match) {
      if (random.nextDouble() > 0.8) {
        return _puncts[random.nextInt(_puncts.length)];
      }
      return '.';
    });
  }
}

class OcrErrorMutation implements MutationRule {
  @override
  String get name => 'OcrErrorMutation';

  @override
  String apply(String text, Random random) {
    if (random.nextDouble() > 0.5) return text;
    String res = text;
    // 0 -> O
    if (random.nextDouble() > 0.5) res = res.replaceFirst('0', 'O');
    // I -> l
    if (random.nextDouble() > 0.5) res = res.replaceFirst('I', 'l');
    // m -> rn
    if (random.nextDouble() > 0.5) res = res.replaceFirst('m', 'rn');
    // i -> l
    if (random.nextDouble() > 0.5) res = res.replaceFirst('i', 'l');
    
    return res;
  }
}

class CaseMutation implements MutationRule {
  @override
  String get name => 'CaseMutation';

  @override
  String apply(String text, Random random) {
    double r = random.nextDouble();
    if (r < 0.2) {
      return text.toUpperCase();
    } else if (r < 0.4) {
      return text.toLowerCase();
    } else if (r < 0.5) {
      // Random mixed case
      return String.fromCharCodes(text.runes.map((c) {
        if (random.nextDouble() > 0.5) {
          return String.fromCharCode(c).toUpperCase().codeUnitAt(0);
        }
        return String.fromCharCode(c).toLowerCase().codeUnitAt(0);
      }));
    }
    return text;
  }
}

class NoiseMutation implements MutationRule {
  @override
  String get name => 'NoiseMutation';

  final List<String> _noises = ['👍', '✅', '💳', '!!', '...', '  '];

  @override
  String apply(String text, Random random) {
    if (random.nextDouble() > 0.5) return text;
    final noise = _noises[random.nextInt(_noises.length)];
    if (random.nextDouble() > 0.5) {
      return '$noise $text';
    } else {
      return '$text $noise';
    }
  }
}

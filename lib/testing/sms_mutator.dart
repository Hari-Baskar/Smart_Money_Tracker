import 'dart:math';
import 'mutation_rules.dart';

class SmsMutator {
  final List<MutationRule> rules = [
    CurrencyMutation(),
    AmountMutation(),
    AccountFormatMutation(),
    DebitWordMutation(),
    CreditWordMutation(),
    MerchantMutation(),
    WhitespaceMutation(),
    PunctuationMutation(),
    OcrErrorMutation(),
    CaseMutation(),
    NoiseMutation(),
  ];

  /// Generates [count] realistic variations of [originalSms] using the [random] seed.
  /// Returns a map of the mutated string to the list of rule names that were applied.
  Map<String, List<String>> generateMutations(String originalSms, int count, Random random) {
    Map<String, List<String>> results = {};
    
    // Always include the original text
    results[originalSms] = ['Original'];

    int attempts = 0;
    while (results.length < count && attempts < count * 5) {
      attempts++;
      String currentText = originalSms;
      List<String> appliedRules = [];

      // Shuffle rules to apply a random subset in a random order
      var activeRules = List<MutationRule>.from(rules)..shuffle(random);
      
      // Pick a random number of rules to apply (between 1 and max)
      int numRulesToApply = random.nextInt(activeRules.length) + 1;
      
      for (int i = 0; i < numRulesToApply; i++) {
        final rule = activeRules[i];
        String newText = rule.apply(currentText, random);
        if (newText != currentText) {
          currentText = newText;
          appliedRules.add(rule.name);
        }
      }

      if (appliedRules.isNotEmpty && !results.containsKey(currentText)) {
        results[currentText] = appliedRules;
      }
    }

    return results;
  }
}

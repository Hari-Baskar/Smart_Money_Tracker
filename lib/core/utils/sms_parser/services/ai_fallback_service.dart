import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../../constants/app_strings.dart';

class AiFallbackService {
  static final _model = GenerativeModel(
    model: 'gemini-1.5-flash',
    apiKey: AppStrings.geminiApiKey,
  );

  static Future<Map<String, dynamic>?> parseWithAi(String smsBody) async {
    try {
      final prompt = '''You are a highly advanced financial analyzer for bank SMS messages.
Your task is to determine if an SMS or notification is a valid personal transaction (DEBIT for expense, or CREDIT for income).
EXPENSES (debit) include: payments to merchants, UPI transfers to people, ATM withdrawals, bill payments, and card swipes.
INCOME (credit) include: salary, received money, cashback, bank interest, refunds, and money added to wallet.

CRITICAL RULES:
1. Set "type": "debit" if money was spent or sent. Keywords: "paid", "sent", "debited", "towards", "transferred", "vpa", "to payee".
2. Set "type": "credit" if money was received or added. Keywords: "credited", "received", "added", "deposited", "refunded", "cashback".
3. If the message is an OTP, a login alert, a balance check, a payment REQUEST (not yet paid), a failed/declined transaction, a purely informational telecom recharge confirmation (e.g. "recharge successful", "pack activated"), or a promotional/marketing offer/ad (e.g. "up to ₹XXX", "win cashback", "earn rewards", "earn laddoos"), set "type": "junk".
4. For "merchant", extract the FULL name of the store, business, or person.
   - Look for patterns like "debited for payee [NAME]", "Paid to [NAME]", "Received from [NAME]", "Credited by [NAME]".
   - Bank SMS messages often format payee names with underscores, e.g. "MS_VIKRAANTH_AGENCYY_". Replace ALL underscores with spaces: return "MS VIKRAANTH AGENCYY" NOT "MS".
   - Prefixes like MS, MR, DR that appear BEFORE a business/person name are PART OF the name. NEVER return just the prefix alone. Always include the full name after the prefix.
   - Good: "Zomato", "Swiggy", "Amazon", "Salary", "Cashback", "MS VIKRAANTH AGENCYY", "MR RAJAN STORES".
   - Bad: "YOUR BANK", "IOB", "HDFC", "TXN ID", "BANK IMMEDIATELY", "VPA", "SB-xxx", "MS", "MR", "DR" (prefix alone).
5. If you cannot find a clear merchant name, set "merchant": "Bank Transaction".
6. Categorize the transaction into: Food, Travel, Shopping, Bills, Groceries, Entertainment, Health, Investment, Income, Salary, Cashback, Other.

SMS/Notification Content: $smsBody

Return ONLY a STRICT JSON object:
{
"type": "debit" | "credit" | "junk",
"amount": number,
"merchant": "string",
"category": "string",
"date": "YYYY-MM-DD" | null,
"reference": "string" | null
}''';

      final response = await _model.generateContent([Content.text(prompt)]);

      if (response.text != null) {
        String cleanContent = response.text!.trim();
        
        // Handle potential markdown formatting
        if (cleanContent.startsWith('```json')) {
          cleanContent = cleanContent.replaceAll('```json', '');
        }
        if (cleanContent.endsWith('```')) {
          cleanContent = cleanContent.replaceAll('```', '');
        }
        cleanContent = cleanContent.trim();
        
        final Map<String, dynamic> parsed = jsonDecode(cleanContent);
        return parsed;
      }
    } catch (e) {
      print('Gemini AiFallbackService Exception: $e');
    }
    return null;
  }
}

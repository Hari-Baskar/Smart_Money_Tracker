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
Your task is to determine if an SMS or notification is a valid personal EXPENSE (debit).
EXPENSES include: payments to merchants, UPI transfers to people, ATM withdrawals, bill payments, and card swipes.

CRITICAL RULES:
1. ONLY return "type": "debit" if money was actually spent or sent. Look for keywords like "paid", "sent", "debited", "towards", "transferred", "vpa", "to payee".
2. If the message is an OTP, a login alert, a balance check, or an income/credit, set "type": "junk".
3. For "merchant", extract the CLEAN name of the store or person. 
   - Look for patterns like "debited for payee [NAME]", "Paid to [NAME]", "Sent to [NAME]", "towards [NAME]".
   - Good: "Zomato", "Swiggy", "Amazon", "Raman Periyasamy", "GOPAL PERIYANNAN".
   - Bad: "YOUR BANK", "IOB", "HDFC", "TXN ID", "BANK IMMEDIATELY", "VPA", "SB-xxx".
4. If you cannot find a clear merchant name, set "merchant": "Bank Transaction".
5. If the amount is 0, or it's a "collect request" or "payment request" that hasn't been paid, set "type": "junk".
6. Categorize the merchant into standard categories: Food, Travel, Shopping, Bills, Groceries, Entertainment, Health, Investment, Cash Withdrawal, Income. If unsure, set "category": "Unknown".

SMS/Notification Content: $smsBody

Return ONLY a STRICT JSON object:
{
"type": "debit" | "junk",
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

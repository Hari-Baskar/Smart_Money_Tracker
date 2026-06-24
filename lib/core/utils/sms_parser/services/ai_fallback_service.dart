import 'dart:convert';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class AiFallbackService {
  // Keeps track of SMS that required AI parsing, so we can improve regex later
  static List<String> fallbackSmsLog = [];

  static Future<Map<String, dynamic>?> parseWithAi(String smsBody) async {
    // PRE-FILTER: Drastically reduce costs by not sending obvious junk to Gemini
    final lowerSms = smsBody.toLowerCase();
    final hasMoneyKeyword =
        RegExp(r'\b(rs\.?|inr|usd)\b').hasMatch(lowerSms) ||
        RegExp(
          r'\b(credited|debited|spent|withdrawn|withdrawal|purchase|txn|transaction|paid|received|sent|a/c|acct|account|upi|imps|neft|rtgs)\b',
        ).hasMatch(lowerSms);

    if (!hasMoneyKeyword) {
      print('BLOCKED BY JUNK FILTER (Saved Cost): $smsBody');
      return null;
    }

    // Add to log for developers to improve local regex
    if (!fallbackSmsLog.contains(smsBody)) {
      fallbackSmsLog.add(smsBody);
    }

    try {
      // ---------------------------------------------------------
      // 🚀 FRONTEND TESTING MODE (Bypasses Firebase Deployment)
      // ---------------------------------------------------------
      // TEMPORARILY set to true and paste your API key below to test instantly!
      const bool testInFrontend = true;

      if (testInFrontend) {
        print('Testing Gemini in Frontend...');
        // Paste your raw API key here (e.g., 'AIzaSy...')
        const apiKey = 'AQ.Ab8RN6KCb9GRUt-tJ0Ls8Aogsxa5ztqIob8l6B4QXRoHfFQsOg';

        final model = GenerativeModel(
          // You can instantly test different models here: 'gemini-1.5-flash', 'gemini-2.0-flash-lite', etc.
          model: 'gemini-3.1-flash-lite',
          apiKey: apiKey,
        );

        final prompt =
            '''
You are a highly advanced financial analyzer for bank SMS messages.
Your task is to determine if an SMS or notification is a valid personal transaction (DEBIT for expense, or CREDIT for income).

SMS/Notification Content: $smsBody

Return ONLY a STRICT JSON object:
{
"type": "debit" | "credit" | "junk",
"amount": number,
"merchant": "string",
"category": "Food" | "Travel" | "Shopping" | "Bills" | "Entertainment" | "Health" | "Investment" | "Salary" | "Other",
"date": "YYYY-MM-DD" | null,
"reference": "string" | null
}
}
IMPORTANT RULES:
1. "category" MUST be exactly one of the options listed above. Do not make up your own category (e.g. no "transfer"). If unsure, use "Other".
2. "merchant" is the person, business, or entity that sent or received the money (e.g., "Amazon", "CHINNAMMAL", "Paytm"). NEVER use the amount (e.g. "RS.3000.00"), date, or generic words. If the merchant is NOT explicitly clear, or if it is just a location/branch name (e.g. "MARUNGAPURI"), output "-".''';

        final response = await model.generateContent([Content.text(prompt)]);
        var cleanText = response.text?.trim() ?? '';

        if (cleanText.startsWith('```json'))
          cleanText = cleanText.substring(7);
        else if (cleanText.startsWith('```'))
          cleanText = cleanText.substring(3);
        if (cleanText.endsWith('```'))
          cleanText = cleanText.substring(0, cleanText.length - 3);

        final Map<String, dynamic> parsed = Map<String, dynamic>.from(
          jsonDecode(cleanText.trim()),
        );
        print('FRONTEND GEMINI RESULT: $parsed');
        return parsed;
      }

      // ---------------------------------------------------------
      // ☁️ BACKEND PRODUCTION MODE
      // ---------------------------------------------------------
      final callable = FirebaseFunctions.instance.httpsCallable(
        'parseSmsWithGemini',
      );
      final response = await callable.call(<String, dynamic>{
        'smsBody': smsBody,
      });
      print('CLOUD FUNCTION RESPONSE DATA: ${response.data}');

      if (response.data != null) {
        return Map<String, dynamic>.from(response.data);
      }
      return null;
    } catch (e) {
      print('AI Parse Exception: $e');
      rethrow;
    }
  }
}

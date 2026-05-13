import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../constants/app_strings.dart';

class AiService {
  static final _model = GenerativeModel(
    model: 'gemini-1.5-flash',
    apiKey: AppStrings.geminiApiKey,
  );

  static Future<Map<String, String>> extractTransactionDetails(String smsBody) async {
    try {
      final prompt = '''You are an expert financial data extractor. 
Analyze the provided SMS message and extract the FULL, REAL merchant or business name.

Rules:
1. Extract the most recognizable business name (e.g., "ZOMATO", "AMAZON", "STARBUCKS").
2. For UPI/VPA transactions, look for the person or business name after "to" or in the VPA (e.g., "to merchant-name@okaxis" -> "Merchant Name").
3. IMPORTANT: If the name in the SMS is truncated (e.g., "at S."), try to infer the full name if possible, or return the most descriptive version. NEVER return just "S" or "UNKNOWN" if a name exists.
4. Categorize into: Food, Travel, Shopping, Bills, Groceries, Entertainment, Health, Investment, Income, Other.

SMS Content: $smsBody

Return ONLY a JSON object: {"merchant": "NAME", "category": "CATEGORY"}''';

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
        return {
          'merchant': parsed['merchant']?.toString() ?? 'UNKNOWN',
          'category': parsed['category']?.toString() ?? 'Other',
        };
      }
    } catch (e) {
      print('Gemini AiService Exception: $e');
    }
    return {'merchant': 'UNKNOWN', 'category': 'Other'};
  }
}

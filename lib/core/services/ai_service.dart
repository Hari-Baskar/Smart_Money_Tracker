import 'package:cloud_functions/cloud_functions.dart';

class AiService {
  static Future<Map<String, String>> extractTransactionDetails(String smsBody) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('parseSmsWithGemini');
      final response = await callable.call(<String, dynamic>{
        'smsBody': smsBody,
      });
      
      if (response.data != null) {
        final Map<String, dynamic> parsed = Map<String, dynamic>.from(response.data);
        return {
          'merchant': parsed['merchant']?.toString() ?? 'UNKNOWN',
          'category': parsed['category']?.toString() ?? 'Other',
        };
      }
    } catch (e) {
      print('Cloud Function parseSmsWithGemini (AiService) Exception: $e');
    }
    return {'merchant': 'UNKNOWN', 'category': 'Other'};
  }
}

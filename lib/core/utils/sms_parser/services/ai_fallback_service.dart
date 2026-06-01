import 'package:cloud_functions/cloud_functions.dart';

class AiFallbackService {
  static Future<Map<String, dynamic>?> parseWithAi(String smsBody) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('parseSmsWithGemini');
      final response = await callable.call(<String, dynamic>{
        'smsBody': smsBody,
      });

      if (response.data != null) {
        final Map<String, dynamic> parsed = Map<String, dynamic>.from(response.data);
        return parsed;
      }
    } catch (e) {
      print('Cloud Function parseSmsWithGemini Exception: $e');
    }
    return null;
  }
}

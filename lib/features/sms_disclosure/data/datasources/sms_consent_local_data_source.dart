import 'package:shared_preferences/shared_preferences.dart';

class SmsConsentLocalDataSource {
  static const String _consentKey = 'sms_disclosure_consented';

  Future<bool> hasConsented() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_consentKey) ?? false;
  }

  Future<void> saveConsent(bool consented) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_consentKey, consented);
  }
}

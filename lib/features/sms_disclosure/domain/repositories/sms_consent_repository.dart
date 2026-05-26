abstract class SmsConsentRepository {
  Future<bool> hasConsented();
  Future<void> saveConsent(bool consented);
}

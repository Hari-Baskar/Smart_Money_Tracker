import '../../domain/repositories/sms_consent_repository.dart';
import '../datasources/sms_consent_local_data_source.dart';

class SmsConsentRepositoryImpl implements SmsConsentRepository {
  final SmsConsentLocalDataSource _localDataSource;

  SmsConsentRepositoryImpl(this._localDataSource);

  @override
  Future<bool> hasConsented() {
    return _localDataSource.hasConsented();
  }

  @override
  Future<void> saveConsent(bool consented) {
    return _localDataSource.saveConsent(consented);
  }
}

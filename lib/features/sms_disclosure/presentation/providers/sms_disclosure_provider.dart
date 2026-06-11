import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../domain/repositories/sms_consent_repository.dart';
import '../../data/datasources/sms_consent_local_data_source.dart';
import '../../data/repositories/sms_consent_repository_impl.dart';
import '../state/sms_disclosure_state.dart';
import '../notifiers/sms_disclosure_notifier.dart';

final smsConsentLocalDataSourceProvider = Provider<SmsConsentLocalDataSource>((ref) {
  return SmsConsentLocalDataSource();
});

final smsConsentRepositoryProvider = Provider<SmsConsentRepository>((ref) {
  final localDataSource = ref.watch(smsConsentLocalDataSourceProvider);
  return SmsConsentRepositoryImpl(localDataSource);
});

final smsDisclosureNotifierProvider =
    NotifierProvider<SmsDisclosureNotifier, SmsDisclosureState>(() {
  return SmsDisclosureNotifier();
});

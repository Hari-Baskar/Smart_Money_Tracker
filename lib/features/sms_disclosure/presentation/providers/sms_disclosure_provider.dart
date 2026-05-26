import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../domain/repositories/sms_consent_repository.dart';
import '../../data/datasources/sms_consent_local_data_source.dart';
import '../../data/repositories/sms_consent_repository_impl.dart';

class SmsDisclosureState {
  final bool isCheckboxChecked;
  final bool hasConsented;
  final bool isLoading;

  const SmsDisclosureState({
    this.isCheckboxChecked = false,
    this.hasConsented = false,
    this.isLoading = false,
  });

  SmsDisclosureState copyWith({
    bool? isCheckboxChecked,
    bool? hasConsented,
    bool? isLoading,
  }) {
    return SmsDisclosureState(
      isCheckboxChecked: isCheckboxChecked ?? this.isCheckboxChecked,
      hasConsented: hasConsented ?? this.hasConsented,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class SmsDisclosureNotifier extends Notifier<SmsDisclosureState> {
  late final SmsConsentRepository _repository;

  @override
  SmsDisclosureState build() {
    _repository = ref.watch(smsConsentRepositoryProvider);
    Future.microtask(() => _loadInitialConsent());
    return const SmsDisclosureState(isLoading: true);
  }

  Future<void> _loadInitialConsent() async {
    final consented = await _repository.hasConsented();
    state = state.copyWith(
      hasConsented: consented,
      isCheckboxChecked: consented,
      isLoading: false,
    );
  }

  void toggleCheckbox(bool value) {
    state = state.copyWith(isCheckboxChecked: value);
  }

  Future<bool> acceptConsent() async {
    if (!state.isCheckboxChecked) return false;
    
    state = state.copyWith(isLoading: true);
    try {
      await _repository.saveConsent(true);
      state = state.copyWith(hasConsented: true, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false);
      return false;
    }
  }

  Future<void> rejectConsent() async {
    state = state.copyWith(isLoading: true);
    try {
      await _repository.saveConsent(false);
      state = state.copyWith(
        hasConsented: false,
        isCheckboxChecked: false,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }
}

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

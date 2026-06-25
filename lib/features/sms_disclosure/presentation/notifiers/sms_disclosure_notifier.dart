import 'dart:async';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../domain/repositories/sms_consent_repository.dart';
import '../providers/sms_disclosure_provider.dart';
import '../state/sms_disclosure_state.dart';
import 'package:smart_money_tracker/features/auth/presentation/providers/auth_provider.dart';

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

  Future<void> _saveFirestoreConsent(bool consented) async {
    final user = ref.read(authStateProvider).value;
    if (user != null && !user.isAnonymous) {
      await ref.read(authRepositoryProvider).saveUserSettings(
        user.id,
        {'sms_consent': consented},
      );
    }
  }

  Future<bool> acceptConsent() async {
    if (!state.isCheckboxChecked) return false;
    
    state = state.copyWith(isLoading: true);
    try {
      await _repository.saveConsent(true);
      await _saveFirestoreConsent(true);
      state = state.copyWith(hasConsented: true, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false);
      return false;
    }
  }

  Future<void> rejectConsent() async {
    state = state.copyWith(isRejecting: true);
    try {
      await _repository.saveConsent(false);
      await _saveFirestoreConsent(false);
      state = state.copyWith(
        hasConsented: false,
        isCheckboxChecked: false,
        isRejecting: false,
      );
    } catch (e) {
      state = state.copyWith(isRejecting: false);
    }
  }
}

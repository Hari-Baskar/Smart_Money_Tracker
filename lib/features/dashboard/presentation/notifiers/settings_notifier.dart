import 'dart:async';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../state/settings_state.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../providers/settings_provider.dart';

class SettingsNotifier extends Notifier<SettingsState> {
  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  SettingsState build() {
    ref.listen(authStateProvider, (previous, next) {
      if (next is AsyncData && next.value?.id != previous?.value?.id) {
        _syncWithFirebase(next.value?.id);
      }
    });

    bool notifications = _prefs.getBool('notifications_enabled') ?? true;
    String theme = _prefs.getString('theme_mode') ?? 'system';
    String lang = _prefs.getString('language') ?? 'English (US)';
    bool smsReadingActive = _prefs.getBool('sms_reading_enabled') ?? false;
    bool notifListener = _prefs.getBool('notification_listener_enabled') ?? false;
    List<String> scannedMonths = _prefs.getStringList('scanned_months') ?? [];

    final user = ref.read(authStateProvider).value;
    Future.microtask(() => _syncWithFirebase(user?.id));

    return SettingsState(
      notificationsEnabled: notifications,
      themeMode: theme,
      language: lang,
      smsConsentEnabled: smsReadingActive,
      notificationListenerEnabled: notifListener,
      scannedMonths: scannedMonths,
    );
  }

  Future<void> _syncWithFirebase(String? userId) async {
    try {
      if (userId != null) {
        final authRepo = ref.read(authRepositoryProvider);
        final firebaseSettings = await authRepo.getUserSettings(userId);
        if (firebaseSettings != null) {
          final notifications = firebaseSettings['notifications_enabled'] ?? state.notificationsEnabled;
          final theme = firebaseSettings['theme_mode'] ?? state.themeMode;
          final lang = firebaseSettings['language'] ?? state.language;
          final smsReadingActive = firebaseSettings['sms_reading_enabled'] ?? state.smsConsentEnabled;
          final notifListener = firebaseSettings['notification_listener_enabled'] ?? state.notificationListenerEnabled;
          
          List<String> scannedMonths = state.scannedMonths;
          final scannedMonthsDynamic = firebaseSettings['scanned_months'] as List<dynamic>?;
          if (scannedMonthsDynamic != null) {
            scannedMonths = scannedMonthsDynamic.map((e) => e.toString()).toList();
          }
          
          await _prefs.setBool('notifications_enabled', notifications);
          await _prefs.setString('theme_mode', theme);
          await _prefs.setString('language', lang);
          await _prefs.setBool('sms_reading_enabled', smsReadingActive);
          await _prefs.setBool('notification_listener_enabled', notifListener);
          await _prefs.setStringList('scanned_months', scannedMonths);

          state = state.copyWith(
            notificationsEnabled: notifications,
            themeMode: theme,
            language: lang,
            smsConsentEnabled: smsReadingActive,
            notificationListenerEnabled: notifListener,
            scannedMonths: scannedMonths,
          );
        } else {
          // If no settings exist in Firebase, save the current local ones
          await _saveToFirebase({
            'notifications_enabled': state.notificationsEnabled,
            'theme_mode': state.themeMode,
            'language': state.language,
            'sms_reading_enabled': state.smsConsentEnabled,
            'notification_listener_enabled': state.notificationListenerEnabled,
            'scanned_months': state.scannedMonths,
          });
        }
      }
    } catch (e) {
      // Fallback silently if Firebase fails
    }
  }

  Future<void> _saveToFirebase(Map<String, dynamic> settings) async {
    final user = ref.read(authStateProvider).value;
    if (user != null) {
      final authRepo = ref.read(authRepositoryProvider);
      try {
        await authRepo.saveUserSettings(user.id, settings);
      } catch (e) {
        print('Error saving settings to Firebase: $e');
      }
    }
  }

  Future<void> toggleNotifications(bool value) async {
    state = state.copyWith(notificationsEnabled: value);
    await _prefs.setBool('notifications_enabled', value);
    await _saveToFirebase({'notifications_enabled': value});
  }

  Future<void> setThemeMode(String mode) async {
    state = state.copyWith(themeMode: mode);
    await _prefs.setString('theme_mode', mode);
    await _saveToFirebase({'theme_mode': mode});
  }

  Future<void> setLanguage(String language) async {
    state = state.copyWith(language: language);
    await _prefs.setString('language', language);
    await _saveToFirebase({'language': language});
  }

  Future<void> toggleSmsConsent(bool value) async {
    state = state.copyWith(smsConsentEnabled: value);
    await _prefs.setBool('sms_reading_enabled', value);
    await _saveToFirebase({'sms_reading_enabled': value});
  }

  Future<void> toggleNotificationListener(bool value) async {
    state = state.copyWith(notificationListenerEnabled: value);
    await _prefs.setBool('notification_listener_enabled', value);
    await _saveToFirebase({'notification_listener_enabled': value});
  }

  Future<void> addScannedMonth(String monthKey) async {
    final currentList = List<String>.from(state.scannedMonths);
    if (!currentList.contains(monthKey)) {
      currentList.add(monthKey);
      state = state.copyWith(scannedMonths: currentList);
      await _prefs.setStringList('scanned_months', currentList);
      await _saveToFirebase({'scanned_months': currentList});
    }
  }
}

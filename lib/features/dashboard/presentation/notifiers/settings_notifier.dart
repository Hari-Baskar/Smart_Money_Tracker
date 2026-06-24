import 'dart:async';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../state/settings_state.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';

class SettingsNotifier extends Notifier<SettingsState> {
  SharedPreferences? _prefs;

  @override
  SettingsState build() {
    ref.listen(authStateProvider, (previous, next) {
      if (next is AsyncData && next.value?.id != previous?.value?.id) {
        _initPrefs(next.value?.id);
      }
    });

    final user = ref.read(authStateProvider).value;
    _initPrefs(user?.id);
    return SettingsState();
  }

  Future<void> _initPrefs(String? userId) async {
    try {
      _prefs = await SharedPreferences.getInstance();
      
      bool notifications = _prefs?.getBool('notifications_enabled') ?? true;
      String theme = _prefs?.getString('theme_mode') ?? 'light';
      String lang = _prefs?.getString('language') ?? 'English (US)';
      bool smsReadingActive = _prefs?.getBool('sms_reading_enabled') ?? false;
      bool notifListener = _prefs?.getBool('notification_listener_enabled') ?? false;
      List<String> scannedMonths = _prefs?.getStringList('scanned_months') ?? [];

      if (userId != null) {
        final authRepo = ref.read(authRepositoryProvider);
        final firebaseSettings = await authRepo.getUserSettings(userId);
        if (firebaseSettings != null) {
          notifications = firebaseSettings['notifications_enabled'] ?? notifications;
          theme = firebaseSettings['theme_mode'] ?? theme;
          lang = firebaseSettings['language'] ?? lang;
          smsReadingActive = firebaseSettings['sms_reading_enabled'] ?? smsReadingActive;
          notifListener = firebaseSettings['notification_listener_enabled'] ?? notifListener;
          
          final scannedMonthsDynamic = firebaseSettings['scanned_months'] as List<dynamic>?;
          if (scannedMonthsDynamic != null) {
            scannedMonths = scannedMonthsDynamic.map((e) => e.toString()).toList();
          }
          
          await _prefs?.setBool('notifications_enabled', notifications);
          await _prefs?.setString('theme_mode', theme);
          await _prefs?.setString('language', lang);
          await _prefs?.setBool('sms_reading_enabled', smsReadingActive);
          await _prefs?.setBool('notification_listener_enabled', notifListener);
          await _prefs?.setStringList('scanned_months', scannedMonths);
        } else {
          // If no settings exist in Firebase, save the current local ones
          await _saveToFirebase({
            'notifications_enabled': notifications,
            'theme_mode': theme,
            'language': lang,
            'sms_reading_enabled': smsReadingActive,
            'notification_listener_enabled': notifListener,
            'scanned_months': scannedMonths,
          });
        }
      }
      
      state = SettingsState(
        notificationsEnabled: notifications,
        themeMode: theme,
        language: lang,
        smsConsentEnabled: smsReadingActive,
        notificationListenerEnabled: notifListener,
        scannedMonths: scannedMonths,
      );
    } catch (e) {
      // Fallback silently if shared preferences or Firebase fails
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
    await _prefs?.setBool('notifications_enabled', value);
    await _saveToFirebase({'notifications_enabled': value});
  }

  Future<void> setThemeMode(String mode) async {
    state = state.copyWith(themeMode: mode);
    await _prefs?.setString('theme_mode', mode);
    await _saveToFirebase({'theme_mode': mode});
  }

  Future<void> setLanguage(String language) async {
    state = state.copyWith(language: language);
    await _prefs?.setString('language', language);
    await _saveToFirebase({'language': language});
  }

  Future<void> toggleSmsConsent(bool value) async {
    state = state.copyWith(smsConsentEnabled: value);
    await _prefs?.setBool('sms_reading_enabled', value);
    await _saveToFirebase({'sms_reading_enabled': value});
  }

  Future<void> toggleNotificationListener(bool value) async {
    state = state.copyWith(notificationListenerEnabled: value);
    await _prefs?.setBool('notification_listener_enabled', value);
    await _saveToFirebase({'notification_listener_enabled': value});
  }
  Future<void> addScannedMonth(String monthKey) async {
    final currentList = List<String>.from(state.scannedMonths);
    if (!currentList.contains(monthKey)) {
      currentList.add(monthKey);
      state = state.copyWith(scannedMonths: currentList);
      await _prefs?.setStringList('scanned_months', currentList);
      await _saveToFirebase({'scanned_months': currentList});
    }
  }
}

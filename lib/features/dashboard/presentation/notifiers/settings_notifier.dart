import 'dart:async';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../state/settings_state.dart';

class SettingsNotifier extends Notifier<SettingsState> {
  SharedPreferences? _prefs;

  @override
  SettingsState build() {
    _initPrefs();
    return SettingsState();
  }

  Future<void> _initPrefs() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      final notifications = _prefs?.getBool('notifications_enabled') ?? true;
      final theme = _prefs?.getString('theme_mode') ?? 'light';
      final lang = _prefs?.getString('language') ?? 'English (US)';
      final smsReadingActive = _prefs?.getBool('sms_reading_enabled') ?? false;
      final notifListener = _prefs?.getBool('notification_listener_enabled') ?? false;
      
      state = SettingsState(
        notificationsEnabled: notifications,
        themeMode: theme,
        language: lang,
        smsConsentEnabled: smsReadingActive,
        notificationListenerEnabled: notifListener,
      );
    } catch (e) {
      // Fallback silently if shared preferences fails
    }
  }

  Future<void> toggleNotifications(bool value) async {
    state = state.copyWith(notificationsEnabled: value);
    await _prefs?.setBool('notifications_enabled', value);
  }

  Future<void> setThemeMode(String mode) async {
    state = state.copyWith(themeMode: mode);
    await _prefs?.setString('theme_mode', mode);
  }

  Future<void> setLanguage(String language) async {
    state = state.copyWith(language: language);
    await _prefs?.setString('language', language);
  }

  Future<void> toggleSmsConsent(bool value) async {
    state = state.copyWith(smsConsentEnabled: value);
    await _prefs?.setBool('sms_reading_enabled', value);
  }

  Future<void> toggleNotificationListener(bool value) async {
    state = state.copyWith(notificationListenerEnabled: value);
    await _prefs?.setBool('notification_listener_enabled', value);
  }
}

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsState {
  final bool notificationsEnabled;
  final String themeMode; // 'light', 'dark', 'system'
  final String language;

  SettingsState({
    this.notificationsEnabled = true,
    this.themeMode = 'system',
    this.language = 'English (US)',
  });

  SettingsState copyWith({
    bool? notificationsEnabled,
    String? themeMode,
    String? language,
  }) {
    return SettingsState(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
    );
  }
}

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
      final theme = _prefs?.getString('theme_mode') ?? 'system';
      final lang = _prefs?.getString('language') ?? 'English (US)';
      
      state = SettingsState(
        notificationsEnabled: notifications,
        themeMode: theme,
        language: lang,
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
}

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(() {
  return SettingsNotifier();
});

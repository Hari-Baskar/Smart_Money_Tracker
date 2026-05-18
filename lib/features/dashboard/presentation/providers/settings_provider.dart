import 'package:hooks_riverpod/hooks_riverpod.dart';

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
  @override
  SettingsState build() {
    return SettingsState();
  }

  void toggleNotifications(bool value) {
    state = state.copyWith(notificationsEnabled: value);
  }

  void setThemeMode(String mode) {
    state = state.copyWith(themeMode: mode);
  }

  void setLanguage(String language) {
    state = state.copyWith(language: language);
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(() {
  return SettingsNotifier();
});

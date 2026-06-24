class SettingsState {
  final bool notificationsEnabled;
  final String themeMode; // 'light', 'dark', 'system'
  final String language;
  final bool smsConsentEnabled;
  final bool notificationListenerEnabled;
  final List<String> scannedMonths;

  SettingsState({
    this.notificationsEnabled = true,
    this.themeMode = 'light',
    this.language = 'English (US)',
    this.smsConsentEnabled = false,
    this.notificationListenerEnabled = false,
    this.scannedMonths = const [],
  });

  SettingsState copyWith({
    bool? notificationsEnabled,
    String? themeMode,
    String? language,
    bool? smsConsentEnabled,
    bool? notificationListenerEnabled,
    List<String>? scannedMonths,
  }) {
    return SettingsState(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
      smsConsentEnabled: smsConsentEnabled ?? this.smsConsentEnabled,
      notificationListenerEnabled: notificationListenerEnabled ?? this.notificationListenerEnabled,
      scannedMonths: scannedMonths ?? this.scannedMonths,
    );
  }
}

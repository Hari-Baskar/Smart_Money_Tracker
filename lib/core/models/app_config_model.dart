class AppConfig {
  final String minVersion;
  final String maxVersion;
  final String? updateUrl;
  final String? releaseNotes;
  final bool testAds;
  final bool showAds;
  final bool isNative;

  AppConfig({
    required this.minVersion,
    required this.maxVersion,
    this.updateUrl,
    this.releaseNotes,
    this.testAds = false,
    this.showAds = false,
    this.isNative = false,
  });

  factory AppConfig.fromMap(Map<String, dynamic> map) {
    return AppConfig(
      minVersion: map['min_version'] ?? '1.0.0',
      maxVersion: map['max_version'] ?? '1.0.0',
      updateUrl: map['update_url'],
      releaseNotes: map['release_notes'] ?? 'New update available.',
      testAds: map['test_ads'] ?? map['test_ads '] ?? map['testAds'] ?? false,
      showAds: map['show_ads'] ?? map['show_ads '] ?? map['showAds'] ?? false,
      isNative: map['is_native'] ?? map['is_native '] ?? map['isNative'] ?? false,
    );
  }
}

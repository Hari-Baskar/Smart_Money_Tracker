class AppConfig {
  final String minVersion;
  final String maxVersion;
  final String? updateUrl;
  final String? releaseNotes;
  final bool testAds;
  final bool showAds;

  AppConfig({
    required this.minVersion,
    required this.maxVersion,
    this.updateUrl,
    this.releaseNotes,
    this.testAds = false,
    this.showAds = false,
  });

  factory AppConfig.fromMap(Map<String, dynamic> map) {
    return AppConfig(
      minVersion: map['min_version'] ?? '1.0.0',
      maxVersion: map['max_version'] ?? '1.0.0',
      updateUrl: map['update_url'],
      releaseNotes: map['release_notes'] ?? 'New update available.',
      testAds: map['test_ads'] ?? false,
      showAds: map['show_ads'] ?? false,
    );
  }
}

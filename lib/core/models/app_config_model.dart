class AppConfig {
  final String minVersion;
  final String maxVersion;
  final String? updateUrl;
  final String? releaseNotes;
  final bool testAds;
  final bool showAds;
  final bool showScanAd;
  final int paginationInitialFetchLimit;
  final int paginationLoadMoreLimit;
  final int reviewDays;

  AppConfig({
    required this.minVersion,
    required this.maxVersion,
    this.updateUrl,
    this.releaseNotes,
    this.testAds = false,
    this.showAds = false,
    this.showScanAd = false,
    this.paginationInitialFetchLimit = 500,
    this.paginationLoadMoreLimit = 50,
    this.reviewDays = 14,
  });

  factory AppConfig.fromMap(Map<String, dynamic> map) {
    return AppConfig(
      minVersion: map['min_version'] ?? '1.0.0',
      maxVersion: map['max_version'] ?? '1.0.0',
      updateUrl: map['update_url'],
      releaseNotes: map['release_notes'] ?? 'New update available.',
      testAds: map['test_ads'] ?? map['test_ads '] ?? map['testAds'] ?? false,
      showAds: map['show_ads'] ?? map['show_ads '] ?? map['showAds'] ?? false,
      showScanAd: map['show_scan_ad'] ?? map['showScanAd'] ?? false,
      paginationInitialFetchLimit:
          map['pagination_initial_fetch_limit'] ??
          map['paginationInitialFetchLimit'] ??
          500,
      paginationLoadMoreLimit:
          map['pagination_load_more_limit'] ??
          map['paginationLoadMoreLimit'] ??
          50,
      reviewDays: map['review_days'] ?? map['reviewDays'] ?? 14,
    );
  }
}

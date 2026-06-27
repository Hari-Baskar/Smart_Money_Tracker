import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppReviewService {
  static const String _firstOpenDateKey = 'app_first_open_date';
  static const String _hasShownReviewKey = 'app_has_shown_review';

  final InAppReview _inAppReview = InAppReview.instance;

  /// Checks if the conditions are met and prompts for an app review.
  /// Conditions: [reviewDays] days passed since first open.
  Future<void> checkAndRequestReview({int reviewDays = 14}) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final hasShownReview = prefs.getBool(_hasShownReviewKey) ?? false;
      if (hasShownReview) return;

      final firstOpenDateStr = prefs.getString(_firstOpenDateKey);
      DateTime firstOpenDate;

      if (firstOpenDateStr == null) {
        firstOpenDate = DateTime.now();
        await prefs.setString(
          _firstOpenDateKey,
          firstOpenDate.toIso8601String(),
        );
      } else {
        firstOpenDate = DateTime.parse(firstOpenDateStr);
      }

      final daysSinceFirstOpen = DateTime.now()
          .difference(firstOpenDate)
          .inDays;

      if (daysSinceFirstOpen >= reviewDays) {
        if (await _inAppReview.isAvailable()) {
          await _inAppReview.requestReview();
          await prefs.setBool(_hasShownReviewKey, true);
        }
      }
    } catch (e) {
      // Silently fail if review prompt fails
      print('Error requesting app review: $e');
    }
  }

  /// Manually opens the store listing for the app.
  /// Use this for a "Rate App" button in the settings screen.
  Future<void> requestManualReview() async {
    try {
      // For manual button clicks, we MUST use openStoreListing directly.
      // Google Play strictly limits how often requestReview() can be shown (quota limits).
      // If we use requestReview() on a button, it will work once and then silently fail.
      await _inAppReview.openStoreListing(appStoreId: 'finzo.smartmoneytracker');
    } catch (e) {
      print('Error opening store listing: $e');
    }
  }
}

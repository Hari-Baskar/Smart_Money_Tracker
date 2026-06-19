import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppReviewService {
  static const String _firstOpenDateKey = 'app_first_open_date';
  static const String _hasShownReviewKey = 'app_has_shown_review';

  final InAppReview _inAppReview = InAppReview.instance;

  /// Checks if the conditions are met and prompts for an app review.
  /// Conditions: Tracking 50 transactions OR 14 days passed since first open.
  Future<void> checkAndRequestReview(int transactionCount) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final hasShownReview = prefs.getBool(_hasShownReviewKey) ?? false;
      if (hasShownReview) return;

      final firstOpenDateStr = prefs.getString(_firstOpenDateKey);
      DateTime firstOpenDate;

      if (firstOpenDateStr == null) {
        firstOpenDate = DateTime.now();
        await prefs.setString(_firstOpenDateKey, firstOpenDate.toIso8601String());
      } else {
        firstOpenDate = DateTime.parse(firstOpenDateStr);
      }

      final daysSinceFirstOpen = DateTime.now().difference(firstOpenDate).inDays;

      if (transactionCount >= 50 || daysSinceFirstOpen >= 14) {
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
}

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  static final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;
  static final FirebasePerformance _performance = FirebasePerformance.instance;

  /// Log a screen view
  static Future<void> logScreenView(String screenName) async {
    try {
      await _analytics.logScreenView(screenName: screenName);
      debugPrint('Analytics: Screen view logged - $screenName');
    } catch (e) {
      debugPrint('Analytics Error: Failed to log screen view - $e');
    }
  }

  /// Log a custom event
  static Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {
    try {
      await _analytics.logEvent(name: name, parameters: parameters);
      debugPrint('Analytics: Event logged - $name');
    } catch (e) {
      debugPrint('Analytics Error: Failed to log event $name - $e');
    }
  }

  /// Specifically track Local Database hits to prove efficiency
  static Future<void> logLocalDbHit({String action = 'read'}) async {
    try {
      await _analytics.logEvent(
        name: 'database_hit',
        parameters: {
          'source': 'local_sqlite',
          'action': action,
        },
      );
    } catch (e) {
      // Silently fail to not interrupt UX
    }
  }

  /// Specifically track Remote Database (Firebase) hits
  static Future<void> logRemoteDbHit({String action = 'write'}) async {
    try {
      await _analytics.logEvent(
        name: 'database_hit',
        parameters: {
          'source': 'remote_firestore',
          'action': action,
        },
      );
    } catch (e) {
      // Silently fail
    }
  }

  /// Log a non-fatal error to Crashlytics
  static Future<void> logError(dynamic exception, StackTrace stackTrace, {String? reason}) async {
    try {
      await _crashlytics.recordError(exception, stackTrace, reason: reason);
      debugPrint('Crashlytics: Error logged - $reason');
    } catch (e) {
      debugPrint('Crashlytics Error: Failed to log error - $e');
    }
  }

  /// Start a performance trace
  static Future<Trace?> startTrace(String traceName) async {
    try {
      final trace = _performance.newTrace(traceName);
      await trace.start();
      return trace;
    } catch (e) {
      debugPrint('Performance Error: Failed to start trace $traceName - $e');
      return null;
    }
  }

  /// Stop a performance trace
  static Future<void> stopTrace(Trace? trace) async {
    try {
      await trace?.stop();
    } catch (e) {
      debugPrint('Performance Error: Failed to stop trace - $e');
    }
  }
}

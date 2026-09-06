import 'dart:developer';
import 'package:notification_listener_service/notification_listener_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../../firebase_options.dart';
import '../models/transaction_model.dart';
import '../utils/sms_parser.dart';
import '../constants/app_colors.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // List of package names for common payment/banking apps in India/Globally
  static const List<String> _paymentApps = [
    'com.smart_money_tracker', // App itself for developer test notifications
    'com.android.shell', // ADB testing
    'com.google.android.apps.nbu.paisa.user', // Google Pay
    'com.phonepe.app', // PhonePe
    'net.one97.paytm', // Paytm
    'in.amazon.mShop.android.shopping', // Amazon Pay
    'com.csam.icici.bank.imobile', // iMobile
    'com.sbi.YONO', // YONO SBI
  ];

  static Future<void> initialize({bool forceRequest = false}) async {
    try {
      // Initialize timezone database
      tz.initializeTimeZones();
      try {
        tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
      } catch (e) {
        log('Error setting local timezone location: $e');
      }

      // Initialize local notifications plugin
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/launcher_icon');
      const InitializationSettings initializationSettings =
          InitializationSettings(android: initializationSettingsAndroid);
      await _localNotifications.initialize(settings: initializationSettings);

      // Check user preferences: Stop if disabled by user settings
      final prefs = await SharedPreferences.getInstance();
      final isListenerEnabled =
          prefs.getBool('notification_listener_enabled') ?? false;
      if (!isListenerEnabled) {
        log(
          'Notification Listener is disabled in settings. Skipping initialization.',
        );
        return;
      }

      // Check Notification Listener Permission (special permission)
      bool granted = await NotificationListenerService.isPermissionGranted();

      log("Permission: $granted");

      NotificationListenerService.notificationsStream.listen((event) {
        log("EVENT FOUND");
        log(event.toString());
      });

      bool listenerStatus =
          await NotificationListenerService.isPermissionGranted();
      if (!listenerStatus && forceRequest) {
        log('Notification Listener Permission not granted, requesting...');
        listenerStatus = await NotificationListenerService.requestPermission();
      }

      if (listenerStatus) {
        log('Notification Listener Started');
        NotificationListenerService.notificationsStream.listen((event) {
          _handleNotification(event);
        });
      } else {
        log('Notification Listener Permission not granted/denied.');
      }
    } catch (e) {
      log('Error initializing Notification Service: $e');
    }
  }

  static Future<void> _handleNotification(dynamic event) async {
    try {
      // Check user preferences before processing payment app notification events
      final prefs = await SharedPreferences.getInstance();
      final isListenerEnabled =
          prefs.getBool('notification_listener_enabled') ?? false;
      if (!isListenerEnabled) {
        log('Notification Listener event skipped: disabled in settings.');
        return;
      }
      final packageName = event.packageName ?? '';

      // Only process notifications from known payment apps
      if (!_paymentApps.contains(packageName)) return;

      final title = event.title ?? '';
      final content = event.content ?? '';

      // We combine title and content to mimic an SMS for our parser
      final fullText = '$title $content';

      // Simple initial filter to ensure it's a transactional message
      final lowerText = fullText.toLowerCase();
      final hasPaymentKeyword = [
        'paid',
        'sent',
        'debited',
        'transferred',
        'towards',
        'paying',
        'payment',
        'txn',
        'spent',
        'transaction',
        'credited',
        'received',
        'deposited',
        'added',
      ].any((kw) => lowerText.contains(kw));

      if (!hasPaymentKeyword &&
          !lowerText.contains('₹') &&
          !lowerText.contains('rs.')) {
        log('Notification filtered out (not transactional): $fullText');
        return;
      }

      log('Payment App Notification Detected: $fullText');

      // Use the existing SmsParser to extract details
      final transaction = await SmsParser.parse(
        fullText,
        packageName,
        date: DateTime.now(),
      );

      if (transaction != null) {
        // Since this might run in a background context, ensure Firebase is ready
        try {
          if (Firebase.apps.isEmpty) {
            await Firebase.initializeApp(
              options: DefaultFirebaseOptions.currentPlatform,
            );
          }
        } catch (_) {}

        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final docRef = FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('transactions')
              .doc();

          final txnWithId = transaction.copyWith(id: docRef.id);
          await docRef.set(txnWithId.toMap());
          log(
            'Transaction saved from Payment App Notification: ${transaction.amount} ${transaction.merchant}',
          );
          await showBackgroundTransactionNotification(txnWithId);
        }
      }
    } catch (e) {
      log('Error processing payment notification: $e');
    }
  }

  static Future<void> showBackgroundTransactionNotification(
    TransactionModel transaction,
  ) async {
    try {
      final isCredit = transaction.type == TransactionType.credit;
      final amountStr = AppColors.formatShortAmount(transaction.amount);
      final title = isCredit ? 'Income Added' : 'Expense Recorded';
      final merchantName =
          transaction.merchant.isNotEmpty && transaction.merchant != '-'
              ? transaction.merchant
              : (isCredit ? 'Sender' : 'Merchant');
      final body = isCredit
          ? '₹$amountStr received from $merchantName'
          : '₹$amountStr spent at $merchantName';

      const AndroidNotificationDetails androidNotificationDetails =
          AndroidNotificationDetails(
            'transaction_channel_id',
            'Transactions',
            channelDescription: 'Notifications for tracked transactions',
            importance: Importance.max,
            priority: Priority.high,
          );
      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidNotificationDetails,
      );

      final notifId = (transaction.id.hashCode & 0x7FFFFFFF);

      await _localNotifications.show(
        id: notifId,
        title: title,
        body: body,
        notificationDetails: notificationDetails,
      );
      log('Transaction notification shown: $title - $body');
    } catch (e) {
      log('Error showing transaction notification: $e');
    }
  }

  static Future<void> sendTestNotification() async {
    try {
      const AndroidNotificationDetails androidNotificationDetails =
          AndroidNotificationDetails(
            'test_notification_channel_id',
            'Test Notifications',
            channelDescription: 'Channel for testing foreground notifications',
            importance: Importance.max,
            priority: Priority.high,
            ticker: 'ticker',
          );
      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidNotificationDetails,
      );
      await _localNotifications.show(
        id: 0,
        title: 'Test Notification',
        body: 'This is a test foreground notification from the app.',
        notificationDetails: notificationDetails,
      );
      log('Test foreground notification sent successfully');
    } catch (e) {
      log('Error sending test foreground notification: $e');
    }
  }

  static Future<void> sendTestBackgroundNotification() async {
    try {
      const AndroidNotificationDetails androidNotificationDetails =
          AndroidNotificationDetails(
            'test_bg_notification_channel_id',
            'Background Notifications',
            channelDescription: 'Channel for background system notifications',
            importance: Importance.max,
            priority: Priority.high,
            ticker: 'ticker',
          );
      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidNotificationDetails,
      );
      await _localNotifications.show(
        id: 1,
        title: 'Background Sync',
        body: 'This is a test notification from the background service.',
        notificationDetails: notificationDetails,
      );
      log('Test background notification sent successfully');
    } catch (e) {
      log('Error sending test background notification: $e');
    }
  }

  static Future<void> updateDailyReminderState({
    double totalIncome = 0.0,
    double totalExpense = 0.0,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isEnabled = prefs.getBool('is_daily_reminder_enabled') ?? true;

      // Cancel existing reminder first
      await cancelDailyReminder();

      if (!isEnabled) {
        log('Daily summary notification is disabled in settings.');
        return;
      }

      const int hour = 21; // 9:30 PM
      const int minute = 30;

      final now = DateTime.now();

      // Check if the scheduled time has already passed today
      DateTime localSchedule = DateTime(
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );
      if (now.isAfter(localSchedule)) {
        localSchedule = localSchedule.add(const Duration(days: 1));
      }

      // Convert the local schedule exactly to UTC to bypass tz timezone mapping issues
      final utcSchedule = localSchedule.toUtc();
      final tz.TZDateTime scheduledDate = tz.TZDateTime.utc(
        utcSchedule.year,
        utcSchedule.month,
        utcSchedule.day,
        utcSchedule.hour,
        utcSchedule.minute,
      );

      const String title = 'Daily Summary';

      final String formattedIncome = AppColors.formatShortAmount(totalIncome);
      final String formattedExpense = AppColors.formatShortAmount(totalExpense);

      String body;
      if (totalIncome > 0 && totalExpense > 0) {
        body =
            'Today\'s Total: Income ₹$formattedIncome • Expense ₹$formattedExpense';
      } else if (totalExpense > 0) {
        body = 'Today\'s Total Expense: ₹$formattedExpense';
      } else if (totalIncome > 0) {
        body = 'Today\'s Total Income: ₹$formattedIncome';
      } else {
        body = 'No transactions recorded today. Tap to add manually.';
      }

      const AndroidNotificationDetails androidNotificationDetails =
          AndroidNotificationDetails(
            'daily_summary_channel_id',
            'Daily Summary',
            channelDescription: 'Channel for daily income and expense summaries',
            importance: Importance.max,
            priority: Priority.high,
          );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidNotificationDetails,
      );

      // Schedule the repeating zoned notification
      await _localNotifications.zonedSchedule(
        id: 100, // ID for daily summary
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      log(
        'Local daily summary scheduled for 9:30 PM. Next alarm: $scheduledDate ($title: $body)',
      );
    } catch (e) {
      log('Error updating local daily summary state: $e');
    }
  }

  static Future<void> cancelDailyReminder() async {
    try {
      await _localNotifications.cancel(id: 100);
      log('Cancelled local daily summary notification');
    } catch (e) {
      log('Error cancelling local daily summary notification: $e');
    }
  }
}

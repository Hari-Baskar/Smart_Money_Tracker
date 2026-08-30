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
import 'auth_service.dart';

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
        } catch (e) {
          // Firebase might already be initialized
        }

        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('transactions')
              .doc(transaction.id)
              .set(transaction.toMap());

          log(
            'Notification Transaction Saved: ${transaction.merchant} - ${transaction.amount}',
          );

          await showBackgroundTransactionNotification(transaction);
        }
      }
    } catch (e) {
      log('Error handling notification: $e');
    }
  }

  static Future<void> sendTestNotification() async {
    try {
      final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
          FlutterLocalNotificationsPlugin();

      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/launcher_icon');

      const InitializationSettings initializationSettings =
          InitializationSettings(android: initializationSettingsAndroid);

      await flutterLocalNotificationsPlugin.initialize(
        settings: initializationSettings,
      );

      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();
      if (androidImplementation != null) {
        await androidImplementation.requestNotificationsPermission();
      }

      const AndroidNotificationDetails androidNotificationDetails =
          AndroidNotificationDetails(
            'test_payment_channel_id',
            'Test Financial Alerts',
            channelDescription: 'Channel for developer test alerts',
            importance: Importance.max,
            priority: Priority.high,
          );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidNotificationDetails,
      );

      await flutterLocalNotificationsPlugin.show(
        id: 999,
        title: 'AD-KVBANK-S',
        body:
            'Your NEFT Transfer of INR 60,000.00 from A/c No:XX12771 to Karthik Balaji Murugasan Ref No: KVBLH00262586680 is settled. Avl Bal INR 29,626.51 -KVB',
        notificationDetails: notificationDetails,
      );
      log('Developer test notification sent successfully');
    } catch (e) {
      log('Error sending developer test notification: $e');
    }
  }

  static Future<void> showBackgroundTransactionNotification(
    TransactionModel transaction,
  ) async {
    try {
      final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
          FlutterLocalNotificationsPlugin();

      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/launcher_icon');

      const InitializationSettings initializationSettings =
          InitializationSettings(android: initializationSettingsAndroid);

      await flutterLocalNotificationsPlugin.initialize(
        settings: initializationSettings,
      );

      const AndroidNotificationDetails androidNotificationDetails =
          AndroidNotificationDetails(
            'transaction_alerts_channel',
            'Transaction Alerts',
            channelDescription: 'Alerts for new transactions recorded from SMS',
            importance: Importance.max,
            priority: Priority.high,
          );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidNotificationDetails,
      );

      String typeText = transaction.type == TransactionType.credit
          ? 'Credit'
          : 'Debit';
      String amountText = '₹${transaction.amount.toStringAsFixed(2)}';
      String bodyText =
          'Recorded $typeText of $amountText at ${transaction.merchant}.';

      await flutterLocalNotificationsPlugin.show(
        id: transaction.id.hashCode,
        title: 'New Transaction Logged',
        body: bodyText,
        notificationDetails: notificationDetails,
      );
      log('Background transaction notification sent successfully');
    } catch (e) {
      log('Error sending background transaction notification: $e');
    }
  }

  static Future<void> showGenericTestNotification(String messageBody) async {
    try {
      final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
          FlutterLocalNotificationsPlugin();

      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/launcher_icon');

      const InitializationSettings initializationSettings =
          InitializationSettings(android: initializationSettingsAndroid);

      await flutterLocalNotificationsPlugin.initialize(
        settings: initializationSettings,
      );

      const AndroidNotificationDetails androidNotificationDetails =
          AndroidNotificationDetails(
            'test_alerts_channel',
            'Test Alerts',
            channelDescription: 'Temporary channel for testing background isolate',
            importance: Importance.max,
            priority: Priority.high,
          );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidNotificationDetails,
      );

      await flutterLocalNotificationsPlugin.show(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: 'Background SMS Triggered!',
        body: 'Received: $messageBody',
        notificationDetails: notificationDetails,
      );
      log('Test background notification sent successfully');
    } catch (e) {
      log('Error sending test background notification: $e');
    }
  }

  static Future<void> updateDailyReminderState({
    required bool hasTransactionsToday,
    required bool hasUnknownTransactionsToday,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isEnabled = prefs.getBool('is_daily_reminder_enabled') ?? true;

      // Cancel existing reminder first
      await cancelDailyReminder();

      if (!isEnabled) {
        log('Daily reminder is disabled in settings.');
        return;
      }

      final hour = prefs.getInt('daily_reminder_time_hour') ?? 21; // 9 PM
      final minute = prefs.getInt('daily_reminder_time_minute') ?? 0;

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

      const String title = 'Daily Reminder';

      final userName = await AuthService().getUserName();
      final greeting = (userName != null && userName.isNotEmpty)
          ? 'Hey ${userName.split(' ').first}, did you spend anything today?'
          : 'Did you spend anything today?';

      final String body = '$greeting Do not forget to log your transactions!';

      const AndroidNotificationDetails androidNotificationDetails =
          AndroidNotificationDetails(
            'daily_reminder_channel_id',
            'Daily Reminders',
            channelDescription: 'Channel for daily transaction reminders',
            importance: Importance.max,
            priority: Priority.high,
          );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidNotificationDetails,
      );

      // Schedule the repeating zoned notification
      await _localNotifications.zonedSchedule(
        id: 100, // ID for daily reminders
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      log(
        'Local daily reminder scheduled. Next alarm: $scheduledDate ($title)',
      );
    } catch (e) {
      log('Error updating local daily reminder state: $e');
    }
  }

  static Future<void> cancelDailyReminder() async {
    try {
      await _localNotifications.cancel(id: 100);
      log('Cancelled local daily reminder');
    } catch (e) {
      log('Error cancelling local daily reminder: $e');
    }
  }
}

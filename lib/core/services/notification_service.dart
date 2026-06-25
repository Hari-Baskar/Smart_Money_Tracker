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
import '../utils/sms_parser.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // List of package names for common payment/banking apps in India/Globally
  static const List<String> _paymentApps = [
    'com.smart_money_tracker', // App itself for developer test notifications
    'com.android.shell',
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
          AndroidInitializationSettings('launcher_icon');
      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
      );
      await _localNotifications.initialize(settings: initializationSettings);

      // Check user preferences: Stop if disabled by user settings
      final prefs = await SharedPreferences.getInstance();
      final isListenerEnabled = prefs.getBool('notification_listener_enabled') ?? false;
      if (!isListenerEnabled) {
        log('Notification Listener is disabled in settings. Skipping initialization.');
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
      final isListenerEnabled = prefs.getBool('notification_listener_enabled') ?? false;
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
          AndroidInitializationSettings('launcher_icon');

      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
      );

      await flutterLocalNotificationsPlugin.initialize(settings: initializationSettings);

      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
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

      const NotificationDetails notificationDetails =
          NotificationDetails(android: androidNotificationDetails);

      await flutterLocalNotificationsPlugin.show(
        id: 999,
        title: 'AD-KVBANK-S',
        body: 'Your NEFT Transfer of INR 60,000.00 from A/c No:XX12771 to Karthik Balaji Murugasan Ref No: KVBLH00262586680 is settled. Avl Bal INR 29,626.51 -KVB',
        notificationDetails: notificationDetails,
      );
      log('Developer test notification sent successfully');
    } catch (e) {
      log('Error sending developer test notification: $e');
    }
  }

  static Future<void> updateDailyReminderState({
    required bool hasTransactionsToday,
    required bool hasUnknownTransactionsToday,
  }) async {
    try {
      final now = tz.TZDateTime.now(tz.local);
      
      // Determine the next target date
      tz.TZDateTime scheduledDate;
      String title;
      String body;

      // Check if 8 PM has already passed today
      final eightPmToday = tz.TZDateTime(tz.local, now.year, now.month, now.day, 20, 0);
      
      if (now.isAfter(eightPmToday)) {
        // If it's already past 8 PM today, we target tomorrow at 8 PM
        scheduledDate = eightPmToday.add(const Duration(days: 1));
        title = 'No Transactions Today';
        body = 'Did you spend anything today? Do not forget to add your transactions!';
      } else {
        // It's before 8 PM today
        if (!hasTransactionsToday) {
          scheduledDate = eightPmToday;
          title = 'No Transactions Today';
          body = 'Did you spend anything today? Do not forget to add your transactions!';
        } else if (hasUnknownTransactionsToday) {
          scheduledDate = eightPmToday;
          title = 'Uncategorized Transactions';
          body = 'You have some unknown transactions today. Please categorize them!';
        } else {
          // Has transactions today and all are categorized!
          // We don't need a reminder today. Schedule for tomorrow at 8 PM.
          scheduledDate = eightPmToday.add(const Duration(days: 1));
          title = 'No Transactions Today';
          body = 'Did you spend anything today? Do not forget to add your transactions!';
        }
      }

      const AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
        'daily_reminder_channel_id',
        'Daily Reminders',
        channelDescription: 'Channel for daily transaction reminders',
        importance: Importance.max,
        priority: Priority.high,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidNotificationDetails,
      );

      // Cancel any existing scheduled reminder with the same ID
      await cancelDailyReminder();

      // Schedule the one-shot zoned notification
      await _localNotifications.zonedSchedule(
        id: 100, // ID for daily reminders
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
      log('Local daily reminder scheduled. Next alarm: $scheduledDate ($title)');
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


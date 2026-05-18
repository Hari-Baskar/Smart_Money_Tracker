import 'dart:developer';
import 'package:permission_handler/permission_handler.dart';
import 'package:notification_listener_service/notification_listener_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../firebase_options.dart';
import '../utils/sms_parser.dart';
import 'package:uuid/uuid.dart';

class NotificationService {
  // List of package names for common payment/banking apps in India/Globally
  static const List<String> _paymentApps = [
    'com.google.android.apps.nbu.paisa.user', // Google Pay
    'com.phonepe.app', // PhonePe
    'net.one97.paytm', // Paytm
    'in.amazon.mShop.android.shopping', // Amazon Pay
    'com.csam.icici.bank.imobile', // iMobile
    'com.sbi.YONO', // YONO SBI
  ];

  static Future<void> initialize() async {
    try {
      // 1. Request POST_NOTIFICATIONS permission (for Android 13+)
      final notificationStatus = await Permission.notification.request();
      if (notificationStatus.isDenied) {
        log('Notification Permission denied by user.');
      }

      // 2. Request Notification Listener Permission (special permission)
      bool listenerStatus = await NotificationListenerService.isPermissionGranted();
      if (!listenerStatus) {
        log('Notification Listener Permission not granted, requesting...');
        listenerStatus = await NotificationListenerService.requestPermission();
      }

      if (listenerStatus) {
        log('Notification Listener Started');
        NotificationListenerService.notificationsStream.listen((event) {
          _handleNotification(event);
        });
      } else {
        log('Notification Listener Permission denied.');
      }
    } catch (e) {
      log('Error initializing Notification Service: $e');
    }
  }

  static Future<void> _handleNotification(dynamic event) async {
    try {
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
        'paid', 'sent', 'debited', 'transferred', 'towards',
        'paying', 'payment', 'txn', 'spent', 'transaction',
        'credited', 'received', 'deposited', 'added'
      ].any((kw) => lowerText.contains(kw));

      if (!hasPaymentKeyword && !lowerText.contains('₹') && !lowerText.contains('rs.')) {
        log('Notification filtered out (not transactional): $fullText');
        return; 
      }

      log('Payment App Notification Detected: $fullText');

      // Use the existing SmsParser to extract details
      final transaction = await SmsParser.parse(fullText, packageName, date: DateTime.now());

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
              
          log('Notification Transaction Saved: ${transaction.merchant} - ${transaction.amount}');
        }
      }
    } catch (e) {
      log('Error handling notification: $e');
    }
  }
}

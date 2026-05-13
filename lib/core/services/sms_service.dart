import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:telephony/telephony.dart';
import '../../firebase_options.dart';
import '../models/transaction_model.dart';
import '../utils/sms_parser.dart';

class SmsService {
  final Telephony telephony = Telephony.instance;

  Future<bool> requestPermissions() async {
    var status = await Permission.sms.request();
    return status.isGranted;
  }

  Future<List<TransactionModel>> fetchRecentTransactions() async {
    bool granted = await requestPermissions();
    if (!granted) return [];

    // Fetch messages from inbox
    List<SmsMessage> messages = await telephony.getInboxSms(
      columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
      sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.DESC)],
    );

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Filter ONLY for today's messages first
    final todayMessages = messages.where((m) {
      if (m.date == null) return false;
      final msgDate = DateTime.fromMillisecondsSinceEpoch(m.date!);
      return msgDate.year == today.year &&
          msgDate.month == today.month &&
          msgDate.day == today.day;
    }).toList();

    List<TransactionModel> transactions = [];

    // Keywords specifically for EXPENSES/DEBITS
    final debitKeywords = [
      'debited',
      'spent',
      'paid',
      'payed',
      'sent',
      'transferred',
      'transfer',
      'withdrawn',
      'txn',
      'payment',
    ];

    // Filter messages that look like EXPENSES and have an AMOUNT (Rs/INR/₹)
    final potentialExpenses = todayMessages.where((m) {
      if (m.body == null) return false;
      final body = m.body!.toLowerCase();

      // Must have an amount indicator
      bool hasAmount =
          body.contains('rs') || body.contains('inr') || body.contains('₹');
      if (!hasAmount) return false;

      // Must be a debit/expense (ignore "credited", "received", "added")
      if (body.contains('credited') ||
          body.contains('received') ||
          body.contains('added')) {
        return false;
      }

      return debitKeywords.any((kw) => body.contains(kw));
    }).toList();

    // Process potential expenses sequentially to avoid API rate limits
    final limitedExpenses = potentialExpenses.take(20).toList();

    for (var message in limitedExpenses) {
      try {
        final date = message.date != null
            ? DateTime.fromMillisecondsSinceEpoch(message.date!)
            : null;

        // Pass to parser which uses AI for refined extraction
        final transaction = await SmsParser.parse(
          message.body!,
          message.address ?? '',
          date: date,
        );

        if (transaction != null) {
          if (transaction.type == TransactionType.debit) {
            transactions.add(transaction);
          }
        }

        await Future.delayed(const Duration(milliseconds: 300));
      } catch (e) {
        print('Error processing today\'s message: $e');
      }
    }

    return transactions;
  }

  // To listen for incoming SMS in real-time
  void listenToIncomingSms(
    Function(TransactionModel) onTransactionDetected,
  ) async {
    bool granted = await requestPermissions();
    if (!granted) return;

    telephony.listenIncomingSms(
      onNewMessage: (SmsMessage message) async {
        if (message.body != null) {
          final date = message.date != null
              ? DateTime.fromMillisecondsSinceEpoch(message.date!)
              : null;
          final transaction = await SmsParser.parse(
            message.body!,
            message.address ?? '',
            date: date,
          );
          if (transaction != null) {
            onTransactionDetected(transaction);
          }
        }
      },
      onBackgroundMessage: backgroundMessageHandler,
      listenInBackground: true,
    );
  }
}

@pragma('vm:entry-point')
Future<void> backgroundMessageHandler(SmsMessage message) async {
  // Note: This runs in a separate isolate
  if (message.body == null) return;

  try {
    // Initialize Firebase in the background isolate
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    final date = message.date != null
        ? DateTime.fromMillisecondsSinceEpoch(message.date!)
        : null;

    final transaction = await SmsParser.parse(
      message.body!,
      message.address ?? '',
      date: date,
    );

    if (transaction != null) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('transactions')
            .doc(transaction.id)
            .set(transaction.toMap());

        print(
          'Background Transaction Saved: ${transaction.merchant} - ${transaction.amount}',
        );
      }
    }
  } catch (e) {
    print('Error in background SMS handling: $e');
  }
}

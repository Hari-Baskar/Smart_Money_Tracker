import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:telephony/telephony.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../../firebase_options.dart';
import '../models/transaction_model.dart';
import '../utils/sms_parser.dart';
import 'local_database_helper.dart';

class SmsService {
  final Telephony telephony = Telephony.instance;

  Future<bool> requestPermissions() async {
    var status = await Permission.sms.request();
    return status.isGranted;
  }

  Future<List<TransactionModel>> fetchRecentTransactions(String userId) {
    return fetchTransactionsForDate(userId, DateTime.now());
  }

  Future<List<TransactionModel>> fetchTransactionsForDate(String userId, DateTime targetDate) async {
    bool granted = await requestPermissions();
    if (!granted) return [];

    // Fetch messages from inbox
    List<SmsMessage> messages = await telephony.getInboxSms(
      columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
      sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.DESC)],
    );

    final target = DateTime(targetDate.year, targetDate.month, targetDate.day);
    final targetEnd = DateTime(targetDate.year, targetDate.month, targetDate.day, 23, 59, 59, 999);

    final existingTxns = await LocalDatabaseHelper.instance.getTransactionsInDateRange(userId, target, targetEnd);
    final existingSmsSet = existingTxns.map((t) => t.rawSms).toSet();

    // Filter ONLY for target date's messages first
    final targetMessages = messages.where((m) {
      if (m.date == null) return false;
      final msgDate = DateTime.fromMillisecondsSinceEpoch(m.date!);
      return msgDate.year == target.year &&
          msgDate.month == target.month &&
          msgDate.day == target.day;
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
      'payee',
      'dr',
      'withdrawal',
      'purchase',
      'pos',
      'ecom',
      'upi',
      'imps',
      'neft',
      'rtgs',
    ];

    // Keywords for INCOME/CREDITS
    final creditKeywords = [
      'credited',
      'received',
      'added',
      'deposited',
      'cashback',
      'refund',
      'cr',
    ];

    print("TARGET MESSAGES (Recent): ${targetMessages.length}");

    // Filter messages that look like transactions and have an AMOUNT (Rs/INR/₹)
    final potentialTransactions = targetMessages.where((m) {
      if (m.body == null) return false;
      if (existingSmsSet.contains(m.body!)) return false; // Skip already processed SMS
      
      final body = m.body!.toLowerCase();

      // Must have an amount indicator (rs, inr, amt, ₹) not buried inside an English word (like "offers")
      bool hasAmount = RegExp(r'(?<![a-z])(?:rs|inr|amt)(?![a-z])|₹').hasMatch(body);
      if (!hasAmount) return false;

      // Must be either a debit or a credit
      bool isDebit = debitKeywords.any((kw) => body.contains(kw));
      bool isCredit = creditKeywords.any((kw) => body.contains(kw));

      return isDebit || isCredit;
    }).toList();

    // Process potential transactions sequentially
    final transactionsToProcess = potentialTransactions.toList();

    for (var message in transactionsToProcess) {
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
          transactions.add(transaction);
        }
      } catch (e) {
        print('Error processing message for target date: $e');
      }
    }

    // Proximity Deduplication
    List<TransactionModel> deduplicated = [];
    for (var t in transactions) {
      bool isDuplicate = false;
      for (int i = 0; i < deduplicated.length; i++) {
        final existing = deduplicated[i];
        if (existing.amount == t.amount && existing.type == t.type) {
          if (existing.date != null && t.date != null) {
            if (existing.date!.difference(t.date!).abs().inMinutes <= 2) {
              
              bool refsOverlap = false;
              String ref1 = existing.reference?.trim() ?? '';
              String ref2 = t.reference?.trim() ?? '';

              if (ref1.isEmpty || ref2.isEmpty) {
                refsOverlap = true; // One is missing, assume duplicate
              } else if (ref1.contains(ref2) || ref2.contains(ref1)) {
                refsOverlap = true; // Substring match
              }

              if (refsOverlap) {
                isDuplicate = true;
                if ((t.reference?.length ?? 0) > (existing.reference?.length ?? 0)) {
                  deduplicated[i] = t;
                }
                break;
              }
            }
          }
        }
      }
      if (!isDuplicate) {
        deduplicated.add(t);
      }
    }

    return deduplicated;
  }

  Future<List<TransactionModel>> fetchTransactionsForDateRange(String userId, DateTime start, DateTime end) async {
    bool granted = await requestPermissions();
    if (!granted) return [];

    // Fetch messages from inbox ONCE
    List<SmsMessage> messages = await telephony.getInboxSms(
      columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
      sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.DESC)],
    );

    final targetStart = DateTime(start.year, start.month, start.day);
    final targetEnd = DateTime(end.year, end.month, end.day, 23, 59, 59, 999);

    final existingTxns = await LocalDatabaseHelper.instance.getTransactionsInDateRange(userId, targetStart, targetEnd);
    final existingSmsSet = existingTxns.map((t) => t.rawSms).toSet();

    final targetMessages = messages.where((m) {
      if (m.date == null) return false;
      final msgDate = DateTime.fromMillisecondsSinceEpoch(m.date!);
      return msgDate.isAfter(targetStart.subtract(const Duration(seconds: 1))) && msgDate.isBefore(targetEnd.add(const Duration(seconds: 1)));
    }).toList();

    List<TransactionModel> transactions = [];

    final debitKeywords = ['debited', 'spent', 'paid', 'payed', 'sent', 'transferred', 'transfer', 'withdrawn', 'txn', 'payment', 'payee', 'dr', 'withdrawal', 'purchase', 'pos', 'ecom', 'upi', 'imps', 'neft', 'rtgs'];
    final creditKeywords = ['credited', 'received', 'added', 'deposited', 'cashback', 'refund', 'cr'];

    final potentialTransactions = targetMessages.where((m) {
      if (m.body == null) return false;
      if (existingSmsSet.contains(m.body!)) return false; 
      
      final body = m.body!.toLowerCase();
      // Must have an amount indicator not buried inside an English word
      bool hasAmount = RegExp(r'(?<![a-z])(?:rs|inr|amt)(?![a-z])|₹').hasMatch(body);
      if (!hasAmount) return false;

      bool isDebit = debitKeywords.any((kw) => body.contains(kw));
      bool isCredit = creditKeywords.any((kw) => body.contains(kw));
      return isDebit || isCredit;
    }).toList();

    // Process potential transactions sequentially
    final transactionsToProcess = potentialTransactions.toList();

    for (var message in transactionsToProcess) {
      try {
        final date = message.date != null ? DateTime.fromMillisecondsSinceEpoch(message.date!) : null;
        final transaction = await SmsParser.parse(message.body!, message.address ?? '', date: date);

        if (transaction != null) {
          print("SCAN LOG | Date: $date | Txn #: ${transaction.reference} | SMS: ${message.body}");
          transactions.add(transaction);
        } else {
          print("SCAN LOG | Date: $date | Txn #: FAILED TO PARSE | SMS: ${message.body}");
        }
      } catch (e) {
        print('Error processing message for range: $e');
      }
    }

    // Proximity Deduplication: Banks often send 2 different SMS for the same transaction.
    // If we see the exact same amount and type within 2 minutes, merge them.
    List<TransactionModel> deduplicated = [];
    for (var t in transactions) {
      bool isDuplicate = false;
      for (int i = 0; i < deduplicated.length; i++) {
        final existing = deduplicated[i];
        if (existing.amount == t.amount && existing.type == t.type) {
          if (existing.date != null && t.date != null) {
            if (existing.date!.difference(t.date!).abs().inMinutes <= 2) {
              
              bool refsOverlap = false;
              String ref1 = existing.reference?.trim() ?? '';
              String ref2 = t.reference?.trim() ?? '';

              if (ref1.isEmpty || ref2.isEmpty) {
                refsOverlap = true; // One is missing, assume duplicate
              } else if (ref1.contains(ref2) || ref2.contains(ref1)) {
                refsOverlap = true; // Substring match
              }

              if (refsOverlap) {
                isDuplicate = true;
                // Keep the one with the better/longer reference number
                if ((t.reference?.length ?? 0) > (existing.reference?.length ?? 0)) {
                  deduplicated[i] = t;
                }
                break;
              }
            }
          }
        }
      }
      if (!isDuplicate) {
        deduplicated.add(t);
      }
    }

    return deduplicated;
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

Future<bool> _isTransactionEditedLocally(String uid, String txnId) async {
  try {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'transactions_$uid.db');
    final db = await openDatabase(path, readOnly: true);
    final List<Map<String, dynamic>> result = await db.query(
      'transactions',
      columns: ['isEdited'],
      where: 'id = ?',
      whereArgs: [txnId],
    );
    await db.close();
    if (result.isNotEmpty) {
      return (result.first['isEdited'] as int) == 1;
    }
  } catch (e) {
    print('Background SMS: Error checking local SQLite DB: $e');
  }
  return false;
}

@pragma('vm:entry-point')
Future<void> backgroundMessageHandler(SmsMessage message) async {
  // Note: This runs in a separate isolate
  if (message.body == null) return;

  // FAST LOCAL FILTER: Exit immediately if the incoming message is clearly not a financial transaction.
  // This avoids initializing heavy SharedPreferences and Firebase app instances for 95% of spam/OTPs.
  final normalizedBody = message.body!.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
  final isFinancial = RegExp(r'(?<![a-z])(?:rs|inr|amt)(?![a-z])|₹').hasMatch(normalizedBody);
  if (!isFinancial) {
    return; // Exit instantly at 0 computational/battery cost!
  }

  try {
    // Google Play Policy compliance check: Ensure user consent has been explicitly granted
    // BEFORE starting background SMS parsing or initializing Firebase/Firestore.
    final prefs = await SharedPreferences.getInstance();
    final consented = prefs.getBool('sms_disclosure_consented') ?? false;

    if (!consented) {
      print('Background SMS processing skipped: Explicit user consent is not granted.');
      return;
    }

    final date = message.date != null
        ? DateTime.fromMillisecondsSinceEpoch(message.date!)
        : null;

    final transaction = await SmsParser.parse(
      message.body!,
      message.address ?? '',
      date: date,
    );

    if (transaction != null) {
      final savedUid = prefs.getString('current_user_uid');
      if (savedUid != null) {
        final isEdited = await _isTransactionEditedLocally(savedUid, transaction.id);
        if (isEdited) {
          print('Background SMS: Skip saving to protect manually edited local transaction.');
          return;
        }
      }

      // Initialize Firebase in the background isolate
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final docRef = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('transactions')
            .doc(transaction.id);

        await docRef.set(transaction.toMap());

        print(
          'Background Transaction Saved: ${transaction.merchant} - ${transaction.amount}',
        );
      }
    }
  } catch (e) {
    print('Error in background SMS handling: $e');
  }
}

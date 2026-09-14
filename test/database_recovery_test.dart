import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:smart_money_tracker/core/services/local_database_helper.dart';
import 'package:smart_money_tracker/core/models/transaction_model.dart';

void main() {
  // Initialize FFI for local SQLite test execution
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  const testUid = 'test_user_resilience_123';
  final dbHelper = LocalDatabaseHelper.instance;

  final sampleTxn = TransactionModel(
    id: 'txn_test_1',
    amount: 1500.0,
    merchant: 'Amazon India',
    date: DateTime(2026, 9, 14, 10, 30),
    type: TransactionType.debit,
    category: 'Shopping',
    subcategory: 'Electronics',
    rawSms: 'Rs 1500.00 debited for Amazon',
    splits: [],
    isEdited: false,
  );

  setUp(() async {
    // Clear and reset before test
    await dbHelper.close();
  });

  tearDown(() async {
    await dbHelper.deleteAllTransactions(testUid);
    await dbHelper.close();
  });

  test('Database properly initializes and saves transaction', () async {
    await dbHelper.saveTransaction(testUid, sampleTxn);
    final txns = await dbHelper.getTransactions(testUid);

    expect(txns.length, 1);
    expect(txns.first.id, 'txn_test_1');
    expect(txns.first.amount, 1500.0);
    expect(txns.first.merchant, 'Amazon India');
  });

  test('Auto-recovery: Operates seamlessly when underlying database is closed unexpectedly', () async {
    // 1. Initial write
    await dbHelper.saveTransaction(testUid, sampleTxn);
    var txns = await dbHelper.getTransactions(testUid);
    expect(txns.length, 1);

    // 2. Simulate OS aggressively closing the SQLite connection directly
    final rawDb = await dbHelper.getDatabase(testUid);
    expect(rawDb.isOpen, isTrue);
    await rawDb.close();
    expect(rawDb.isOpen, isFalse);

    // 3. Immediately attempt queries on dbHelper without manual restart
    // Before fix: Threw DatabaseException(error database_closed)
    // After fix: Detects !isOpen or catches error, reopens DB, and succeeds!
    final recoveredTxns = await dbHelper.getTransactions(testUid);
    expect(recoveredTxns.length, 1);
    expect(recoveredTxns.first.merchant, 'Amazon India');

    // 4. Test insert after another simulated closure
    final rawDb2 = await dbHelper.getDatabase(testUid);
    await rawDb2.close();

    final sampleTxn2 = sampleTxn.copyWith(
      id: 'txn_test_2',
      amount: 450.0,
      merchant: 'Swiggy',
    );
    await dbHelper.saveTransaction(testUid, sampleTxn2);

    final allTxns = await dbHelper.getTransactions(testUid);
    expect(allTxns.length, 2);
    expect(allTxns.any((t) => t.merchant == 'Swiggy'), isTrue);
  });

  test('Concurrent access does not cause race conditions during reconnection', () async {
    // Simulate closure
    await dbHelper.close();

    // Fire 5 concurrent queries at the exact same instant while database is closed
    final futures = List.generate(5, (_) => dbHelper.getTransactions(testUid));
    final results = await Future.wait(futures);

    for (final res in results) {
      expect(res, isA<List<TransactionModel>>());
    }
  });
}

import 'dart:async';
import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:smart_money_tracker/core/models/transaction_model.dart';

class LocalDatabaseHelper {
  static final LocalDatabaseHelper instance = LocalDatabaseHelper._init();
  Database? _database;
  String? _currentUid;

  LocalDatabaseHelper._init();

  // Stream controller to notify repository of any updates/writes to transactions or subcategories
  final _changeController = StreamController<void>.broadcast();
  Stream<void> get onChange => _changeController.stream;

  Future<Database> getDatabase(String uid) async {
    // If the database is already open for the correct user uid, return it
    if (_database != null && _currentUid == uid) {
      return _database!;
    }

    // If a database is open for a different user uid, close it first
    if (_database != null) {
      await close();
    }

    _currentUid = uid;
    // Uses the Firebase Auth uid for the SQLite database filename
    _database = await _initDB('transactions_$uid.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        amount REAL NOT NULL,
        merchant TEXT NOT NULL,
        date TEXT NOT NULL,
        type TEXT NOT NULL,
        category TEXT NOT NULL,
        subcategory TEXT NOT NULL,
        rawSms TEXT NOT NULL,
        splits TEXT NOT NULL,
        isEdited INTEGER NOT NULL,
        reference TEXT,
        bankId TEXT,
        paymentMethodId TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE subcategories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        parentCategory TEXT NOT NULL,
        isCustom INTEGER NOT NULL,
        isIncome INTEGER NOT NULL
      )
    ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS subcategories (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          parentCategory TEXT NOT NULL,
          isCustom INTEGER NOT NULL,
          isIncome INTEGER NOT NULL
        )
      ''');
    }
  }

  // ── TRANSACTION CRUD ──

  Future<void> saveTransaction(String uid, TransactionModel txn) async {
    final db = await getDatabase(uid);
    
    final map = txn.toMap();
    // Convert splits list to JSON string for SQLite storage
    final splitsJson = jsonEncode(map['splits'] ?? []);
    
    await db.insert(
      'transactions',
      {
        'id': txn.id,
        'amount': txn.amount,
        'merchant': txn.merchant,
        'date': txn.date.toIso8601String(),
        'type': txn.type.name,
        'category': txn.category,
        'subcategory': txn.subcategory,
        'rawSms': txn.rawSms,
        'splits': splitsJson,
        'isEdited': txn.isEdited ? 1 : 0,
        'reference': txn.reference,
        'bankId': txn.bankId,
        'paymentMethodId': txn.paymentMethodId,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    
    // Notify listeners of changes
    _changeController.add(null);
  }

  Future<void> saveTransactionsBatch(String uid, List<TransactionModel> txns) async {
    final db = await getDatabase(uid);
    final batch = db.batch();
    
    for (final txn in txns) {
      final map = txn.toMap();
      final splitsJson = jsonEncode(map['splits'] ?? []);
      
      batch.insert(
        'transactions',
        {
          'id': txn.id,
          'amount': txn.amount,
          'merchant': txn.merchant,
          'date': txn.date.toIso8601String(),
          'type': txn.type.name,
          'category': txn.category,
          'subcategory': txn.subcategory,
          'rawSms': txn.rawSms,
          'splits': splitsJson,
          'isEdited': txn.isEdited ? 1 : 0,
          'reference': txn.reference,
          'bankId': txn.bankId,
          'paymentMethodId': txn.paymentMethodId,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    
    await batch.commit(noResult: true);
    _changeController.add(null);
  }

  Future<void> deleteTransaction(String uid, String id) async {
    final db = await getDatabase(uid);
    await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
    _changeController.add(null);
  }

  Future<List<TransactionModel>> getTransactions(String uid) async {
    final db = await getDatabase(uid);
    final result = await db.query('transactions', orderBy: 'date DESC');
    return result.map((json) => _mapToModel(json)).toList();
  }

  Future<List<TransactionModel>> getTransactionsInDateRange(String uid, DateTime start, DateTime end) async {
    final db = await getDatabase(uid);
    final result = await db.query(
      'transactions',
      where: 'date >= ? AND date <= ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'date DESC',
    );
    return result.map((json) => _mapToModel(json)).toList();
  }

  TransactionModel _mapToModel(Map<String, dynamic> json) {
    // Deserialize splits JSON
    final splitsList = jsonDecode(json['splits'] as String) as List;
    final typeStr = json['type'] as String;
    
    return TransactionModel(
      id: json['id'] as String,
      amount: (json['amount'] as num).toDouble(),
      merchant: json['merchant'] as String,
      date: DateTime.parse(json['date'] as String),
      type: TransactionType.values.firstWhere(
        (e) => e.name == typeStr,
        orElse: () => TransactionType.unknown,
      ),
      category: json['category'] as String,
      subcategory: json['subcategory'] as String,
      rawSms: json['rawSms'] as String,
      splits: splitsList.map((x) => TransactionSplit.fromMap(x as Map<String, dynamic>)).toList(),
      isEdited: (json['isEdited'] as int) == 1,
      reference: json['reference'] as String?,
      bankId: json['bankId'] as String?,
      paymentMethodId: json['paymentMethodId'] as String?,
    );
  }

  // ── SUBCATEGORY CRUD ──

  Future<void> saveSubcategory(String uid, SubcategoryModel subcategory) async {
    final db = await getDatabase(uid);
    await db.insert(
      'subcategories',
      {
        'id': subcategory.id,
        'name': subcategory.name,
        'parentCategory': subcategory.parentCategory,
        'isCustom': subcategory.isCustom ? 1 : 0,
        'isIncome': subcategory.isIncome ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _changeController.add(null);
  }

  Future<void> saveSubcategoriesBatch(String uid, List<SubcategoryModel> subcategories) async {
    final db = await getDatabase(uid);
    final batch = db.batch();
    
    for (final sub in subcategories) {
      batch.insert(
        'subcategories',
        {
          'id': sub.id,
          'name': sub.name,
          'parentCategory': sub.parentCategory,
          'isCustom': sub.isCustom ? 1 : 0,
          'isIncome': sub.isIncome ? 1 : 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
    _changeController.add(null);
  }

  Future<void> deleteSubcategory(String uid, String subcategoryId) async {
    final db = await getDatabase(uid);
    await db.delete(
      'subcategories',
      where: 'id = ?',
      whereArgs: [subcategoryId],
    );
    _changeController.add(null);
  }

  Future<List<SubcategoryModel>> getSubcategories(String uid) async {
    final db = await getDatabase(uid);
    final result = await db.query('subcategories');
    return result.map((json) => SubcategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      parentCategory: json['parentCategory'] as String,
      isCustom: (json['isCustom'] as int) == 1,
      isIncome: (json['isIncome'] as int) == 1,
    )).toList();
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
    }
    _database = null;
    _currentUid = null;
  }
}

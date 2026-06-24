import 'dart:async';
import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:smart_money_tracker/core/models/transaction_model.dart';

import 'package:smart_money_tracker/core/models/custom_asset_model.dart';

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
      version: 4,
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
        isIncome INTEGER NOT NULL,
        isArchived INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        isCustom INTEGER NOT NULL,
        isIncome INTEGER NOT NULL,
        isArchived INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE custom_assets (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        isArchived INTEGER NOT NULL DEFAULT 0
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
      
      try {
        await db.execute('ALTER TABLE transactions ADD COLUMN bankId TEXT');
      } catch (e) {
        print('bankId column already exists or failed to add: $e');
      }

      try {
        await db.execute('ALTER TABLE transactions ADD COLUMN paymentMethodId TEXT');
      } catch (e) {
        print('paymentMethodId column already exists or failed to add: $e');
      }
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS categories (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          isCustom INTEGER NOT NULL,
          isIncome INTEGER NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS custom_assets (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          type TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 4) {
      try {
        await db.execute('ALTER TABLE categories ADD COLUMN isArchived INTEGER NOT NULL DEFAULT 0');
      } catch (e) {
        print('categories.isArchived column already exists or failed to add: $e');
      }
      try {
        await db.execute('ALTER TABLE subcategories ADD COLUMN isArchived INTEGER NOT NULL DEFAULT 0');
      } catch (e) {
        print('subcategories.isArchived column already exists or failed to add: $e');
      }
      try {
        await db.execute('ALTER TABLE custom_assets ADD COLUMN isArchived INTEGER NOT NULL DEFAULT 0');
      } catch (e) {
        print('custom_assets.isArchived column already exists or failed to add: $e');
      }
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

  Future<void> deleteAllTransactions(String uid) async {
    final db = await getDatabase(uid);
    await db.delete('transactions');
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

  Future<int> getTransactionCount(String uid) async {
    final db = await getDatabase(uid);
    final result = await db.rawQuery('SELECT COUNT(*) FROM transactions');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<DateTime?> getOldestTransactionDate(String userId) async {
    final db = await getDatabase(userId);
    final result = await db.rawQuery('SELECT MIN(date) as oldest FROM transactions');
    if (result.isNotEmpty && result.first['oldest'] != null) {
      return DateTime.parse(result.first['oldest'] as String);
    }
    return null;
  }

  Future<DateTime?> getNewestTransactionDate(String userId) async {
    final db = await getDatabase(userId);
    final result = await db.rawQuery('SELECT MAX(date) as newest FROM transactions');
    if (result.isNotEmpty && result.first['newest'] != null) {
      return DateTime.parse(result.first['newest'] as String);
    }
    return null;
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
        'parentCategory': subcategory.parentCategoryId,
        'isCustom': subcategory.isCustom ? 1 : 0,
        'isIncome': subcategory.isIncome ? 1 : 0,
        'isArchived': subcategory.isArchived ? 1 : 0,
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
          'parentCategory': sub.parentCategoryId,
          'isCustom': sub.isCustom ? 1 : 0,
          'isIncome': sub.isIncome ? 1 : 0,
          'isArchived': sub.isArchived ? 1 : 0,
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
      parentCategoryId: json['parentCategory'] as String,
      isCustom: (json['isCustom'] as int) == 1,
      isIncome: (json['isIncome'] as int) == 1,
      isArchived: (json['isArchived'] as int?) == 1,
    )).toList();
  }

  // ── CATEGORY CRUD ──

  Future<void> saveCategory(String uid, CategoryModel category) async {
    final db = await getDatabase(uid);
    await db.insert(
      'categories',
      {
        'id': category.id,
        'name': category.name,
        'isCustom': category.isCustom ? 1 : 0,
        'isIncome': category.isIncome ? 1 : 0,
        'isArchived': category.isArchived ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _changeController.add(null);
  }

  Future<void> saveCategoriesBatch(String uid, List<CategoryModel> categories) async {
    final db = await getDatabase(uid);
    final batch = db.batch();
    for (final cat in categories) {
      batch.insert(
        'categories',
        {
          'id': cat.id,
          'name': cat.name,
          'isCustom': cat.isCustom ? 1 : 0,
          'isIncome': cat.isIncome ? 1 : 0,
          'isArchived': cat.isArchived ? 1 : 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
    _changeController.add(null);
  }

  Future<void> deleteCategory(String uid, String categoryId) async {
    final db = await getDatabase(uid);
    await db.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [categoryId],
    );
    _changeController.add(null);
  }

  Future<List<CategoryModel>> getCategories(String uid) async {
    final db = await getDatabase(uid);
    final result = await db.query('categories');
    return result.map((json) => CategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      isCustom: (json['isCustom'] as int) == 1,
      isIncome: (json['isIncome'] as int) == 1,
      isArchived: (json['isArchived'] as int?) == 1,
    )).toList();
  }

  // ── CUSTOM ASSETS CRUD ──

  Future<void> saveCustomAsset(String uid, CustomAssetModel asset) async {
    final db = await getDatabase(uid);
    await db.insert(
      'custom_assets',
      asset.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _changeController.add(null);
  }

  Future<void> deleteCustomAsset(String uid, String id) async {
    final db = await getDatabase(uid);
    await db.delete(
      'custom_assets',
      where: 'id = ?',
      whereArgs: [id],
    );
    _changeController.add(null);
  }

  Future<List<CustomAssetModel>> getCustomAssets(String uid) async {
    final db = await getDatabase(uid);
    final result = await db.query('custom_assets');
    return result.map((json) => CustomAssetModel.fromMap(json)).toList();
  }

  Future<void> renameBankId(String uid, String oldBankId, String newBankId) async {
    final db = await getDatabase(uid);
    await db.update(
      'transactions',
      {'bankId': newBankId},
      where: 'bankId = ?',
      whereArgs: [oldBankId],
    );
    _changeController.add(null);
  }

  Future<void> deleteBankId(String uid, String bankId) async {
    final db = await getDatabase(uid);
    await db.update(
      'transactions',
      {'bankId': null},
      where: 'bankId = ?',
      whereArgs: [bankId],
    );
    _changeController.add(null);
  }

  Future<void> renamePaymentMethodId(String uid, String oldId, String newId) async {
    final db = await getDatabase(uid);
    await db.update(
      'transactions',
      {'paymentMethodId': newId},
      where: 'paymentMethodId = ?',
      whereArgs: [oldId],
    );
    _changeController.add(null);
  }

  Future<void> deletePaymentMethodId(String uid, String id) async {
    final db = await getDatabase(uid);
    await db.update(
      'transactions',
      {'paymentMethodId': null},
      where: 'paymentMethodId = ?',
      whereArgs: [id],
    );
    _changeController.add(null);
  }

  Future<void> clearDatabase(String uid) async {
    final db = await getDatabase(uid);
    await db.execute('DELETE FROM transactions');
    await db.execute('DELETE FROM subcategories');
    await db.execute('DELETE FROM categories');
    await db.execute('DELETE FROM custom_assets');
    _changeController.add(null);
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

import 'dart:math';
import 'package:sqflite/sqflite.dart' hide Transaction;
import 'package:path/path.dart';
import '../models/transaction.dart';

class DatabaseService {
  static Database? _db;

  static Future<Database> get _database async {
    _db ??= await _open();
    return _db!;
  }

  static Future<Database> _open() async {
    final path = join(await getDatabasesPath(), 'hesoyam.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, _) => db.execute('''
        CREATE TABLE transactions (
          id TEXT PRIMARY KEY,
          amount REAL NOT NULL,
          type TEXT NOT NULL,
          merchant TEXT,
          category TEXT NOT NULL DEFAULT 'Other',
          bank TEXT,
          raw_sms TEXT,
          transaction_date TEXT NOT NULL,
          sms_hash TEXT UNIQUE
        )
      '''),
    );
  }

  static String _newId() {
    final rand = Random.secure();
    final bytes = List<int>.generate(16, (_) => rand.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }

  // SMS-imported: ignore duplicates via sms_hash UNIQUE constraint.
  static Future<void> upsertTransaction(Transaction txn) async {
    final db = await _database;
    await db.insert(
      'transactions',
      {
        'id': txn.id ?? _newId(),
        'amount': txn.amount,
        'type': txn.type,
        'merchant': txn.merchant,
        'category': txn.category,
        'bank': txn.bank,
        'raw_sms': txn.rawSms,
        'transaction_date': txn.transactionDate.toIso8601String(),
        'sms_hash': txn.smsHash,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  // Manually added entries — always insert with a fresh ID.
  static Future<void> insertManual(Transaction txn) async {
    final db = await _database;
    await db.insert(
      'transactions',
      {
        'id': _newId(),
        'amount': txn.amount,
        'type': txn.type,
        'merchant': txn.merchant,
        'category': txn.category,
        'bank': txn.bank,
        'raw_sms': txn.rawSms,
        'transaction_date': txn.transactionDate.toIso8601String(),
        'sms_hash': txn.smsHash,
      },
    );
  }

  static Future<void> deleteTransaction(String id) async {
    final db = await _database;
    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  static Future<List<Transaction>> getTransactions({DateTime? from, DateTime? to}) async {
    final db = await _database;
    final since = (from ?? DateTime.now().subtract(const Duration(days: 90))).toIso8601String();
    final until = (to ?? DateTime.now().add(const Duration(days: 1))).toIso8601String();
    final rows = await db.query(
      'transactions',
      where: 'transaction_date >= ? AND transaction_date < ?',
      whereArgs: [since, until],
      orderBy: 'transaction_date DESC',
      limit: 500,
    );
    return rows.map(Transaction.fromMap).toList();
  }

  static Future<List<Transaction>> getAllForAnalytics() async {
    final db = await _database;
    final since = DateTime.now().subtract(const Duration(days: 365)).toIso8601String();
    final rows = await db.query(
      'transactions',
      where: 'transaction_date >= ?',
      whereArgs: [since],
      orderBy: 'transaction_date DESC',
      limit: 2000,
    );
    return rows.map(Transaction.fromMap).toList();
  }
}

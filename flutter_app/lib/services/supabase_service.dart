import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/transaction.dart';

class SupabaseService {
  static SupabaseClient get _db => Supabase.instance.client;

  static Future<void> upsertTransaction(Transaction txn) async {
    await _db.from('transactions').upsert(
      txn.toMap(),
      onConflict: 'sms_hash',
      ignoreDuplicates: true,
    );
  }

  static Future<void> insertManual(Transaction txn) async {
    await _db.from('transactions').insert(txn.toMap());
  }

  static Future<void> deleteTransaction(String id) async {
    await _db.from('transactions').delete().eq('id', id);
  }

  static Future<List<Transaction>> getAllForAnalytics() async {
    final since = DateTime.now().subtract(const Duration(days: 365));
    final rows = await _db
        .from('transactions')
        .select()
        .gte('transaction_date', since.toIso8601String())
        .order('transaction_date', ascending: false)
        .limit(1000);
    return (rows as List).map((r) => Transaction.fromMap(r)).toList();
  }

  static Future<List<Transaction>> getTransactions({DateTime? from, DateTime? to}) async {
    // Filters must precede .order()/.limit() in the Supabase query builder.
    final since = from ?? DateTime.now().subtract(const Duration(days: 90));
    final until = to ?? DateTime.now().add(const Duration(days: 1));
    final rows = await _db
        .from('transactions')
        .select()
        .gte('transaction_date', since.toIso8601String())
        .lt('transaction_date', until.toIso8601String())
        .order('transaction_date', ascending: false)
        .limit(200);
    return (rows as List).map((r) => Transaction.fromMap(r)).toList();
  }
}

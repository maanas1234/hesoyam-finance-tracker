import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'sms_parser.dart';
import 'categorizer.dart';
import 'supabase_service.dart';
import '../models/transaction.dart';

class SmsService {
  static const _lastSyncKey = 'last_sms_sync_ms';

  static Future<bool> requestPermission() async {
    final status = await Permission.sms.request();
    return status.isGranted;
  }

  // Returns number of new transactions synced.
  static Future<int> sync({bool fullSync = false}) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return 0;

    final prefs = await SharedPreferences.getInstance();
    final lastMs = prefs.getInt(_lastSyncKey);

    // Full sync goes back 90 days; incremental goes back to last sync or 7 days.
    final since = fullSync
        ? DateTime.now().subtract(const Duration(days: 90))
        : (lastMs != null
            ? DateTime.fromMillisecondsSinceEpoch(lastMs)
            : DateTime.now().subtract(const Duration(days: 7)));

    final messages = await SmsQuery().querySms(kinds: [SmsQueryKind.inbox]);

    int count = 0;
    for (final sms in messages) {
      final date = sms.date;
      final body = sms.body ?? '';
      final address = sms.address ?? '';

      if (date == null || date.isBefore(since)) continue;
      if (!SmsParser.isTransactionSms(address, body)) continue;

      final parsed = SmsParser.parse(body);
      if (parsed == null) continue;

      final hash = md5
          .convert(utf8.encode('$body${date.millisecondsSinceEpoch}'))
          .toString();

      await SupabaseService.upsertTransaction(Transaction(
        userId: userId,
        amount: parsed.amount,
        type: parsed.type,
        merchant: parsed.merchant,
        category: Categorizer.categorize(parsed.merchant),
        bank: parsed.bank,
        rawSms: body,
        transactionDate: date,
        smsHash: hash,
      ));
      count++;
    }

    await prefs.setInt(_lastSyncKey, DateTime.now().millisecondsSinceEpoch);
    return count;
  }
}

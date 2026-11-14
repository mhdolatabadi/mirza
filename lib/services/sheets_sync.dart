import 'dart:convert';

import 'package:bank_sms_parser/bank_sms_parser.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import 'ledger.dart';
import 'sync_settings.dart';

/// Columns after the id column, in sheet order. Must match what
/// assets/google_apps_script.gs formats.
const sheetHeaders = ['تاریخ', 'ساعت', 'بانک', 'حساب', 'نوع', 'مبلغ (ریال)', 'مانده', 'شرح', 'دسته‌بندی', 'متن پیامک'];

/// Stable id of a transaction: the raw SMS identifies it.
String transactionId(Transaction t) => sha1.convert(utf8.encode(t.raw)).toString().substring(0, 16);

List<Object?> sheetValues(Ledger ledger, Transaction t) => [
      t.date?.toString() ?? '',
      t.time ?? '',
      ledger.bankLabel(t),
      t.account ?? '',
      t.type == TransactionType.credit ? 'واریز' : 'برداشت',
      t.signedAmount,
      t.balance,
      t.description ?? '',
      ledger.categoryOf(t),
      t.raw,
    ];

class SyncResult {
  final int added;
  final int updated;

  const SyncResult(this.added, this.updated);

  bool get changed => added + updated > 0;
}

class SheetsSyncError implements Exception {
  final String message;
  const SheetsSyncError(this.message);

  @override
  String toString() => message;
}

/// Sends new or changed transactions to the Google Sheet. Rows the sheet
/// already has with the same content are skipped, so this is cheap to run
/// often. Oldest transactions go first so the sheet reads top to bottom.
Future<SyncResult> syncToSheet(Ledger ledger, SyncSettings settings, {http.Client? client}) async {
  if (!settings.sheetConfigured) throw const SheetsSyncError('آدرس گوگل شیت تنظیم نشده است.');
  final sent = settings.sent;
  final pending = <String, List<Object?>>{};
  for (final t in ledger.transactions.reversed) {
    final id = transactionId(t);
    final values = sheetValues(ledger, t);
    if (sent[id] != _fingerprint(values)) pending[id] = values;
  }

  var added = 0, updated = 0;
  final c = client ?? http.Client();
  try {
    final ids = pending.keys.toList();
    for (var i = 0; i < ids.length; i += _batchSize) {
      final batch = ids.sublist(i, (i + _batchSize).clamp(0, ids.length));
      final res = await _post(c, settings.sheetUrl, {
        'token': settings.token,
        'headers': sheetHeaders,
        'rows': [for (final id in batch) {'id': id, 'values': pending[id]}],
      });
      added += (res['added'] as num?)?.toInt() ?? 0;
      updated += (res['updated'] as num?)?.toInt() ?? 0;
      for (final id in batch) {
        sent[id] = _fingerprint(pending[id]!);
      }
      await settings.setSent(sent);
    }
  } finally {
    if (client == null) c.close();
  }
  await settings.setLastSync(DateTime.now());
  return SyncResult(added, updated);
}

const _batchSize = 200;

String _fingerprint(List<Object?> values) => sha1.convert(utf8.encode(jsonEncode(values))).toString();

/// Apps Script answers a POST with a redirect to the response, which must be
/// fetched with GET; dart:io does not follow redirects for POST itself.
Future<Map<String, dynamic>> _post(http.Client c, String url, Map<String, dynamic> body) async {
  final req = http.Request('POST', Uri.parse(url))
    ..followRedirects = false
    ..headers['Content-Type'] = 'application/json'
    ..body = jsonEncode(body);
  var res = await http.Response.fromStream(await c.send(req));
  if (res.isRedirect || res.statusCode == 302 || res.statusCode == 303) {
    final location = res.headers['location'];
    if (location == null) throw const SheetsSyncError('پاسخ گوگل نامعتبر بود.');
    res = await c.get(Uri.parse(location));
  }
  if (res.statusCode != 200) throw SheetsSyncError('گوگل شیت خطای ${res.statusCode} داد.');
  final Object? json;
  try {
    json = jsonDecode(res.body);
  } on FormatException {
    throw const SheetsSyncError('پاسخ اسکریپت قابل خواندن نبود. دسترسی اسکریپت باید «Anyone» باشد.');
  }
  if (json is! Map<String, dynamic> || json['ok'] != true) {
    final error = json is Map ? json['error'] : null;
    throw SheetsSyncError(error == 'bad token'
        ? 'رمز این گوشی با اسکریپت نمی‌خواند. اسکریپت را دوباره منتشر کنید.'
        : 'اسکریپت خطا داد: ${error ?? res.body}');
  }
  return json;
}

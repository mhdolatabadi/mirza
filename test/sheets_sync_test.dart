import 'dart:convert';

import 'package:bank_sms_parser/bank_sms_parser.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hesabdar/services/ledger.dart';
import 'package:hesabdar/services/sheets_sync.dart';
import 'package:hesabdar/services/sync_settings.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

const received = JalaliDate(1405, 8, 7);
const execUrl = 'https://script.google.com/macros/s/abc/exec';
const echoUrl = 'https://script.googleusercontent.com/macros/echo?id=1';

final blu = parseSms('بلو\nبرداشت پول\nمحمدحسین عزیز، 557,000ریال از حساب شما پرید.\n'
    'موجودی: 37,693,190 ریال\n۱۱:۵۹\n۱۴۰۵.۰۸.۰۷', receivedOn: received)!;
final paya = parseSms('پايا: 534,600+\n حساب:75009\n مانده:43,566,749\n 0806 - 13:19', receivedOn: received)!;

/// Fakes Apps Script: POST answers 302 to an echo URL that serves the result.
class FakeScript {
  final requests = <Map<String, dynamic>>[];
  final rows = <String, List<dynamic>>{};
  String? response;

  late final client = MockClient((req) async {
    if (req.method == 'POST') {
      expect(req.url.toString(), execUrl);
      final body = jsonDecode(req.body) as Map<String, dynamic>;
      requests.add(body);
      var added = 0, updated = 0;
      for (final r in body['rows'] as List) {
        rows.containsKey(r['id']) ? updated++ : added++;
        rows[r['id'] as String] = r['values'] as List;
      }
      response = jsonEncode({'ok': true, 'added': added, 'updated': updated});
      return http.Response('', 302, headers: {'location': echoUrl});
    }
    expect(req.url.toString(), echoUrl);
    return http.Response.bytes(utf8.encode(response!), 200, headers: {'content-type': 'application/json'});
  });
}

void main() {
  late SyncSettings settings;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    settings = await SyncSettings.open();
    await settings.setSheetUrl(execUrl);
  });

  test('sends new rows once, oldest first, following the redirect', () async {
    final script = FakeScript();
    final ledger = Ledger([blu, paya]); // newest first, as read from the inbox

    final r = await syncToSheet(ledger, settings, client: script.client);
    expect((r.added, r.updated), (2, 0));
    final sent = script.requests.single;
    expect(sent['token'], settings.token);
    expect(sent['headers'], sheetHeaders);
    final rows = sent['rows'] as List;
    expect(rows.map((r) => r['id']), [transactionId(paya), transactionId(blu)]);
    expect(rows[1]['values'], ['1405/08/07', '11:59', 'بلو', '', 'برداشت', -557000, 37693190, 'برداشت پول', 'سایر', blu.raw]);

    final again = await syncToSheet(ledger, settings, client: script.client);
    expect(again.changed, isFalse);
    expect(script.requests, hasLength(1));
  });

  test('re-sends only the row whose category or account name changed', () async {
    final script = FakeScript();
    await syncToSheet(Ledger([blu, paya]), settings, client: script.client);

    final edited = Ledger([blu, paya], categoryOverrides: {blu.raw: 'خرید'});
    final r = await syncToSheet(edited, settings, client: script.client);
    expect((r.added, r.updated), (0, 1));
    expect((script.requests.last['rows'] as List).single['id'], transactionId(blu));
    expect(script.rows[transactionId(blu)]![8], 'خرید');
  });

  test('clearSent makes the next sync send everything again', () async {
    final script = FakeScript();
    await syncToSheet(Ledger([blu, paya]), settings, client: script.client);
    await settings.clearSent();
    final r = await syncToSheet(Ledger([blu, paya]), settings, client: script.client);
    expect(r.updated, 2);
  });

  test('a rejected token is reported and nothing is marked as sent', () async {
    final client = MockClient((req) async => http.Response('{"ok":false,"error":"bad token"}', 200));
    await expectLater(syncToSheet(Ledger([blu]), settings, client: client), throwsA(isA<SheetsSyncError>()));
    expect(settings.sent, isEmpty);
  });

  test('an HTML answer (script not shared with Anyone) is explained', () async {
    final client = MockClient((req) async => http.Response('<html>Sign in</html>', 200));
    await expectLater(
      syncToSheet(Ledger([blu]), settings, client: client),
      throwsA(predicate((e) => e.toString().contains('Anyone'))),
    );
  });

  test('without a URL it refuses to sync', () async {
    await settings.setSheetUrl('');
    await expectLater(syncToSheet(Ledger([blu]), settings), throwsA(isA<SheetsSyncError>()));
  });
}

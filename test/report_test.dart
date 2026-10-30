import 'package:bank_sms_parser/bank_sms_parser.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hesabdar/services/ledger.dart';
import 'package:hesabdar/services/report.dart';

Transaction tx(TransactionType type, int amount, JalaliDate? date, [String raw = '']) =>
    Transaction(bank: null, type: type, amount: amount, date: date, raw: raw);

void main() {
  test('groups by Jalali month, newest first, skipping undated', () {
    final s = monthlySummaries([
      tx(TransactionType.credit, 5500000, const JalaliDate(1405, 8, 3)),
      tx(TransactionType.debit, 557000, const JalaliDate(1405, 8, 7)),
      tx(TransactionType.credit, 20000000, const JalaliDate(1405, 5, 15)),
      tx(TransactionType.debit, 1000, null),
    ]);
    expect(s.map((m) => m.label), ['1405/08', '1405/05']);
    expect(s[0].income, 5500000);
    expect(s[0].expense, 557000);
    expect(s[0].net, 4943000);
    expect(s[0].count, 2);
    expect(s[1].income, 20000000);
  });

  test('category totals for one month, biggest expense first', () {
    final ledger = Ledger([
      tx(TransactionType.debit, 46400, const JalaliDate(1405, 8, 4), 'کارمزد پیامک'),
      tx(TransactionType.debit, 557000, const JalaliDate(1405, 8, 7), 'برداشت پول'),
      tx(TransactionType.debit, 100000, const JalaliDate(1405, 8, 8), 'برداشت دوم'),
      tx(TransactionType.credit, 534600, const JalaliDate(1405, 8, 6), 'پایا'),
      tx(TransactionType.debit, 999, const JalaliDate(1405, 7, 1), 'برداشت مهر'),
    ], categoryOverrides: {'برداشت دوم': 'خرید'});
    final c = categorySummaries(ledger, 1405, 8);
    expect(c.map((s) => s.category), ['سایر', 'خرید', 'کارمزد بانکی', 'انتقال']);
    expect(c[0].expense, 557000);
    expect(c[3].income, 534600);
  });
}

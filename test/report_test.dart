import 'package:bank_sms_parser/bank_sms_parser.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hesabdar/services/report.dart';

Transaction tx(TransactionType type, int amount, JalaliDate? date) =>
    Transaction(bank: null, type: type, amount: amount, date: date, raw: '');

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
}

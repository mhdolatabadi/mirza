import 'package:bank_sms_parser/bank_sms_parser.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hesabdar/services/day_groups.dart';
import 'package:hesabdar/services/format.dart';

Transaction tx(TransactionType type, int amount, JalaliDate? date) =>
    Transaction(bank: null, type: type, amount: amount, date: date, raw: '$type $amount $date');

void main() {
  test('money uses Persian digits and separators, toman drops a zero', () {
    expect(formatMoney(18426000, MoneyUnit.rial), '۱۸٬۴۲۶٬۰۰۰');
    expect(formatMoney(18426000, MoneyUnit.toman), '۱٬۸۴۲٬۶۰۰');
    expect(formatMoney(-46400, MoneyUnit.rial, signed: true), '−۴۶٬۴۰۰');
    expect(formatMoney(534600, MoneyUnit.rial, signed: true), '+۵۳۴٬۶۰۰');
    expect(formatMoney(0, MoneyUnit.rial, signed: true), '۰');
  });

  test('compact amounts', () {
    expect(formatCompact(23674000, MoneyUnit.rial), '۲۳٫۷ م');
    expect(formatCompact(40000000, MoneyUnit.rial), '۴۰ م');
    expect(formatCompact(2500000000, MoneyUnit.rial), '۲٫۵ میلیارد');
    expect(formatCompact(92800, MoneyUnit.rial), '۹۲٬۸۰۰');
  });

  test('month and day titles', () {
    const today = JalaliDate(1405, 8, 7);
    const yesterday = JalaliDate(1405, 8, 6);
    expect(monthTitle(1405, 8), 'آبان ۱۴۰۵');
    expect(dayTitle(today, today, yesterday), 'امروز · ۷ آبان');
    expect(dayTitle(yesterday, today, yesterday), 'دیروز · ۶ آبان');
    expect(dayTitle(const JalaliDate(1405, 5, 15), today, yesterday), '۱۵ مرداد');
    expect(dayTitle(const JalaliDate(1404, 12, 1), today, yesterday), '۱ اسفند ۱۴۰۴');
  });

  test('groups by day, newest first, undated last, with daily net', () {
    final groups = groupByDay([
      tx(TransactionType.debit, 850000, const JalaliDate(1405, 8, 7)),
      tx(TransactionType.credit, 534600, const JalaliDate(1405, 8, 6)),
      tx(TransactionType.debit, 1000, null),
      tx(TransactionType.debit, 430000, const JalaliDate(1405, 8, 7)),
    ]);
    expect(groups.map((g) => g.date), [const JalaliDate(1405, 8, 7), const JalaliDate(1405, 8, 6), null]);
    expect(groups[0].transactions.map((t) => t.amount), [850000, 430000]);
    expect(groups[0].net, -1280000);
    expect(groups[1].net, 534600);
  });
}

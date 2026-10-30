import 'package:bank_sms_parser/bank_sms_parser.dart';

class MonthlySummary {
  final int year;
  final int month;
  final int income;
  final int expense;
  final int count;

  const MonthlySummary(this.year, this.month, this.income, this.expense, this.count);

  int get net => income - expense;
  String get label => '$year/${month.toString().padLeft(2, '0')}';
}

/// Groups transactions by Jalali month, newest month first. Transactions
/// without a date are skipped.
List<MonthlySummary> monthlySummaries(Iterable<Transaction> transactions) {
  final byMonth = <(int, int), List<Transaction>>{};
  for (final t in transactions) {
    final d = t.date;
    if (d == null) continue;
    byMonth.putIfAbsent((d.year, d.month), () => []).add(t);
  }
  final keys = byMonth.keys.toList()
    ..sort((a, b) => b.$1 != a.$1 ? b.$1 - a.$1 : b.$2 - a.$2);
  return [
    for (final k in keys)
      MonthlySummary(
        k.$1,
        k.$2,
        _sum(byMonth[k]!, TransactionType.credit),
        _sum(byMonth[k]!, TransactionType.debit),
        byMonth[k]!.length,
      ),
  ];
}

int _sum(List<Transaction> ts, TransactionType type) =>
    ts.where((t) => t.type == type).fold(0, (s, t) => s + t.amount);

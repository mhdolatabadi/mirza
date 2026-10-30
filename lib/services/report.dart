import 'package:bank_sms_parser/bank_sms_parser.dart';

import 'ledger.dart';

class MonthlySummary {
  final int year;
  final int month;
  final int income;
  final int expense;
  final int count;

  const MonthlySummary(this.year, this.month, this.income, this.expense, this.count);

  int get net => income - expense;
  String get label => monthLabel(year, month);
}

class CategorySummary {
  final String category;
  final int income;
  final int expense;

  const CategorySummary(this.category, this.income, this.expense);
}

String monthLabel(int year, int month) => '$year/${month.toString().padLeft(2, '0')}';

/// Groups transactions by Jalali month, newest month first. Transactions
/// without a date are skipped.
List<MonthlySummary> monthlySummaries(Iterable<Transaction> transactions) {
  final byMonth = _byMonth(transactions);
  return [
    for (final MapEntry(key: k, value: ts) in byMonth.entries)
      MonthlySummary(k.$1, k.$2, _sum(ts, TransactionType.credit), _sum(ts, TransactionType.debit), ts.length),
  ];
}

/// Totals per category for one month, biggest expense first.
List<CategorySummary> categorySummaries(Ledger ledger, int year, int month) {
  final byCategory = <String, List<Transaction>>{};
  for (final t in ledger.transactions) {
    if (t.date?.year != year || t.date?.month != month) continue;
    byCategory.putIfAbsent(ledger.categoryOf(t), () => []).add(t);
  }
  return [
    for (final MapEntry(key: c, value: ts) in byCategory.entries)
      CategorySummary(c, _sum(ts, TransactionType.credit), _sum(ts, TransactionType.debit)),
  ]..sort((a, b) => b.expense != a.expense ? b.expense - a.expense : b.income - a.income);
}

/// Newest month first.
Map<(int, int), List<Transaction>> _byMonth(Iterable<Transaction> transactions) {
  final byMonth = <(int, int), List<Transaction>>{};
  for (final t in transactions) {
    final d = t.date;
    if (d == null) continue;
    byMonth.putIfAbsent((d.year, d.month), () => []).add(t);
  }
  final keys = byMonth.keys.toList()
    ..sort((a, b) => b.$1 != a.$1 ? b.$1 - a.$1 : b.$2 - a.$2);
  return {for (final k in keys) k: byMonth[k]!};
}

int _sum(List<Transaction> ts, TransactionType type) =>
    ts.where((t) => t.type == type).fold(0, (s, t) => s + t.amount);

import 'package:bank_sms_parser/bank_sms_parser.dart';

class DayGroup {
  /// Null for transactions whose SMS had no date.
  final JalaliDate? date;
  final List<Transaction> transactions;

  const DayGroup(this.date, this.transactions);

  /// Credits minus debits for the day.
  int get net => transactions.fold(0, (s, t) => s + t.signedAmount);
}

/// Groups transactions by day, newest day first, keeping the order within a
/// day. Undated transactions go last.
List<DayGroup> groupByDay(Iterable<Transaction> transactions) {
  final byDay = <JalaliDate?, List<Transaction>>{};
  for (final t in transactions) {
    byDay.putIfAbsent(t.date, () => []).add(t);
  }
  final days = byDay.keys.whereType<JalaliDate>().toList()..sort((a, b) => b.compareTo(a));
  return [
    for (final d in days) DayGroup(d, byDay[d]!),
    if (byDay.containsKey(null)) DayGroup(null, byDay[null]!),
  ];
}

/// A Jalali (Shamsi) calendar date. Conversion from Gregorian lives in the
/// app (shamsi_date); the parser only needs to compare and build dates.
class JalaliDate implements Comparable<JalaliDate> {
  final int year;
  final int month;
  final int day;

  const JalaliDate(this.year, this.month, this.day);

  @override
  int compareTo(JalaliDate other) =>
      (year - other.year) * 10000 + (month - other.month) * 100 + (day - other.day);

  @override
  bool operator ==(Object other) =>
      other is JalaliDate && compareTo(other) == 0;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() =>
      '$year/${month.toString().padLeft(2, '0')}/${day.toString().padLeft(2, '0')}';
}

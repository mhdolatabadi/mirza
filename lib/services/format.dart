import 'package:bank_sms_parser/bank_sms_parser.dart';
import 'package:intl/intl.dart';

enum MoneyUnit { rial, toman }

const _persianDigits = '۰۱۲۳۴۵۶۷۸۹';

const monthNames = [
  'فروردین',
  'اردیبهشت',
  'خرداد',
  'تیر',
  'مرداد',
  'شهریور',
  'مهر',
  'آبان',
  'آذر',
  'دی',
  'بهمن',
  'اسفند',
];

final _grouped = NumberFormat.decimalPattern('en');

/// Replaces Latin digits with Persian ones and the thousands comma with `٬`.
String faDigits(Object value) => value
    .toString()
    .replaceAll(',', '٬')
    .replaceAllMapped(RegExp('[0-9]'), (m) => _persianDigits[int.parse(m[0]!)]);

/// Amount in [unit] with Persian digits, e.g. `۱۸٬۴۲۶٬۰۰۰`. [rials] is
/// always in Rials, as the SMS reports it. With [signed], positive amounts
/// get a `+` and negative ones a `−`.
String formatMoney(int rials, MoneyUnit unit, {bool signed = false}) {
  final value = unit == MoneyUnit.toman ? rials ~/ 10 : rials;
  final digits = faDigits(_grouped.format(value.abs()));
  if (!signed || value == 0) return value < 0 ? '−$digits' : digits;
  return value < 0 ? '−$digits' : '+$digits';
}

/// Short amount for tight spots, e.g. `۲۳٫۷ م` for 23,700,000.
String formatCompact(int rials, MoneyUnit unit) {
  final value = (unit == MoneyUnit.toman ? rials ~/ 10 : rials).abs();
  if (value >= 1000000000) return '${faDigits(_oneDecimal(value / 1000000000))} میلیارد';
  if (value >= 1000000) return '${faDigits(_oneDecimal(value / 1000000))} م';
  return faDigits(_grouped.format(value));
}

String _oneDecimal(double v) {
  final s = v.toStringAsFixed(1);
  return (s.endsWith('.0') ? s.substring(0, s.length - 2) : s).replaceAll('.', '٫');
}

String unitLabel(MoneyUnit unit) => unit == MoneyUnit.toman ? 'تومان' : 'ریال';

/// `آبان ۱۴۰۵`.
String monthTitle(int year, int month) => '${monthNames[month - 1]} ${faDigits(year)}';

/// `۷ آبان`, or `امروز · ۷ آبان` / `دیروز · ۶ آبان` relative to [today].
String dayTitle(JalaliDate date, JalaliDate today, JalaliDate yesterday) {
  final label = '${faDigits(date.day)} ${monthNames[date.month - 1]}';
  if (date == today) return 'امروز · $label';
  if (date == yesterday) return 'دیروز · $label';
  return date.year == today.year ? label : '$label ${faDigits(date.year)}';
}

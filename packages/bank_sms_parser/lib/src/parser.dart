import 'jalali_date.dart';
import 'normalize.dart';
import 'transaction.dart';

/// Parses a bank SMS into a [Transaction], or returns null when the message
/// is not a transaction (OTP, ads, ...).
///
/// [receivedOn] is the Jalali date the SMS arrived. It fills in the year for
/// banks that only send month/day.
Transaction? parseSms(String text, {required JalaliDate receivedOn}) {
  final t = normalize(text).trim();
  for (final p in _parsers) {
    final r = p(t, text, receivedOn);
    if (r != null) return r;
  }
  return null;
}

typedef _Parser = Transaction? Function(String t, String raw, JalaliDate receivedOn);

const List<_Parser> _parsers = [_parseBlu, _parseSigned];

const _num = r'(\d[\d,]*)';
final _balanceRe = RegExp(r'(?:مانده|موجودی)\s*:?\s*(-?)\s*' + _num);
final _timeRe = RegExp(r'(?:^|\D)(\d{1,2}):(\d{2})(?!\d)');
final _fullDateRe = RegExp(r'(1[34]\d{2})[./\-](\d{1,2})[./\-](\d{1,2})');

int? _balance(String t) {
  final m = _balanceRe.firstMatch(t);
  if (m == null) return null;
  final v = parseAmount(m.group(2)!);
  return m.group(1) == '-' ? -v : v;
}

/// Blu bank:
///   بلو / برداشت پول / ...، 557,000ریال از حساب شما پرید. / موجودی: ... / 11:59 / 1405.08.07
Transaction? _parseBlu(String t, String raw, JalaliDate receivedOn) {
  if (!t.startsWith('بلو')) return null;
  final TransactionType type;
  if (t.contains('برداشت') || t.contains('پرید')) {
    type = TransactionType.debit;
  } else if (t.contains('واریز') || t.contains('نشست')) {
    type = TransactionType.credit;
  } else {
    return null;
  }
  final amount = RegExp(_num + r'\s*ریال').firstMatch(t);
  if (amount == null) return null;
  final d = _fullDateRe.firstMatch(t);
  final tm = _timeRe.firstMatch(t);
  final lines = t.split('\n').map((l) => l.trim()).toList();
  return Transaction(
    bank: 'blu',
    type: type,
    amount: parseAmount(amount.group(1)!),
    balance: _balance(t),
    date: d == null
        ? null
        : JalaliDate(int.parse(d.group(1)!), int.parse(d.group(2)!), int.parse(d.group(3)!)),
    time: tm == null ? null : _fmtTime(tm.group(1)!, tm.group(2)!),
    description: lines.length > 1 ? lines[1] : null,
    raw: raw,
  );
}

// "+20,000,000" or "534,600+" anywhere on a line, optionally after a label
// like "پایا:".
final _signedRe = RegExp(r'^\s*(?:([^\d\n:+\-]{1,20}):\s*)?(?:([+\-])\s*' + _num +
    r'|' + _num + r'\s*([+\-]))\s*$', multiLine: true);
final _accountRe = RegExp(r'^\s*(?:حساب\s*:\s*)?(\d+(?:[.\-]\d+){0,4})\s*$', multiLine: true);
// "0806 - 13:19" (MMdd - HH:mm) or "08/04_09:58" (MM/dd_HH:mm)
final _shortDateTimeRe =
    RegExp(r'(?:^|\s)(\d{2})/?(\d{2})\s*[-_ ]\s*(\d{1,2}):(\d{2})(?!\d)', multiLine: true);

/// Generic format used by many banks: a signed amount line, account line,
/// balance line and a short date. Lines that match nothing become the
/// description. A balance line is required so that random messages with a
/// "+1,000" line are not mistaken for transactions.
Transaction? _parseSigned(String t, String raw, JalaliDate receivedOn) {
  final m = _signedRe.firstMatch(t);
  final balance = _balance(t);
  if (m == null || balance == null) return null;
  final sign = m.group(2) ?? m.group(5)!;
  final amount = parseAmount(m.group(3) ?? m.group(4)!);
  final label = m.group(1)?.trim();

  String? account;
  final explicitAccount = RegExp(r'حساب\s*:\s*([\d.\-]+)').firstMatch(t);
  if (explicitAccount != null) {
    account = explicitAccount.group(1);
  } else {
    account = _accountRe.firstMatch(t)?.group(1);
  }

  JalaliDate? date;
  String? time;
  final sd = _shortDateTimeRe.firstMatch(t);
  if (sd != null) {
    date = _inferYear(int.parse(sd.group(1)!), int.parse(sd.group(2)!), receivedOn);
    time = _fmtTime(sd.group(3)!, sd.group(4)!);
  } else {
    final d = _fullDateRe.firstMatch(t);
    if (d != null) {
      date = JalaliDate(int.parse(d.group(1)!), int.parse(d.group(2)!), int.parse(d.group(3)!));
    }
    final tm = _timeRe.firstMatch(t);
    if (tm != null) time = _fmtTime(tm.group(1)!, tm.group(2)!);
  }

  final known = <RegExp>[_signedRe, _balanceRe, _shortDateTimeRe, RegExp(r'حساب\s*:'), _accountRe];
  final extra = t
      .split('\n')
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty && !known.any((r) => r.hasMatch(l)))
      .toList();
  final description = [?label, ...extra].join(' - ');

  return Transaction(
    bank: null,
    type: sign == '+' ? TransactionType.credit : TransactionType.debit,
    amount: amount,
    balance: balance,
    account: account,
    date: date,
    time: time,
    description: description.isEmpty ? null : description,
    raw: raw,
  );
}

/// The SMS has no year: take it from the receive date, stepping back a year
/// when the month/day would otherwise land in the future (e.g. an Esfand
/// transaction reported in Farvardin).
JalaliDate _inferYear(int month, int day, JalaliDate receivedOn) {
  final candidate = JalaliDate(receivedOn.year, month, day);
  return candidate.compareTo(receivedOn) > 0
      ? JalaliDate(receivedOn.year - 1, month, day)
      : candidate;
}

String _fmtTime(String h, String m) => '${h.padLeft(2, '0')}:$m';

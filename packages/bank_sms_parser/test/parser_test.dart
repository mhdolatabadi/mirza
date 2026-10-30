import 'package:bank_sms_parser/bank_sms_parser.dart';
import 'package:test/test.dart';

const received = JalaliDate(1405, 8, 7);

Transaction parse(String sms) {
  final t = parseSms(sms, receivedOn: received);
  expect(t, isNotNull, reason: sms);
  return t!;
}

void main() {
  group('Blu', () {
    test('debit', () {
      final t = parse('بلو\n'
          'برداشت پول\n'
          'محمدحسین عزیز، 557,000ریال از حساب شما پرید.\n'
          'موجودی: 37,693,190 ریال\n'
          '۱۱:۵۹\n'
          '۱۴۰۵.۰۸.۰۷');
      expect(t.bank, 'blu');
      expect(t.type, TransactionType.debit);
      expect(t.amount, 557000);
      expect(t.signedAmount, -557000);
      expect(t.balance, 37693190);
      expect(t.time, '11:59');
      expect(t.date, const JalaliDate(1405, 8, 7));
      expect(t.description, 'برداشت پول');
    });

    test('credit', () {
      final t = parse('بلو\n'
          'واریز پول\n'
          'محمدحسین عزیز، 5,500,000ریال به حساب شما نشست.\n'
          'موجودی: 68,456,940 ریال\n'
          '۱۶:۳۹\n'
          '۱۴۰۵.۰۸.۰۳');
      expect(t.bank, 'blu');
      expect(t.type, TransactionType.credit);
      expect(t.amount, 5500000);
      expect(t.balance, 68456940);
      expect(t.time, '16:39');
      expect(t.date, const JalaliDate(1405, 8, 3));
    });
  });

  test('Paya credit with trailing sign and Arabic yeh', () {
    final t = parse('پايا: 534,600+\n'
        ' حساب:75009\n'
        ' مانده:43,566,749\n'
        ' 0806 - 13:19');
    expect(t.type, TransactionType.credit);
    expect(t.amount, 534600);
    expect(t.account, '75009');
    expect(t.balance, 43566749);
    expect(t.date, const JalaliDate(1405, 8, 6));
    expect(t.time, '13:19');
    expect(t.description, 'پایا');
  });

  group('dotted account format', () {
    test('debit with description line', () {
      final t = parse('10.9554759.1\n'
          '-46,400 \n'
          '08/04_09:58\n'
          'مانده: 354,280,269 \n'
          'کارمزد پیامک مرداد ماه 1405');
      expect(t.type, TransactionType.debit);
      expect(t.amount, 46400);
      expect(t.account, '10.9554759.1');
      expect(t.balance, 354280269);
      expect(t.date, const JalaliDate(1405, 8, 4));
      expect(t.time, '09:58');
      expect(t.description, 'کارمزد پیامک مرداد ماه 1405');
    });

    test('credit', () {
      final t = parse('10.9554759.1\n'
          '+20,000,000 \n'
          '05/15_15:03\n'
          'مانده: 2,156,619,905');
      expect(t.type, TransactionType.credit);
      expect(t.amount, 20000000);
      expect(t.balance, 2156619905);
      expect(t.date, const JalaliDate(1405, 5, 15));
      expect(t.time, '15:03');
      expect(t.description, isNull);
    });
  });

  test('month/day after the receive date belongs to the previous year', () {
    final t = parseSms('10.9554759.1\n-1,000\n12/25_10:00\nمانده: 5,000',
        receivedOn: const JalaliDate(1405, 1, 10))!;
    expect(t.date, const JalaliDate(1404, 12, 25));
  });

  test('non-transaction messages are ignored', () {
    for (final sms in [
      'رمز پویا شما: 123456\nاعتبار: 2 دقیقه',
      'بلو\nبه بلو خوش آمدید!',
      'تخفیف ۵۰ درصدی فقط تا امشب',
      'امتیاز شما در باشگاه مشتریان:\n+500',
    ]) {
      expect(parseSms(sms, receivedOn: received), isNull, reason: sms);
    }
  });
}

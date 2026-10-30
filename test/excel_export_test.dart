import 'package:bank_sms_parser/bank_sms_parser.dart';
import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hesabdar/services/excel_export.dart';

void main() {
  test('writes transactions and monthly summary sheets', () {
    const received = JalaliDate(1405, 8, 7);
    final ts = [
      parseSms('بلو\nبرداشت پول\nمحمدحسین عزیز، 557,000ریال از حساب شما پرید.\n'
          'موجودی: 37,693,190 ریال\n۱۱:۵۹\n۱۴۰۵.۰۸.۰۷', receivedOn: received)!,
      parseSms('پايا: 534,600+\n حساب:75009\n مانده:43,566,749\n 0806 - 13:19',
          receivedOn: received)!,
    ];

    final excel = Excel.decodeBytes(buildLedger(ts));
    final rows = excel[transactionsSheet].rows;
    expect(rows, hasLength(3));
    expect(rows[1][0]!.value.toString(), '1405/08/07');
    expect(rows[1][2]!.value.toString(), 'بلو');
    expect((rows[1][5]!.value as IntCellValue).value, -557000);
    expect((rows[2][5]!.value as IntCellValue).value, 534600);
    expect(rows[2][3]!.value.toString(), '75009');

    final summary = excel[summarySheet].rows;
    expect(summary[1][0]!.value.toString(), '1405/08');
    expect((summary[1][3]!.value as IntCellValue).value, 534600 - 557000);
  });
}

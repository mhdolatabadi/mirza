import 'package:bank_sms_parser/bank_sms_parser.dart';
import 'package:excel/excel.dart';

import 'report.dart';

const transactionsSheet = 'تراکنش‌ها';
const summarySheet = 'گزارش ماهانه';

const _bankNames = {'blu': 'بلو'};

String bankLabel(Transaction t) => _bankNames[t.bank] ?? t.bank ?? t.account ?? '';

/// Builds the ledger workbook: one row per transaction plus a monthly
/// summary sheet. Amounts are signed (debits negative) so the column sums.
List<int> buildLedger(List<Transaction> transactions) {
  final excel = Excel.createExcel();
  final defaultSheet = excel.getDefaultSheet()!;
  excel.rename(defaultSheet, transactionsSheet);

  final header = CellStyle(bold: true);
  final tx = excel[transactionsSheet]..isRTL = true;
  tx.appendRow([
    for (final h in ['تاریخ', 'ساعت', 'بانک', 'حساب', 'نوع', 'مبلغ (ریال)', 'مانده', 'شرح', 'دسته‌بندی', 'متن پیامک'])
      TextCellValue(h),
  ]);
  for (final t in transactions) {
    tx.appendRow([
      TextCellValue(t.date?.toString() ?? ''),
      TextCellValue(t.time ?? ''),
      TextCellValue(bankLabel(t)),
      TextCellValue(t.account ?? ''),
      TextCellValue(t.type == TransactionType.credit ? 'واریز' : 'برداشت'),
      IntCellValue(t.signedAmount),
      t.balance == null ? null : IntCellValue(t.balance!),
      TextCellValue(t.description ?? ''),
      TextCellValue(''),
      TextCellValue(t.raw),
    ]);
  }

  final sum = excel[summarySheet]..isRTL = true;
  sum.appendRow([
    for (final h in ['ماه', 'واریز', 'برداشت', 'خالص', 'تعداد']) TextCellValue(h),
  ]);
  for (final m in monthlySummaries(transactions)) {
    sum.appendRow([
      TextCellValue(m.label),
      IntCellValue(m.income),
      IntCellValue(m.expense),
      IntCellValue(m.net),
      IntCellValue(m.count),
    ]);
  }

  for (final s in [tx, sum]) {
    for (var c = 0; c < s.maxColumns; c++) {
      s.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 0)).cellStyle = header;
    }
  }
  return excel.encode()!;
}

import 'package:bank_sms_parser/bank_sms_parser.dart';
import 'package:excel/excel.dart';

import 'ledger.dart';
import 'report.dart';

const transactionsSheet = 'تراکنش‌ها';
const summarySheet = 'گزارش ماهانه';
const categorySheet = 'دسته‌بندی';

/// Builds the ledger workbook: one row per transaction, a monthly summary
/// and per-month category totals. Amounts are signed (debits negative) so
/// the column sums.
List<int> buildLedger(Ledger ledger) {
  final excel = Excel.createExcel();
  excel.rename(excel.getDefaultSheet()!, transactionsSheet);

  final tx = excel[transactionsSheet]..isRTL = true;
  tx.appendRow(_header(['تاریخ', 'ساعت', 'بانک', 'حساب', 'نوع', 'مبلغ (ریال)', 'مانده', 'شرح', 'دسته‌بندی', 'متن پیامک']));
  for (final t in ledger.transactions) {
    tx.appendRow([
      TextCellValue(t.date?.toString() ?? ''),
      TextCellValue(t.time ?? ''),
      TextCellValue(ledger.bankLabel(t)),
      TextCellValue(t.account ?? ''),
      TextCellValue(t.type == TransactionType.credit ? 'واریز' : 'برداشت'),
      IntCellValue(t.signedAmount),
      t.balance == null ? null : IntCellValue(t.balance!),
      TextCellValue(t.description ?? ''),
      TextCellValue(ledger.categoryOf(t)),
      TextCellValue(t.raw),
    ]);
  }

  final months = monthlySummaries(ledger.transactions);
  final sum = excel[summarySheet]..isRTL = true;
  sum.appendRow(_header(['ماه', 'واریز', 'برداشت', 'خالص', 'تعداد']));
  for (final m in months) {
    sum.appendRow([
      TextCellValue(m.label),
      IntCellValue(m.income),
      IntCellValue(m.expense),
      IntCellValue(m.net),
      IntCellValue(m.count),
    ]);
  }

  final cat = excel[categorySheet]..isRTL = true;
  cat.appendRow(_header(['ماه', 'دسته‌بندی', 'واریز', 'برداشت']));
  for (final m in months) {
    for (final c in categorySummaries(ledger, m.year, m.month)) {
      cat.appendRow([
        TextCellValue(m.label),
        TextCellValue(c.category),
        IntCellValue(c.income),
        IntCellValue(c.expense),
      ]);
    }
  }

  final bold = CellStyle(bold: true);
  for (final s in [tx, sum, cat]) {
    for (var c = 0; c < s.maxColumns; c++) {
      s.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 0)).cellStyle = bold;
    }
  }
  return excel.encode()!;
}

List<CellValue> _header(List<String> titles) => [for (final h in titles) TextCellValue(h)];

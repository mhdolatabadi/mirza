import 'package:bank_sms_parser/bank_sms_parser.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hesabdar/services/categories.dart';
import 'package:hesabdar/services/ledger.dart';

Transaction tx(String raw, {String? account}) =>
    Transaction(bank: null, type: TransactionType.debit, amount: 1, raw: raw, account: account);

void main() {
  test('auto category from SMS keywords', () {
    expect(autoCategory(tx('-46,400\nکارمزد پیامک مرداد ماه 1405')), 'کارمزد بانکی');
    expect(autoCategory(tx('پايا: 534,600+')), 'انتقال');
    expect(autoCategory(tx('خرید 850,000')), 'خرید');
    expect(autoCategory(tx('برداشت پول')), otherCategory);
  });

  test('user choices override the guess and name accounts', () {
    final t = tx('برداشت پول', account: '10.9554759.1');
    final ledger = Ledger([t],
        categoryOverrides: {t.raw: 'قبوض'}, accountNames: {'10.9554759.1': 'رسالت'});
    expect(ledger.categoryOf(t), 'قبوض');
    expect(ledger.bankLabel(t), 'رسالت');
    expect(const Ledger([]).bankLabel(t), '10.9554759.1');
  });
}

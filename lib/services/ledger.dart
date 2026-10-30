import 'package:bank_sms_parser/bank_sms_parser.dart';

import 'categories.dart';

const _bankNames = {'blu': 'بلو'};

/// Parsed transactions plus the user's edits: categories they picked and
/// names they gave to accounts.
class Ledger {
  final List<Transaction> transactions;

  /// Keyed by the raw SMS text, which identifies a transaction.
  final Map<String, String> categoryOverrides;

  /// Account number -> name, e.g. `10.9554759.1` -> `رسالت`.
  final Map<String, String> accountNames;

  const Ledger(
    this.transactions, {
    this.categoryOverrides = const {},
    this.accountNames = const {},
  });

  String categoryOf(Transaction t) => categoryOverrides[t.raw] ?? autoCategory(t);

  String bankLabel(Transaction t) =>
      accountNames[t.account] ?? _bankNames[t.bank] ?? t.bank ?? t.account ?? '';
}

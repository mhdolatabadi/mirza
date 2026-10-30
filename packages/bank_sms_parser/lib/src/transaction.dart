import 'jalali_date.dart';

enum TransactionType { debit, credit }

class Transaction {
  /// Bank key, e.g. `blu`. Null when the SMS does not say which bank.
  final String? bank;
  final TransactionType type;

  /// Always positive, in Rials.
  final int amount;
  final int? balance;
  final String? account;
  final JalaliDate? date;

  /// `HH:mm`.
  final String? time;

  /// Free text the bank attached, e.g. "پایا" or "کارمزد پیامک مرداد ماه 1405".
  final String? description;
  final String raw;

  const Transaction({
    required this.bank,
    required this.type,
    required this.amount,
    required this.raw,
    this.balance,
    this.account,
    this.date,
    this.time,
    this.description,
  });

  /// Signed amount: negative for debits.
  int get signedAmount => type == TransactionType.debit ? -amount : amount;

  @override
  String toString() =>
      'Transaction($bank, $type, $amount, balance: $balance, account: $account, '
      'date: $date, time: $time, description: $description)';
}

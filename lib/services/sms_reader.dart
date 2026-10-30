import 'package:bank_sms_parser/bank_sms_parser.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shamsi_date/shamsi_date.dart';

class SmsPermissionDenied implements Exception {}

/// Reads the SMS inbox and returns the messages that parse as bank
/// transactions, newest first.
Future<List<Transaction>> readBankTransactions() async {
  if (!(await Permission.sms.request()).isGranted) throw SmsPermissionDenied();
  final messages = await SmsQuery().querySms(kinds: [SmsQueryKind.inbox], sort: true);
  return [
    for (final m in messages)
      if (m.body != null)
        ?parseSms(m.body!, receivedOn: toJalaliDate(m.date ?? DateTime.now())),
  ];
}

JalaliDate toJalaliDate(DateTime d) {
  final j = Jalali.fromDateTime(d);
  return JalaliDate(j.year, j.month, j.day);
}

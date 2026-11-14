import 'package:bank_sms_parser/bank_sms_parser.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shamsi_date/shamsi_date.dart';

import 'sync_settings.dart';

class SmsPermissionDenied implements Exception {}

class InboxMessage {
  final String sender;
  final String body;
  final DateTime date;

  const InboxMessage(this.sender, this.body, this.date);
}

/// Reads the whole SMS inbox, newest first. With [askPermission] false (in
/// the background) a missing permission throws instead of prompting.
Future<List<InboxMessage>> readInbox({bool askPermission = true}) async {
  final status = askPermission ? await Permission.sms.request() : await Permission.sms.status;
  if (!status.isGranted) throw SmsPermissionDenied();
  final messages = await SmsQuery().querySms(kinds: [SmsQueryKind.inbox], sort: true);
  return [
    for (final m in messages)
      if (m.body != null) InboxMessage(m.address ?? '', m.body!, m.date ?? DateTime.now()),
  ];
}

/// Parses the messages that are bank transactions. When the user picked
/// their bank senders, only those are read, and the parser trusts them.
List<Transaction> parseInbox(List<InboxMessage> messages, {Set<String> senders = const {}}) => [
      for (final m in messages)
        if (senders.isEmpty || senders.contains(m.sender))
          ?parseSms(m.body, receivedOn: toJalaliDate(m.date), trustedSender: senders.isNotEmpty),
    ];

/// Reads the inbox and returns the bank transactions, newest first.
Future<List<Transaction>> readBankTransactions() async {
  final settings = await SyncSettings.open();
  return parseInbox(await readInbox(), senders: settings.senders);
}

JalaliDate toJalaliDate(DateTime d) {
  final j = Jalali.fromDateTime(d);
  return JalaliDate(j.year, j.month, j.day);
}

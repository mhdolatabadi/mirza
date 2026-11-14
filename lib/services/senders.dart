import 'package:bank_sms_parser/bank_sms_parser.dart';

import 'sms_reader.dart';

class SenderSummary {
  final String sender;
  final int messages;

  /// Messages that parse as transactions even without trusting the sender.
  final int transactions;
  final String latest;

  const SenderSummary(this.sender, this.messages, this.transactions, this.latest);

  /// Worth suggesting as a bank sender.
  bool get looksLikeBank => transactions > 0;
}

/// One entry per sender, likely banks first, then by message count.
List<SenderSummary> summarizeSenders(List<InboxMessage> inbox) {
  final bySender = <String, List<InboxMessage>>{};
  for (final m in inbox) {
    if (m.sender.isEmpty) continue;
    bySender.putIfAbsent(m.sender, () => []).add(m);
  }
  final list = [
    for (final MapEntry(key: s, value: ms) in bySender.entries)
      SenderSummary(
        s,
        ms.length,
        ms.where((m) => parseSms(m.body, receivedOn: toJalaliDate(m.date)) != null).length,
        ms.first.body,
      ),
  ];
  return list
    ..sort((a, b) => b.transactions != a.transactions
        ? b.transactions - a.transactions
        : b.messages - a.messages);
}

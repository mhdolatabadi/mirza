import 'package:flutter_test/flutter_test.dart';
import 'package:hesabdar/services/senders.dart';
import 'package:hesabdar/services/sms_reader.dart';

final day = DateTime(2026, 10, 29);

final inbox = [
  InboxMessage('Blu Bank', 'بلو\nبرداشت پول\nمحمدحسین عزیز، 557,000ریال از حساب شما پرید.\nموجودی: 37,693,190 ریال\n11:59\n1405.08.07', day),
  InboxMessage('+98912000', 'سلام، فردا میای؟', day),
  InboxMessage('Blu Bank', 'بلو\nبه بلو خوش آمدید!', day),
  InboxMessage('10009554', '10.9554759.1\n-46,400\n08/04_09:58', day),
  InboxMessage('10009554', '10.9554759.1\n+20,000,000\n05/15_15:03\nمانده: 2,156,619,905', day),
];

void main() {
  test('summarizes senders, likely banks first', () {
    final s = summarizeSenders(inbox);
    expect(s.map((e) => e.sender), ['Blu Bank', '10009554', '+98912000']);
    expect(s[0].messages, 2);
    expect(s[0].transactions, 1);
    expect(s[1].transactions, 1);
    expect(s[2].looksLikeBank, isFalse);
  });

  test('without picked senders every message is checked strictly', () {
    expect(parseInbox(inbox), hasLength(2));
  });

  test('picked senders are the only ones read, and are trusted', () {
    final ts = parseInbox(inbox, senders: {'10009554'});
    // The message without a balance line is accepted from a trusted sender.
    expect(ts.map((t) => t.amount), [46400, 20000000]);
  });
}

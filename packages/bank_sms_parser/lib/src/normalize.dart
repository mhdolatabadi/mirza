const _digits = {
  '۰': '0', '۱': '1', '۲': '2', '۳': '3', '۴': '4',
  '۵': '5', '۶': '6', '۷': '7', '۸': '8', '۹': '9',
  '٠': '0', '١': '1', '٢': '2', '٣': '3', '٤': '4',
  '٥': '5', '٦': '6', '٧': '7', '٨': '8', '٩': '9',
};

const _chars = {
  'ي': 'ی', 'ى': 'ی', 'ك': 'ک', '٬': ',', '،': ',', '\u200c': ' ',
  '\u200f': '', '\u200e': '', '\u202a': '', '\u202b': '', '\u202c': '',
};

/// Converts Persian/Arabic digits to ASCII, unifies Arabic letters with
/// their Persian forms and strips direction marks.
String normalize(String text) {
  final b = StringBuffer();
  for (final r in text.runes) {
    final c = String.fromCharCode(r);
    b.write(_digits[c] ?? _chars[c] ?? c);
  }
  return b.toString().replaceAll('\r\n', '\n');
}

int parseAmount(String s) => int.parse(s.replaceAll(',', ''));

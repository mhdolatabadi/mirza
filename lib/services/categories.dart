import 'package:bank_sms_parser/bank_sms_parser.dart';

const otherCategory = 'سایر';

const categories = [
  'خرید',
  'انتقال',
  'قبوض',
  'اقساط',
  'حقوق',
  'سود',
  'کارمزد بانکی',
  otherCategory,
];

// Checked in order: the first rule whose keyword appears in the SMS wins.
const _rules = [
  ('کارمزد', 'کارمزد بانکی'),
  ('قسط', 'اقساط'),
  ('اقساط', 'اقساط'),
  ('قبض', 'قبوض'),
  ('حقوق', 'حقوق'),
  ('سود', 'سود'),
  ('خرید', 'خرید'),
  ('پوز', 'خرید'),
  ('پایا', 'انتقال'),
  ('ساتنا', 'انتقال'),
  ('انتقال', 'انتقال'),
  ('کارت به کارت', 'انتقال'),
];

/// Guesses a category from keywords in the SMS. The user can override it.
String autoCategory(Transaction t) {
  final text = normalize(t.raw);
  for (final (keyword, category) in _rules) {
    if (text.contains(keyword)) return category;
  }
  return otherCategory;
}

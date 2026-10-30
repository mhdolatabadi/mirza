import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Persists the user's category choices and account names on the phone.
class LedgerStore {
  static const _categoriesKey = 'category_overrides';
  static const _accountsKey = 'account_names';

  final SharedPreferences _prefs;

  LedgerStore(this._prefs);

  static Future<LedgerStore> open() async => LedgerStore(await SharedPreferences.getInstance());

  Map<String, String> get categoryOverrides => _read(_categoriesKey);
  Map<String, String> get accountNames => _read(_accountsKey);

  Future<void> setCategory(String raw, String category) => _put(_categoriesKey, raw, category);

  Future<void> setAccountName(String account, String name) => _put(_accountsKey, account, name);

  Map<String, String> _read(String key) {
    final s = _prefs.getString(key);
    return s == null ? {} : Map<String, String>.from(jsonDecode(s) as Map);
  }

  Future<void> _put(String key, String k, String v) async {
    final m = _read(key);
    if (v.trim().isEmpty) {
      m.remove(k);
    } else {
      m[k] = v.trim();
    }
    await _prefs.setString(key, jsonEncode(m));
  }
}

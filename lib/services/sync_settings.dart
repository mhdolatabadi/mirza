import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

/// Which senders are banks, where the Google Sheet is, and what was already
/// sent to it.
class SyncSettings {
  static const _sendersKey = 'bank_senders';
  static const _urlKey = 'sheet_url';
  static const _tokenKey = 'sheet_token';
  static const _autoKey = 'sheet_auto_sync';
  static const _sentKey = 'sheet_sent';
  static const _lastSyncKey = 'sheet_last_sync';

  final SharedPreferences _prefs;

  SyncSettings(this._prefs);

  static Future<SyncSettings> open() async {
    final prefs = await SharedPreferences.getInstance();
    // The background task writes from another isolate.
    await prefs.reload();
    return SyncSettings(prefs);
  }

  Set<String> get senders => (_prefs.getStringList(_sendersKey) ?? const []).toSet();
  Future<void> setSenders(Set<String> s) => _prefs.setStringList(_sendersKey, s.toList()..sort());

  String get sheetUrl => _prefs.getString(_urlKey) ?? '';
  Future<void> setSheetUrl(String url) => _prefs.setString(_urlKey, url.trim());
  bool get sheetConfigured => sheetUrl.startsWith('https://');

  /// Random secret the Apps Script remembers on the first request, so other
  /// people who learn the URL cannot write to the sheet.
  String get token {
    var t = _prefs.getString(_tokenKey);
    if (t == null) {
      final r = Random.secure();
      t = List.generate(24, (_) => r.nextInt(36).toRadixString(36)).join();
      _prefs.setString(_tokenKey, t);
    }
    return t;
  }

  bool get autoSync => _prefs.getBool(_autoKey) ?? true;
  Future<void> setAutoSync(bool v) => _prefs.setBool(_autoKey, v);

  /// Transaction id -> fingerprint of the row last sent for it.
  Map<String, String> get sent {
    final s = _prefs.getString(_sentKey);
    return s == null ? {} : Map<String, String>.from(jsonDecode(s) as Map);
  }

  Future<void> setSent(Map<String, String> sent) => _prefs.setString(_sentKey, jsonEncode(sent));

  /// Makes the next sync send every row again.
  Future<void> clearSent() => _prefs.remove(_sentKey);

  DateTime? get lastSync {
    final ms = _prefs.getInt(_lastSyncKey);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<void> setLastSync(DateTime t) => _prefs.setInt(_lastSyncKey, t.millisecondsSinceEpoch);
}

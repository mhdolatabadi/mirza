import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'format.dart';

/// Display preferences the user picks in Settings, kept on the phone.
class AppSettings extends ChangeNotifier {
  static const _unitKey = 'money_unit';
  static const _themeKey = 'theme_mode';

  final SharedPreferences _prefs;

  AppSettings(this._prefs);

  static Future<AppSettings> open() async => AppSettings(await SharedPreferences.getInstance());

  MoneyUnit get unit => MoneyUnit.values.asNameMap()[_prefs.getString(_unitKey)] ?? MoneyUnit.rial;

  ThemeMode get themeMode => ThemeMode.values.asNameMap()[_prefs.getString(_themeKey)] ?? ThemeMode.system;

  Future<void> setUnit(MoneyUnit unit) async {
    await _prefs.setString(_unitKey, unit.name);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _prefs.setString(_themeKey, mode.name);
    notifyListeners();
  }
}

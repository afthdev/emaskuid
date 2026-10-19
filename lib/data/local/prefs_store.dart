import 'package:shared_preferences/shared_preferences.dart';

/// Small persistent key-value store: primary toko, watchlist, theme.
class PrefsStore {
  PrefsStore._(this._prefs);

  final SharedPreferences _prefs;

  static const _kPrimary = 'primary_vendor';
  static const _kWatchlist = 'watchlist_sources';
  static const _kTheme = 'theme_mode';
  static const _kHideNominal = 'hide_nominal';

  static Future<PrefsStore> init() async {
    return PrefsStore._(await SharedPreferences.getInstance());
  }

  String? get primaryVendor => _prefs.getString(_kPrimary);

  Future<void> setPrimaryVendor(String? source) async {
    if (source == null) {
      await _prefs.remove(_kPrimary);
    } else {
      await _prefs.setString(_kPrimary, source);
    }
  }

  List<String> get watchlist => _prefs.getStringList(_kWatchlist) ?? const [];

  Future<void> setWatchlist(List<String> sources) async {
    await _prefs.setStringList(_kWatchlist, sources);
  }

  String get themeMode => _prefs.getString(_kTheme) ?? 'system';

  Future<void> setThemeMode(String mode) async {
    await _prefs.setString(_kTheme, mode);
  }

  bool get hideNominal => _prefs.getBool(_kHideNominal) ?? false;

  Future<void> setHideNominal(bool value) async {
    await _prefs.setBool(_kHideNominal, value);
  }
}

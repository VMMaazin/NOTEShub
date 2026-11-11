import 'package:shared_preferences/shared_preferences.dart';

/// Lightweight local key-value storage service.
class LocalStorageService {
  static SharedPreferences? _prefs;

  static Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static SharedPreferences get prefs {
    if (_prefs == null) {
      throw StateError('LocalStorageService must be initialized before use.');
    }
    return _prefs!;
  }

  static Future<bool> setString(String key, String value) =>
      prefs.setString(key, value);

  static String? getString(String key) => prefs.getString(key);

  static Future<bool> remove(String key) => prefs.remove(key);
}


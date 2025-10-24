import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  static const String _kHealthCache = 'health_cache';
  static const String _kMoodCache = 'mood_cache';

  Future<void> saveHealthJson(String json) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kHealthCache, json);
  }

  Future<String?> getHealthJson() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(_kHealthCache);
  }

  Future<void> saveMoodJson(String json) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kMoodCache, json);
  }

  Future<String?> getMoodJson() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(_kMoodCache);
  }

  Future<void> clearAll() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_kHealthCache);
    await sp.remove(_kMoodCache);
  }
}

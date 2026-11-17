import 'package:shared_preferences/shared_preferences.dart';

/// Хранит последнего открытого героя, чтобы на главной был быстрый возврат.
class RecentHeroStore {
  const RecentHeroStore();

  static const String _key = 'recent_hero_id';

  Future<int?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getInt(_key);
    if (value == null || value <= 0) {
      return null;
    }
    return value;
  }

  Future<void> save(int heroId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, heroId);
  }
}

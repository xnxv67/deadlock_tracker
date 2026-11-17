import 'package:shared_preferences/shared_preferences.dart';

/// Сервис хранения избранных героев в SharedPreferences.
class FavoritesService {
  static const String _key = 'favorite_hero_ids';

  Future<Set<int>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? const [];
    return raw.map(int.tryParse).whereType<int>().toSet();
  }

  Future<void> save(Set<int> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, ids.map((id) => id.toString()).toList());
  }

  Future<bool> toggle(int heroId) async {
    final current = await load();
    final liked = !current.contains(heroId);
    if (liked) {
      current.add(heroId);
    } else {
      current.remove(heroId);
    }
    await save(current);
    return liked;
  }
}

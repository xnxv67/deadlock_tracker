import '../datasources/deadlock_api.dart';
import '../dto/hero_dto.dart';
import '../dto/item_asset_dto.dart';
import '../dto/rank_tier_dto.dart';

/// Общий каталог героев, предметов и рангов.
///
/// Все репозитории используют один экземпляр, чтобы не дублировать
/// запросы к `/assets/*` и не парсить одни и те же данные повторно.
class AssetCatalog {
  AssetCatalog(this._api);

  final DeadlockApi _api;

  List<HeroDto>? _heroes;
  Map<int, HeroDto>? _heroMap;
  List<ItemAssetDto>? _items;
  Map<int, ItemAssetDto>? _itemMap;
  List<RankTierDto>? _rankTiers;

  Future<List<HeroDto>> heroes() async {
    final cached = _heroes;
    if (cached != null) {
      return cached;
    }
    final data = await _api.getHeroes();
    _heroes = data;
    _heroMap = {for (final hero in data) hero.id: hero};
    return data;
  }

  Future<Map<int, HeroDto>> heroMap() async {
    await heroes();
    return _heroMap ?? const {};
  }

  Future<List<ItemAssetDto>> items() async {
    final cached = _items;
    if (cached != null) {
      return cached;
    }
    final data = await _api.getItemAssets();
    _items = data;
    _itemMap = {for (final item in data) item.id: item};
    return data;
  }

  Future<Map<int, ItemAssetDto>> itemMap() async {
    await items();
    return _itemMap ?? const {};
  }

  Future<List<RankTierDto>> rankTiers() async {
    final cached = _rankTiers;
    if (cached != null) {
      return cached;
    }
    final data = await _api.getRankTiersCached();
    _rankTiers = data;
    return data;
  }
}

import 'package:dio/dio.dart';

import '../../core/error/app_exception.dart';
import '../../domain/entities/item.dart';
import '../../domain/entities/item_meta.dart';
import '../../domain/repositories/items_repository.dart';
import '../datasources/deadlock_api.dart';
import '../dto/item_asset_dto.dart';
import '../repositories/asset_catalog.dart';

class ItemsRepositoryImpl implements ItemsRepository {
  ItemsRepositoryImpl(this._api, this._catalog);

  final DeadlockApi _api;
  final AssetCatalog _catalog;

  @override
  Future<List<ItemMeta>> getItems() {
    return _guard(() async {
      final statsFuture = _api.getItemStats();
      final assetsFuture = _catalog.items();
      final heroStatsFuture = _api.getHeroStats();
      final stats = await statsFuture;
      final assets = await assetsFuture;
      final heroStats = await heroStatsFuture;

      var totalPicks = 0;
      for (final hero in heroStats) {
        totalPicks += hero.matches;
      }

      final assetsById = <int, ItemAssetDto>{
        for (final asset in assets) asset.id: asset,
      };

      final result = <ItemMeta>[];
      for (final stat in stats) {
        if (stat.matches <= 0) {
          continue;
        }
        final asset = assetsById[stat.itemId];
        result.add(
          ItemMeta(
            item: asset != null
                ? _toItem(asset)
                : Item(
                    id: stat.itemId,
                    name: "Предмет #${stat.itemId}",
                    imageUrl: '',
                    tier: 0,
                    cost: 0,
                    slotType: '',
                  ),
            matches: stat.matches,
            wins: stat.wins,
            pickRate: totalPicks == 0 ? 0 : stat.matches / totalPicks,
            avgBuyTimeS: stat.avgBuyTimeS,
          ),
        );
      }

      result.sort((first, second) {
        final byWinRate = second.winRate.compareTo(first.winRate);
        if (byWinRate != 0) {
          return byWinRate;
        }
        return second.matches.compareTo(first.matches);
      });
      return result;
    });
  }

  Item _toItem(ItemAssetDto dto) {
    return Item(
      id: dto.id,
      name: dto.name,
      imageUrl: dto.imageUrl,
      tier: dto.tier,
      cost: dto.cost,
      slotType: dto.slotType,
    );
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on DioException catch (error) {
      if (error.response?.statusCode == 429) {
        throw const AppException(AppErrorType.rateLimited);
      }
      throw const AppException(AppErrorType.network);
    } on AppException {
      rethrow;
    } catch (_) {
      throw const AppException(AppErrorType.unknown);
    }
  }
}

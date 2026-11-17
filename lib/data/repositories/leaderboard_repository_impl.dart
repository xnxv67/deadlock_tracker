import 'package:dio/dio.dart';

import '../../core/error/app_exception.dart';
import '../../domain/entities/hero.dart';
import '../../domain/entities/leaderboard_player.dart';
import '../../domain/entities/player_badge.dart';
import '../../domain/repositories/leaderboard_repository.dart';
import '../datasources/deadlock_api.dart';
import '../repositories/asset_catalog.dart';

class LeaderboardRepositoryImpl implements LeaderboardRepository {
  LeaderboardRepositoryImpl(this._api, this._catalog);

  static const int _limit = 100;

  final DeadlockApi _api;
  final AssetCatalog _catalog;

  @override
  Future<List<LeaderboardPlayer>> getLeaderboard({
    LeaderboardRegion region = LeaderboardRegion.europe,
  }) {
    return _guard(() async {
      final entries =
          (await _api.getLeaderboard(region: region.apiValue))
              .take(_limit)
              .toList();
      final heroMap = await _catalog.heroMap();
      final rankTiers = await _catalog.rankTiers();

      final singleIds = <int>[];
      for (final entry in entries) {
        if (entry.possibleAccountIds.length == 1) {
          singleIds.add(entry.possibleAccountIds.first);
        }
      }

      final badges = <int, int>{};
      if (singleIds.isNotEmpty) {
        try {
          final ranks = await _api.getPlayerRanks(singleIds);
          for (final rank in ranks) {
            badges[rank.accountId] = rank.badge;
          }
        } catch (_) {
          // Бейджи — украшение: без них таблица всё равно работает.
        }
      }

      final tiers = rankTiers
          .map(
            (dto) => RankTier(
              tier: dto.tier,
              name: dto.name,
              colorHex: dto.colorHex,
            ),
          )
          .toList(growable: false);

      final result = <LeaderboardPlayer>[];
      for (final entry in entries) {
        PlayerBadge? badge;
        if (entry.possibleAccountIds.length == 1) {
          badge = PlayerBadge.fromBadge(
            badges[entry.possibleAccountIds.first] ?? 0,
            tiers,
          );
        }

        final heroes = <Hero>[];
        for (final heroId in entry.topHeroIds) {
          final dto = heroMap[heroId];
          if (dto != null) {
            heroes.add(dto.toEntity());
          }
        }

        result.add(
          LeaderboardPlayer(
            position: entry.position,
            name: entry.name,
            badge: badge,
            topHeroes: heroes,
          ),
        );
      }

      return result;
    });
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

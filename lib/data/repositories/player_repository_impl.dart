import 'package:dio/dio.dart';

import '../../core/error/app_exception.dart';
import '../../domain/entities/hero.dart';
import '../../domain/entities/match_record.dart';
import '../../domain/entities/player_badge.dart';
import '../../domain/entities/player_hero_stat.dart';
import '../../domain/entities/player_profile.dart';
import '../../domain/entities/steam_profile.dart';
import '../../domain/repositories/player_repository.dart';
import '../datasources/deadlock_api.dart';
import '../dto/hero_dto.dart';
import '../dto/match_history_dto.dart';
import '../dto/player_hero_stats_dto.dart';
import '../repositories/asset_catalog.dart';

class PlayerRepositoryImpl implements PlayerRepository {
  PlayerRepositoryImpl(this._api, this._catalog);

  final DeadlockApi _api;
  final AssetCatalog _catalog;

  @override
  Future<List<SteamProfile>> searchSteam(String query) {
    return _guard(() async {
      final results = await _api.steamSearch(query);
      return results
          .map((dto) => SteamProfile(
                accountId: dto.accountId,
                personaName: dto.personaName,
                avatar: dto.avatar,
                avatarMedium: dto.avatarMedium,
                profileUrl: dto.profileUrl,
                countryCode: dto.countryCode,
              ))
          .toList(growable: false);
    });
  }

  @override
  Future<PlayerProfile> getProfile(int accountId) {
    return _guard(() async {
      final heroStatsFuture = _api.getPlayerHeroStats(accountId);
      final matchesFuture = _loadMatches(accountId);
      final badgeFuture = _loadBadge(accountId);

      // Статистика героев критична: без неё показываем ошибку.
      final heroStats = await heroStatsFuture;
      final matches = await matchesFuture;
      final badge = await badgeFuture;
      final heroMap = await _catalog.heroMap();

      final heroes = <PlayerHeroStat>[];
      for (final stat in heroStats) {
        if (stat.heroId <= 0) {
          continue;
        }
        heroes.add(
          PlayerHeroStat(
            hero: heroMap[stat.heroId]?.toEntity() ?? _fallbackHero(stat),
            matches: stat.matches,
            wins: stat.wins,
            kills: stat.kills,
            deaths: stat.deaths,
            assists: stat.assists,
          ),
        );
      }

      heroes.sort((first, second) => second.matches.compareTo(first.matches));

      return PlayerProfile(
        accountId: accountId,
        heroes: heroes,
        matches: _toMatches(matches, heroMap),
        badge: badge,
      );
    });
  }

  List<MatchRecord> _toMatches(
    List<MatchHistoryDto> source,
    Map<int, HeroDto> heroMap,
  ) {
    final result = <MatchRecord>[];
    for (final match in source.take(20)) {
      final heroId = match.heroId;
      if (heroId <= 0) {
        continue;
      }
      final heroDto = heroMap[heroId];
      result.add(
        MatchRecord(
          matchId: match.matchId,
          hero:
              heroDto?.toEntity() ??
              Hero(
                id: heroId,
                name: "Герой #$heroId",
                role: '',
                imageUrl: '',
                cardUrl: '',
              ),
          isWin: match.isWin,
          kills: match.kills,
          deaths: match.deaths,
          assists: match.assists,
          durationSeconds: match.durationSeconds,
          startTime: match.startTime,
          heroDamage: match.heroDamage,
          buildingDamage: match.buildingDamage,
          netWorth: match.netWorth,
          lastHits: match.lastHits,
          denies: match.denies,
        ),
      );
    }
    return result;
  }

  Hero _fallbackHero(PlayerHeroStatsDto stat) {
    return Hero(
      id: stat.heroId,
      name: "Герой #${stat.heroId}",
      role: '',
      imageUrl: '',
      cardUrl: '',
    );
  }

  Future<List<MatchHistoryDto>> _loadMatches(int accountId) async {
    try {
      return await _api.getMatchHistory(accountId);
    } catch (_) {
      // История матчей не должна ломать экран со статистикой героев.
      return const [];
    }
  }

  Future<PlayerBadge?> _loadBadge(int accountId) async {
    try {
      final ranks = await _api.getPlayerRanks([accountId]);
      if (ranks.isEmpty) {
        return null;
      }
      final tiers = await _catalog.rankTiers();
      return PlayerBadge.fromBadge(
        ranks.first.badge,
        tiers
            .map(
              (dto) => RankTier(
                tier: dto.tier,
                name: dto.name,
                colorHex: dto.colorHex,
              ),
            )
            .toList(growable: false),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Map<int, PlayerBadge>> getRanks(List<int> accountIds) async {
    final ids = accountIds.where((id) => id > 0).toSet().toList();
    if (ids.isEmpty) {
      return const {};
    }
    return _guard(() async {
      final ranks = await _api.getPlayerRanks(ids);
      final tiers = (await _catalog.rankTiers())
          .map(
            (dto) => RankTier(
              tier: dto.tier,
              name: dto.name,
              colorHex: dto.colorHex,
            ),
          )
          .toList(growable: false);

      final result = <int, PlayerBadge>{};
      for (final rank in ranks) {
        final badge = PlayerBadge.fromBadge(rank.badge, tiers);
        if (badge != null) {
          result[rank.accountId] = badge;
        }
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

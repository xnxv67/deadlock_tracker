import 'package:dio/dio.dart';

import '../../core/error/app_exception.dart';
import '../../domain/entities/hero.dart';
import '../../domain/entities/match_record.dart';
import '../../domain/entities/player_analysis.dart';
import '../../domain/entities/player_badge.dart';
import '../../domain/entities/player_hero_stat.dart';
import '../../domain/entities/player_profile.dart';
import '../../domain/entities/steam_profile.dart';
import '../../domain/repositories/player_repository.dart';
import '../datasources/deadlock_api.dart';
import '../dto/hero_dto.dart';
import '../dto/lane_matchup_dto.dart';
import '../dto/lane_soul_curve_dto.dart';
import '../dto/match_history_dto.dart';
import '../dto/performance_curve_dto.dart';
import '../dto/player_hero_stats_dto.dart';
import '../dto/player_metrics_dto.dart';
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
          .map(
            (dto) => SteamProfile(
              accountId: dto.accountId,
              personaName: dto.personaName,
              avatar: dto.avatar,
              avatarMedium: dto.avatarMedium,
              profileUrl: dto.profileUrl,
              countryCode: dto.countryCode,
            ),
          )
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
            mvpFirst: stat.mvpFirst,
            mvpSecond: stat.mvpSecond,
            mvpThird: stat.mvpThird,
            mvpRatedMatches: stat.mvpRatedMatches,
            accuracy: stat.accuracy,
            critShotRate: stat.critShotRate,
            netWorthPerMin: stat.netWorthPerMin,
            lastHitsPerMin: stat.lastHitsPerMin,
            deniesPerMin: stat.deniesPerMin,
            damagePerMin: stat.damagePerMin,
            permanentBuffs: stat.permanentBuffs,
            timePlayedSeconds: stat.timePlayedSeconds,
            lastPlayed: stat.lastPlayed,
            endingLevel: stat.endingLevel,
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

  @override
  Future<PlayerAnalysis> getAnalysis(int accountId) {
    return _guard(() async {
      final results = await Future.wait<dynamic>([
        _softRequest(_api.getPlayerLaneMatchups(accountId)),
        _softRequest(_api.getPlayerLaneSoulCurve(accountId)),
        _softRequest(_api.getPlayerPerformanceCurve(accountId)),
        _softRequest(_api.getPlayerMetrics(accountId)),
      ]);

      final matchups = results[0] as List<LaneMatchupDto>;
      final soulRows = results[1] as List<LaneSoulCurveDto>;
      final curveRows = results[2] as List<PerformanceCurveDto>;
      final metricsDto = results[3] as PlayerMetricsDto?;

      return PlayerAnalysis(
        lanes: _aggregateLanes(matchups),
        soulCurve: _aggregateSoulCurve(soulRows),
        curve: _toCurvePoints(curveRows),
        metrics: _toMetrics(metricsDto),
      );
    });
  }

  Future<T> _softRequest<T>(Future<T> request) async {
    try {
      return await request;
    } catch (_) {
      if (T == List<LaneMatchupDto>) {
        return const <LaneMatchupDto>[] as T;
      }
      if (T == List<LaneSoulCurveDto>) {
        return const <LaneSoulCurveDto>[] as T;
      }
      if (T == List<PerformanceCurveDto>) {
        return const <PerformanceCurveDto>[] as T;
      }
      return null as T;
    }
  }

  List<LanePerformance> _aggregateLanes(List<LaneMatchupDto> rows) {
    final matches = <int, int>{};
    final wins = <int, int>{};
    final diffWeight = <int, double>{};
    final diffTotal = <int, double>{};

    for (final row in rows) {
      if (row.laneId <= 0) {
        continue;
      }
      matches[row.laneId] = (matches[row.laneId] ?? 0) + row.matches;
      wins[row.laneId] = (wins[row.laneId] ?? 0) + row.wins;
      final weight = (row.sampleMatches > 0 ? row.sampleMatches : row.matches)
          .toDouble();
      diffWeight[row.laneId] = (diffWeight[row.laneId] ?? 0) + weight;
      diffTotal[row.laneId] =
          (diffTotal[row.laneId] ?? 0) + row.netWorthDiff * weight;
    }

    final result = <LanePerformance>[];
    for (final laneId in matches.keys) {
      final laneMatches = matches[laneId] ?? 0;
      final weight = diffWeight[laneId] ?? 0;
      result.add(
        LanePerformance(
          laneId: laneId,
          matches: laneMatches,
          wins: wins[laneId] ?? 0,
          netWorthDiff: weight <= 0 ? 0 : (diffTotal[laneId] ?? 0) / weight,
        ),
      );
    }
    result.sort((first, second) {
      final byMatches = second.matches.compareTo(first.matches);
      return byMatches != 0 ? byMatches : first.laneId.compareTo(second.laneId);
    });
    return result;
  }

  List<LaneSoulPoint> _aggregateSoulCurve(List<LaneSoulCurveDto> rows) {
    final weights = <int, double>{};
    final totals = <int, double>{};

    for (final row in rows) {
      final length = row.sampleTimes.length;
      for (var index = 0; index < length; index++) {
        if (index >= row.diffs.length) {
          break;
        }
        final seconds = row.sampleTimes[index];
        final weight = index < row.sampleMatches.length
            ? row.sampleMatches[index].toDouble()
            : 1.0;
        final safeWeight = weight <= 0 ? 1.0 : weight;
        weights[seconds] = (weights[seconds] ?? 0) + safeWeight;
        totals[seconds] =
            (totals[seconds] ?? 0) + row.diffs[index] * safeWeight;
      }
    }

    final seconds = weights.keys.toList()..sort();
    return [
      for (final second in seconds)
        LaneSoulPoint(
          seconds: second,
          netWorthDiff: (totals[second] ?? 0) / (weights[second] ?? 1),
        ),
    ];
  }

  List<PlayerCurvePoint> _toCurvePoints(List<PerformanceCurveDto> rows) {
    return [
      for (final row in rows)
        PlayerCurvePoint(
          gameTime: row.gameTime,
          netWorth: row.netWorth,
          kills: row.kills,
          deaths: row.deaths,
          assists: row.assists,
          playerDamage: row.playerDamage,
          creepKills: row.creepKills,
          denies: row.denies,
        ),
    ];
  }

  Map<String, MetricRange> _toMetrics(PlayerMetricsDto? dto) {
    if (dto == null) {
      return const {};
    }
    return {
      for (final entry in dto.metrics.entries)
        entry.key: MetricRange(
          key: entry.key,
          avg: entry.value.avg,
          std: entry.value.std,
          p25: entry.value.p25,
          p50: entry.value.p50,
          p75: entry.value.p75,
        ),
    };
  }

  List<MatchRecord> _toMatches(
    List<MatchHistoryDto> source,
    Map<int, HeroDto> heroMap,
  ) {
    final result = <MatchRecord>[];
    for (final match in source.take(50)) {
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
          heroLevel: match.heroLevel,
          rankedBadge: match.rankedBadge,
          rankedDelta: match.rankedDelta,
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

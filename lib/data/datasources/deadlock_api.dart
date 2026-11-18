import 'dart:convert';

import 'package:dio/dio.dart';

import '../../core/cache/api_cache.dart';
import '../dto/ability_asset_dto.dart';
import '../dto/hero_build_dto.dart';
import '../dto/hero_build_stats_dto.dart';
import '../dto/hero_counter_dto.dart';
import '../dto/hero_dto.dart';
import '../dto/ability_order_dto.dart';
import '../dto/hero_stats_dto.dart';
import '../dto/hero_trend_point_dto.dart';
import '../dto/hero_synergy_dto.dart';
import '../dto/item_asset_dto.dart';
import '../dto/item_stats_dto.dart';
import '../dto/json_utils.dart';
import '../dto/leaderboard_entry_dto.dart';
import '../dto/popular_item_dto.dart';
import '../dto/match_history_dto.dart';
import '../dto/player_hero_stats_dto.dart';
import '../dto/player_rank_dto.dart';
import '../dto/rank_tier_dto.dart';
import '../dto/steam_profile_dto.dart';

class DeadlockApi {
  DeadlockApi(this._dio, this._cache);

  static const Duration _assetsTtl = Duration(hours: 12);
  static const String _heroesKey = 'heroes_compact_v1';
  static const String _itemsKey = 'items_compact_v1';
  static const String _abilitiesKey = 'abilities_compact_v1';

  final Dio _dio;
  final ApiCache _cache;

  Future<List<HeroDto>> getHeroes() async {
    final cached = await _cache.read(_heroesKey, overrideTtl: _assetsTtl);
    if (cached is List && cached.isNotEmpty) {
      final heroes = cached
          .map(jsonMap)
          .where((item) => item.isNotEmpty)
          .map(HeroDto.fromCompactJson)
          .where((item) => item.id > 0)
          .toList();
      if (heroes.isNotEmpty) {
        return heroes;
      }
    }

    final data = await _get('/assets/heroes', useCache: false);
    final heroes = jsonList(data)
        .map(jsonMap)
        .where((item) => item.isNotEmpty)
        .map(HeroDto.fromJson)
        .where((item) => item.id > 0)
        .toList();

    if (heroes.isNotEmpty) {
      await _cache.write(
        _heroesKey,
        heroes.map((hero) => hero.toCompactJson()).toList(),
        overrideTtl: _assetsTtl,
      );
    }
    return heroes;
  }

  Future<List<ItemAssetDto>> getItemAssets() async {
    final cached = await _cache.read(_itemsKey, overrideTtl: _assetsTtl);
    if (cached is List && cached.isNotEmpty) {
      final items = cached
          .map(jsonMap)
          .where((item) => item.isNotEmpty)
          .map(ItemAssetDto.fromCompactJson)
          .where((item) => item.id > 0)
          .toList();
      if (items.isNotEmpty) {
        return items;
      }
    }

    final data = await _get('/assets/items', useCache: false);
    final items = jsonList(data)
        .map(jsonMap)
        .where((item) => item.isNotEmpty)
        .where((item) => jsonString(item['type']) == 'upgrade')
        .map(ItemAssetDto.fromJson)
        .where((item) => item.id > 0)
        .toList();

    if (items.isNotEmpty) {
      await _cache.write(
        _itemsKey,
        items.map((item) => item.toCompactJson()).toList(),
        overrideTtl: _assetsTtl,
      );
    }
    return items;
  }

  /// Способности всех героев (id → имя/иконка) для путей прокачки.
  Future<List<AbilityAssetDto>> getAbilities() async {
    final cached = await _cache.read(_abilitiesKey, overrideTtl: _assetsTtl);
    if (cached is List && cached.isNotEmpty) {
      final abilities = cached
          .map(jsonMap)
          .where((item) => item.isNotEmpty)
          .map(AbilityAssetDto.fromCompactJson)
          .where((item) => item.id > 0)
          .toList();
      if (abilities.isNotEmpty) {
        return abilities;
      }
    }

    final data = await _get('/assets/items', query: {'type': 'ability'});
    final abilities = jsonList(data)
        .map(jsonMap)
        .where((item) => item.isNotEmpty)
        .map(AbilityAssetDto.fromJson)
        .where((item) => item.id > 0)
        .toList();

    if (abilities.isNotEmpty) {
      await _cache.write(
        _abilitiesKey,
        abilities.map((a) => a.toCompactJson()).toList(),
        overrideTtl: _assetsTtl,
      );
    }
    return abilities;
  }

  /// Популярные предметы героя по стадиям (early/mid/late).
  /// Возвращает map: 'early_game' | 'mid_game' | 'late_game' → список.
  Future<Map<String, List<PopularItemDto>>> getHeroPopularItems(
    int heroId,
  ) async {
    final data = await _get('/assets/heroes/$heroId');
    final root = jsonMap(data);
    final popular = jsonMap(root['popular_items']);
    final result = <String, List<PopularItemDto>>{};
    for (final stage in const ['early_game', 'mid_game', 'late_game']) {
      result[stage] = jsonList(popular[stage])
          .map(jsonMap)
          .where((item) => item.isNotEmpty)
          .map(PopularItemDto.fromJson)
          .where((item) => item.itemId > 0)
          .toList();
    }
    return result;
  }

  Future<List<HeroStatsDto>> getHeroStats({
    int? minDurationSeconds,
    int? maxDurationSeconds,
  }) async {
    final query = <String, dynamic>{};
    if (minDurationSeconds != null) {
      query['min_duration_s'] = minDurationSeconds;
    }
    if (maxDurationSeconds != null) {
      query['max_duration_s'] = maxDurationSeconds;
    }

    final data = await _get(
      '/analytics/hero-stats',
      query: query.isEmpty ? null : query,
    );
    return _parseList(
      data,
      HeroStatsDto.fromJson,
    ).where((item) => item.heroId > 0).toList();
  }

  /// Тренд винрейта героя по дням.
  Future<List<HeroTrendPointDto>> getHeroTrend(int heroId) async {
    final data = await _get(
      '/analytics/hero-stats',
      query: {'bucket': 'start_time_day'},
    );
    return _parseList(
      data,
      HeroTrendPointDto.fromJson,
    ).where((item) => item.heroId == heroId && item.matches > 0).toList();
  }

  Future<List<HeroCounterDto>> getHeroCounters() async {
    final data = await _get('/analytics/hero-counter-stats');
    return _parseList(
      data,
      HeroCounterDto.fromJson,
    ).where((item) => item.heroId > 0 && item.enemyHeroId > 0).toList();
  }

  Future<List<HeroSynergyDto>> getHeroSynergies() async {
    final data = await _get('/analytics/hero-synergy-stats');
    return _parseList(
      data,
      HeroSynergyDto.fromJson,
    ).where((item) => item.heroId1 > 0 && item.heroId2 > 0).toList();
  }

  Future<List<ItemStatsDto>> getItemStats() async {
    final data = await _get('/analytics/item-stats');
    return _parseList(
      data,
      ItemStatsDto.fromJson,
    ).where((item) => item.itemId > 0).toList();
  }

  Future<List<PlayerHeroStatsDto>> getPlayerHeroStats(int accountId) {
    return getPlayersHeroStats([accountId]);
  }

  /// Статистика героев сразу для нескольких игроков (до 1000 account_id).
  Future<List<PlayerHeroStatsDto>> getPlayersHeroStats(
    Iterable<int> accountIds,
  ) async {
    final ids = accountIds.where((id) => id > 0).toSet().toList()..sort();
    if (ids.isEmpty) {
      return const [];
    }

    final data = await _get(
      '/players/hero-stats',
      query: {'account_ids': ids.join(',')},
    );
    return _parseList(
      data,
      PlayerHeroStatsDto.fromJson,
    ).where((item) => item.heroId > 0).toList();
  }

  /// Последние матчи игрока.
  ///
  /// Эндпоинт отдаёт всю историю (несколько тысяч записей), поэтому в кэш
  /// кладём только 20 самых свежих матчей в компактном виде.
  Future<List<MatchHistoryDto>> getMatchHistory(int accountId) async {
    final key = 'matches_v1_$accountId';
    final cached = await _cache.read(key);
    if (cached is List && cached.isNotEmpty) {
      return cached
          .map(jsonMap)
          .where((item) => item.isNotEmpty)
          .map(MatchHistoryDto.fromCompactJson)
          .where((item) => item.matchId > 0)
          .toList();
    }

    final data = await _get(
      '/players/$accountId/match-history',
      useCache: false,
    );
    final matches =
        _parseList(
          data,
          MatchHistoryDto.fromJson,
        ).where((item) => item.matchId > 0).toList()..sort(
          (first, second) => second.startTime.compareTo(first.startTime),
        );

    final recent = matches.take(20).toList(growable: false);
    if (recent.isNotEmpty) {
      await _cache.write(
        key,
        recent.map((match) => match.toCompactJson()).toList(),
      );
    }
    return recent;
  }

  Future<List<PlayerRankDto>> getPlayerRanks(List<int> accountIds) async {
    final ids = accountIds.where((id) => id > 0).toSet().toList()..sort();
    if (ids.isEmpty) {
      return const [];
    }

    final data = await _get('/players/rank', query: {'account_ids': ids});
    return _parseList(
      data,
      PlayerRankDto.fromJson,
    ).where((item) => item.accountId > 0).toList();
  }

  Future<List<RankTierDto>> getRankTiers() async {
    final data = await _get('/assets/ranks', useCache: false);
    final tiers = _parseList(
      data,
      RankTierDto.fromJson,
    ).where((item) => item.tier >= 0).toList();

    if (tiers.isNotEmpty) {
      await _cache.write(
        'rank_tiers_v1',
        tiers
            .map(
              (tier) => {
                'tier': tier.tier,
                'name': tier.name,
                'color': tier.colorHex,
              },
            )
            .toList(),
        overrideTtl: _assetsTtl,
      );
    }
    return tiers;
  }

  Future<List<RankTierDto>> getRankTiersCached() async {
    final cached = await _cache.read('rank_tiers_v1', overrideTtl: _assetsTtl);
    if (cached is List && cached.isNotEmpty) {
      final tiers = cached
          .map(jsonMap)
          .where((item) => item.isNotEmpty)
          .map(
            (item) => RankTierDto(
              tier: jsonInt(item['tier']),
              name: jsonString(item['name']),
              colorHex: jsonString(item['color']),
            ),
          )
          .where((item) => item.name.isNotEmpty)
          .toList();
      if (tiers.isNotEmpty) {
        return tiers;
      }
    }
    return getRankTiers();
  }

  Future<List<LeaderboardEntryDto>> getLeaderboard({
    String region = 'Europe',
  }) async {
    final data = await _get('/leaderboard/$region');
    final root = jsonMap(data);
    final entries = jsonList(root['entries'])
        .map(jsonMap)
        .where((item) => item.isNotEmpty)
        .toList();

    final result = <LeaderboardEntryDto>[];
    for (var index = 0; index < entries.length; index++) {
      final entry = LeaderboardEntryDto.fromJson(
        entries[index],
        fallbackPosition: index + 1,
      );
      result.add(entry);
    }
    result.sort((first, second) => first.position.compareTo(second.position));
    return result;
  }

  Future<List<HeroBuildStatsDto>> getHeroBuildStats(
    int heroId, {
    int minMatches = 50,
  }) async {
    final data = await _get(
      '/analytics/hero-build-stats/$heroId',
      query: {'min_matches': minMatches},
    );
    return _parseList(
      data,
      HeroBuildStatsDto.fromJson,
    ).where((item) => item.buildId > 0 && item.matches > 0).toList();
  }

  Future<HeroBuildDto?> getHeroBuild(int heroId, int buildId) async {
    try {
      final data = await _get('/builds/$heroId/$buildId');
      final dto = HeroBuildDto.fromJson(jsonMap(data));
      if (dto.buildId <= 0) {
        return null;
      }
      return dto;
    } catch (_) {
      return null;
    }
  }

  Future<List<AbilityOrderDto>> getAbilityOrderStats(int heroId) async {
    final data = await _get(
      '/analytics/ability-order-stats',
      query: {'hero_id': heroId},
    );
    return _parseList(
      data,
      AbilityOrderDto.fromJson,
    ).where((item) => item.abilities.isNotEmpty && item.matches > 0).toList();
  }

  Future<List<SteamProfileDto>> steamSearch(String query) async {
    if (query.trim().isEmpty) return const [];
    final data = await _get(
      '/players/steam-search',
      query: {'search_query': query.trim()},
    );
    return _parseList(
      data,
      SteamProfileDto.fromJson,
    ).where((item) => item.accountId > 0).toList();
  }

  List<T> _parseList<T>(dynamic data, T Function(Map<String, dynamic>) parser) {
    return jsonList(data)
        .map(jsonMap)
        .where((item) => item.isNotEmpty)
        .map(parser)
        .toList();
  }

  Future<dynamic> _get(
    String path, {
    Map<String, dynamic>? query,
    bool useCache = true,
  }) async {
    final key = _cache.keyFor(path, query);
    if (useCache) {
      final cached = await _cache.read(key);
      if (cached != null) {
        return cached;
      }
    }

    final response = await _dio.get<dynamic>(path, queryParameters: query);
    final data = response.data is String
        ? jsonDecode(response.data as String)
        : response.data;

    if (useCache && data != null) {
      await _cache.write(key, data);
    }
    return data;
  }
}

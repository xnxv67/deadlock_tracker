import 'package:dio/dio.dart';

import '../../core/error/app_exception.dart';
import '../../domain/entities/hero.dart';
import '../../domain/entities/hero_ability_path.dart';
import '../../domain/entities/build_category.dart';
import '../../domain/entities/hero_build.dart';
import '../../domain/entities/hero_counter.dart';
import '../../domain/entities/hero_detailed_stats.dart';
import '../../domain/entities/hero_duration_stat.dart';
import '../../domain/entities/hero_meta.dart';
import '../../domain/entities/hero_synergy.dart';
import '../../domain/entities/hero_trend.dart';
import '../../domain/entities/popular_item.dart';
import '../../domain/entities/item.dart';
import '../../domain/repositories/hero_repository.dart';
import '../api/api_client.dart';
import '../datasources/deadlock_api.dart';
import '../dto/hero_build_stats_dto.dart';
import '../dto/hero_counter_dto.dart';
import '../dto/hero_dto.dart';
import '../dto/hero_stats_dto.dart';
import '../dto/ability_asset_dto.dart';
import '../dto/hero_synergy_dto.dart';
import '../dto/item_asset_dto.dart';
import '../repositories/asset_catalog.dart';

class HeroRepositoryImpl implements HeroRepository {
  HeroRepositoryImpl(
    this._api,
    this._catalog, {
    ApiClient? apiClient,
  }) : _apiClient = apiClient ?? ApiClient();

  static const List<_DurationBucket> _durationBuckets = [
    _DurationBucket('до 20 мин', 0, 1200),
    _DurationBucket('20–30 мин', 1200, 1800),
    _DurationBucket('30–40 мин', 1800, 2400),
    _DurationBucket('40+ мин', 2400, null),
  ];

  static const int _minSynergyMatches = 500;

  final DeadlockApi _api;
  final AssetCatalog _catalog;
  final ApiClient _apiClient;

  List<HeroStatsDto>? _statsCache;
  List<HeroCounterDto>? _countersCache;
  List<HeroSynergyDto>? _synergyCache;
  final Map<int, List<HeroDurationStat>> _durationsCache = {};
  final Map<int, List<HeroBuild>> _buildsCache = {};
  final Map<int, HeroDetailedStats?> _detailedCache = {};
  final Map<int, HeroAbilityPath?> _abilityPathCache = {};
  final Map<int, Map<String, List<PopularItem>>> _popularItemsCache = {};
  final Map<int, HeroTrend?> _trendCache = {};
  Map<int, AbilityAssetDto>? _abilityMap;
  Map<int, double>? _itemBuyTimes;

  @override
  Future<List<Hero>> searchHeroes(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return Future.value(const <Hero>[]);
    }

    return _guard(() async {
      final data = await _apiClient.getList('/assets/heroes');

      final result = <Hero>[];
      for (final item in data) {
        if (item is! Map) {
          continue;
        }
        final dto = HeroDto.fromJson(Map<String, dynamic>.from(item));
        if (dto.id <= 0 || !dto.playerSelectable || dto.disabled) {
          continue;
        }
        final haystack = '${dto.name} ${dto.role}'.toLowerCase();
        if (!haystack.contains(normalized)) {
          continue;
        }
        result.add(dto.toEntity());
      }

      result.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
      return result;
    });
  }

  @override
  Future<List<HeroMeta>> getMeta() {
    return _guard(() async {
      final heroes = await _catalog.heroes();
      final stats = await _loadStats();

      final heroesById = {
        for (final hero in heroes)
          if (hero.playerSelectable && !hero.disabled) hero.id: hero,
      };

      var totalPicks = 0;
      for (final stat in stats) {
        if (heroesById.containsKey(stat.heroId)) {
          totalPicks += stat.matches;
        }
      }

      final selected = <HeroMeta>[];
      var totalMatches = 0;
      var totalWins = 0;
      for (final stat in stats) {
        final dto = heroesById[stat.heroId];
        if (dto == null || stat.matches == 0) {
          continue;
        }
        selected.add(
          HeroMeta(
            hero: dto.toEntity(),
            matches: stat.matches,
            wins: stat.wins,
            pickRate: totalPicks == 0 ? 0 : stat.matches / totalPicks,
          ),
        );
        totalMatches += stat.matches;
        totalWins += stat.wins;
      }

      // Средний винрейт по мете для расчёта дельты и ранга.
      final metaAverage = totalMatches == 0 ? 0.5 : totalWins / totalMatches;

      // Ранг по винрейту (1 — лучший).
      final byWinRate = [...selected]
        ..sort((a, b) {
          final cmp = b.winRate.compareTo(a.winRate);
          if (cmp != 0) {
            return cmp;
          }
          return b.matches.compareTo(a.matches);
        });
      final rankById = <int, int>{};
      for (var i = 0; i < byWinRate.length; i++) {
        rankById[byWinRate[i].hero.id] = i + 1;
      }

      final result = <HeroMeta>[
        for (final hero in selected)
          HeroMeta(
            hero: hero.hero,
            matches: hero.matches,
            wins: hero.wins,
            pickRate: hero.pickRate,
            winRateRank: rankById[hero.hero.id] ?? 0,
            totalHeroes: selected.length,
            winRateDelta: hero.winRate - metaAverage,
          ),
      ];

      result.sort((first, second) {
        final cmp = second.winRate.compareTo(first.winRate);
        if (cmp != 0) {
          return cmp;
        }
        return second.matches.compareTo(first.matches);
      });
      return result;
    });
  }

  @override
  Future<List<HeroCounter>> getCounters(int heroId) {
    return _guard(() async {
      final heroes = await _catalog.heroMap();
      final counters = await _loadCounters();

      final result = <HeroCounter>[];
      for (final counter in counters) {
        if (counter.heroId != heroId || counter.matches == 0) {
          continue;
        }
        final enemyDto = heroes[counter.enemyHeroId];
        result.add(
          HeroCounter(
            enemy: enemyDto?.toEntity() ?? _fallbackHero(counter.enemyHeroId),
            matches: counter.matches,
            wins: counter.wins,
          ),
        );
      }

      result.sort((first, second) => second.matches.compareTo(first.matches));
      return result;
    });
  }

  @override
  Future<List<HeroSynergy>> getSynergies(int heroId) {
    return _guard(() async {
      final heroes = await _catalog.heroMap();
      final synergies = await _loadSynergies();

      var relevant = synergies
          .where((pair) => pair.matches >= _minSynergyMatches)
          .where((pair) => pair.heroId1 == heroId || pair.heroId2 == heroId)
          .toList();

      if (relevant.isEmpty) {
        relevant = synergies
            .where((pair) => pair.heroId1 == heroId || pair.heroId2 == heroId)
            .toList();
      }

      final result = <HeroSynergy>[];
      for (final pair in relevant) {
        final allyId = pair.heroId1 == heroId ? pair.heroId2 : pair.heroId1;
        if (allyId == heroId || allyId <= 0) {
          continue;
        }
        result.add(
          HeroSynergy(
            ally: heroes[allyId]?.toEntity() ?? _fallbackHero(allyId),
            matches: pair.matches,
            wins: pair.wins,
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

      return result.take(20).toList(growable: false);
    });
  }

  @override
  Future<List<HeroDurationStat>> getDurationStats(int heroId) {
    return _guard(() async {
      final cached = _durationsCache[heroId];
      if (cached != null) {
        return cached;
      }

      // Запросы по длительности тяжёлые на стороне API, поэтому идём
      // последовательно (а не параллельно), чтобы не ловить 504.
      final buckets = <HeroDurationStat>[];
      for (final bucket in _durationBuckets) {
        buckets.add(await _loadDurationBucket(heroId, bucket));
      }

      // Пустые бакеты не кэшируем: возможно, API временно не ответил.
      if (buckets.any((stat) => stat.matches > 0)) {
        _durationsCache[heroId] = buckets;
      }
      return buckets;
    });
  }

  @override
  Future<HeroDetailedStats?> getHeroDetailedStats(int heroId) {
    return _guard(() async {
      if (_detailedCache.containsKey(heroId)) {
        return _detailedCache[heroId];
      }

      // Общий снапшот по всем героям (bucket=0) уже тянется для меты —
      // переиспользуем его вместо отдельного запроса.
      final stats = await _loadStats();
      HeroStatsDto? selected;
      for (final stat in stats) {
        if (stat.heroId == heroId) {
          selected = stat;
          break;
        }
      }

      final result = selected == null || selected.matches == 0
          ? null
          : HeroDetailedStats(
              matches: selected.matches,
              wins: selected.wins,
              kills: selected.avgKills,
              deaths: selected.avgDeaths,
              assists: selected.avgAssists,
              netWorth: selected.avgNetWorth,
              playerDamage: selected.avgPlayerDamage,
              playerDamageTaken: selected.avgPlayerDamageTaken,
              lastHits: selected.avgLastHits,
              denies: selected.avgDenies,
            );

      _detailedCache[heroId] = result;
      return result;
    });
  }

  @override
  Future<List<HeroBuild>> getBuilds(int heroId) {
    return _guard(() async {
      final cached = _buildsCache[heroId];
      if (cached != null) {
        return cached;
      }

      var stats = await _api.getHeroBuildStats(heroId, minMatches: 50);
      if (stats.isEmpty) {
        stats = await _api.getHeroBuildStats(heroId, minMatches: 10);
      }

      // Собираем кандидатов из двух стратегий: популярные (стабильные)
      // и с высоким винрейтом. Так UI может переключать сортировку без
      // повторных сетевых запросов.
      final byPopularity = [...stats]
        ..sort((a, b) => b.matches.compareTo(a.matches));
      final byWinRate = [...stats]
        ..sort((a, b) {
          final cmp = b.winRate.compareTo(a.winRate);
          if (cmp != 0) {
            return cmp;
          }
          return b.matches.compareTo(a.matches);
        });

      final picked = <int, HeroBuildStatsDto>{};
      for (final stat in byPopularity.take(15)) {
        picked[stat.buildId] = stat;
      }
      for (final stat in byWinRate.take(15)) {
        picked.putIfAbsent(stat.buildId, () => stat);
      }

      final selected = picked.values.toList(growable: false);
      final itemMap = await _catalog.itemMap();
      final buyTimes = await _loadItemBuyTimes();
      final details = await Future.wait(
        selected.map((stat) => _api.getHeroBuild(heroId, stat.buildId)),
      );

      final result = <HeroBuild>[];
      for (var index = 0; index < selected.length; index++) {
        final stat = selected[index];
        final detail = details[index];
        final items = <Item>[];
        final categories = <BuildCategory>[];
        if (detail != null) {
          for (final itemId in detail.itemIds.take(10)) {
            final asset = itemMap[itemId];
            if (asset != null) {
              items.add(_toItem(asset));
            }
          }
          for (final category in detail.categories) {
            final catItems = <Item>[];
            for (final itemId in category.itemIds) {
              final asset = itemMap[itemId];
              if (asset != null) {
                catItems.add(_toItem(asset));
              }
            }
            if (catItems.isEmpty) {
              continue;
            }
            categories.add(
              BuildCategory(
                name: category.name,
                items: catItems,
                annotations: category.annotations,
              ),
            );
          }
        }
        result.add(
          HeroBuild(
            buildId: stat.buildId,
            name: detail?.name ?? _fallbackBuildName(stat),
            items: items,
            matches: stat.matches,
            wins: stat.wins,
            buyTimes: {
              for (final item in items)
                if (buyTimes[item.id] != null) item.id: buyTimes[item.id]!,
            },
            categories: categories,
          ),
        );
      }

      _buildsCache[heroId] = result;
      return result;
    });
  }

  @override
  Future<HeroAbilityPath?> getAbilityPath(int heroId) {
    return _guard(() async {
      if (_abilityPathCache.containsKey(heroId)) {
        return _abilityPathCache[heroId];
      }

      final abilities = await _loadAbilityMap();
      final orders = await _api.getAbilityOrderStats(heroId);
      if (orders.isEmpty) {
        _abilityPathCache[heroId] = null;
        return null;
      }

      orders.sort((a, b) {
        final byWinRate = b.winRate.compareTo(a.winRate);
        if (byWinRate != 0) {
          return byWinRate;
        }
        return b.matches.compareTo(a.matches);
      });

      final top = orders.first;
      final steps = <AbilityPathStep>[];
      for (var i = 0; i < top.abilities.length; i++) {
        final abilityId = top.abilities[i];
        final asset = abilities[abilityId];
        final time = i < top.avgUpgradeTimesS.length
            ? top.avgUpgradeTimesS[i]
            : 0.0;
        steps.add(
          AbilityPathStep(
            order: i + 1,
            abilityName: asset?.name ?? 'Способность',
            imageUrl: asset?.imageUrl ?? '',
            timeSeconds: time,
          ),
        );
      }

      final path = HeroAbilityPath(
        steps: steps,
        matches: top.matches,
        wins: top.wins,
        players: top.players,
      );
      _abilityPathCache[heroId] = path;
      return path;
    });
  }

  @override
  Future<Map<String, List<PopularItem>>> getPopularItems(int heroId) {
    return _guard(() async {
      final cached = _popularItemsCache[heroId];
      if (cached != null) {
        return cached;
      }

      final stages = await _api.getHeroPopularItems(heroId);
      final itemMap = await _catalog.itemMap();
      final result = <String, List<PopularItem>>{};
      for (final entry in stages.entries) {
        final list = <PopularItem>[];
        for (final dto in entry.value) {
          final asset = itemMap[dto.itemId];
          if (asset == null) {
            continue;
          }
          list.add(
            PopularItem(
              item: _toItem(asset),
              pickPct: dto.pickPct,
              winratePct: dto.winratePct,
            ),
          );
        }
        list.sort((a, b) => b.pickPct.compareTo(a.pickPct));
        result[entry.key] = list;
      }
      _popularItemsCache[heroId] = result;
      return result;
    });
  }

  @override
  Future<HeroTrend?> getHeroTrend(int heroId) {
    return _guard(() async {
      if (_trendCache.containsKey(heroId)) {
        return _trendCache[heroId];
      }

      final raw = await _api.getHeroTrend(heroId);
      if (raw.length < 2) {
        _trendCache[heroId] = null;
        return null;
      }

      raw.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      // Берём последние 14 дней, чтобы график был читаемым.
      final recent = raw.length > 14
          ? raw.sublist(raw.length - 14)
          : raw;

      final points = <HeroTrendPoint>[
        for (final point in recent)
          HeroTrendPoint(
            date: DateTime.fromMillisecondsSinceEpoch(point.timestamp * 1000),
            winRate: point.winRate,
            matches: point.matches,
          ),
      ];

      // Дельта за неделю: сравниваем средний винрейт последних 7 дней
      // с предыдущими 7 днями.
      double weekDelta = 0;
      if (recent.length >= 4) {
        final half = recent.length ~/ 2;
        final oldAvg = recent
                .take(half)
                .map((p) => p.winRate)
                .reduce((a, b) => a + b) /
            half;
        final newAvg = recent
                .skip(half)
                .map((p) => p.winRate)
                .reduce((a, b) => a + b) /
            (recent.length - half);
        weekDelta = newAvg - oldAvg;
      }

      final trend = HeroTrend(points: points, weekDelta: weekDelta);
      _trendCache[heroId] = trend;
      return trend;
    });
  }

  Future<Map<int, double>> _loadItemBuyTimes() async {
    final cached = _itemBuyTimes;
    if (cached != null) {
      return cached;
    }
    final stats = await _api.getItemStats();
    final map = <int, double>{};
    for (final stat in stats) {
      if (stat.avgBuyTimeS > 0) {
        map[stat.itemId] = stat.avgBuyTimeS;
      }
    }
    _itemBuyTimes = map;
    return map;
  }

  Future<Map<int, AbilityAssetDto>> _loadAbilityMap() async {
    final cached = _abilityMap;
    if (cached != null) {
      return cached;
    }
    final abilities = await _api.getAbilities();
    final map = <int, AbilityAssetDto>{};
    for (final ability in abilities) {
      map[ability.id] = ability;
    }
    _abilityMap = map;
    return map;
  }

  Future<HeroDurationStat> _loadDurationBucket(
    int heroId,
    _DurationBucket bucket,
  ) async {
    List<HeroStatsDto>? stats;
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        stats = await _api.getHeroStats(
          minDurationSeconds: bucket.minSeconds,
          maxDurationSeconds: bucket.maxSeconds,
        );
        break;
      } on DioException catch (error) {
        // 504/429 — повторяем; прочие ошибки пробрасываем сразу.
        final code = error.response?.statusCode;
        if (code == 504 || code == 429) {
          await Future<void>.delayed(Duration(milliseconds: 400 * (attempt + 1)));
          continue;
        }
        rethrow;
      }
    }

    HeroStatsDto? selected;
    if (stats != null) {
      for (final stat in stats) {
        if (stat.heroId == heroId) {
          selected = stat;
          break;
        }
      }
    }

    return HeroDurationStat(
      label: bucket.label,
      matches: selected?.matches ?? 0,
      wins: selected?.wins ?? 0,
    );
  }

  String _fallbackBuildName(HeroBuildStatsDto stat) {
    return "Сборка #${stat.buildId}";
  }

  Hero _fallbackHero(int id) {
    return Hero(
      id: id,
      name: "Герой #$id",
      role: '',
      imageUrl: '',
      cardUrl: '',
    );
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

  Future<List<HeroStatsDto>> _loadStats() async {
    final cached = _statsCache;
    if (cached != null) {
      return cached;
    }
    final data = await _api.getHeroStats();
    _statsCache = data;
    return data;
  }

  Future<List<HeroCounterDto>> _loadCounters() async {
    final cached = _countersCache;
    if (cached != null) {
      return cached;
    }
    final data = await _api.getHeroCounters();
    _countersCache = data;
    return data;
  }

  Future<List<HeroSynergyDto>> _loadSynergies() async {
    final cached = _synergyCache;
    if (cached != null) {
      return cached;
    }
    final data = await _api.getHeroSynergies();
    _synergyCache = data;
    return data;
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

class _DurationBucket {
  const _DurationBucket(this.label, this.minSeconds, this.maxSeconds);

  final String label;
  final int minSeconds;
  final int? maxSeconds;
}

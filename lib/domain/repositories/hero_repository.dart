import '../entities/hero_ability_path.dart';
import '../entities/hero_build.dart';
import '../entities/hero_counter.dart';
import '../entities/hero_detailed_stats.dart';
import '../entities/hero_duration_stat.dart';
import '../entities/hero_meta.dart';
import '../entities/hero_synergy.dart';
import '../entities/hero_trend.dart';
import '../entities/popular_item.dart';

abstract class HeroRepository {
  /// Все играбельные герои с винрейтом и пикрейтом.
  Future<List<HeroMeta>> getMeta();

  /// Матчапы героя против всех противников.
  Future<List<HeroCounter>> getCounters(int heroId);

  /// Лучшие союзники героя.
  Future<List<HeroSynergy>> getSynergies(int heroId);

  /// Винрейт героя по длительности матчей.
  Future<List<HeroDurationStat>> getDurationStats(int heroId);

  /// Топ сборок героя по винрейту.
  Future<List<HeroBuild>> getBuilds(int heroId);

  /// Детальная статистика героя за патч (KDA, урон, net worth и т.д.).
  Future<HeroDetailedStats?> getHeroDetailedStats(int heroId);

  /// Топ-путь прокачки способностей с иконками и таймингами.
  Future<HeroAbilityPath?> getAbilityPath(int heroId);

  /// Популярные предметы по стадиям (early/mid/late).
  Future<Map<String, List<PopularItem>>> getPopularItems(int heroId);

  /// Тренд винрейта героя по дням + дельта за неделю.
  Future<HeroTrend?> getHeroTrend(int heroId);
}

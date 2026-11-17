import 'package:equatable/equatable.dart';

import '../../../core/error/app_exception.dart';
import '../../../domain/entities/hero_counter.dart';
import '../../../domain/entities/hero_ability_path.dart';
import '../../../domain/entities/hero_detailed_stats.dart';
import '../../../domain/entities/hero_duration_stat.dart';
import '../../../domain/entities/hero_meta.dart';
import '../../../domain/entities/hero_synergy.dart';
import '../../../domain/entities/hero_trend.dart';
import '../../../domain/entities/popular_item.dart';

enum HeroStatus { initial, loading, success, failure }

class HeroState extends Equatable {
  const HeroState({
    this.status = HeroStatus.initial,
    this.meta,
    this.counters = const [],
    this.durations = const [],
    this.synergies = const [],
    this.detailed,
    this.abilityPath,
    this.popularItems = const {},
    this.trend,
    this.error,
  });

  final HeroStatus status;
  final HeroMeta? meta;
  final List<HeroCounter> counters;
  final List<HeroDurationStat> durations;
  final List<HeroSynergy> synergies;
  final HeroDetailedStats? detailed;
  final HeroAbilityPath? abilityPath;
  final Map<String, List<PopularItem>> popularItems;
  final HeroTrend? trend;
  final AppErrorType? error;

  bool get hasData =>
      counters.isNotEmpty || durations.isNotEmpty || synergies.isNotEmpty;

  HeroState copyWith({
    HeroStatus? status,
    HeroMeta? meta,
    List<HeroCounter>? counters,
    List<HeroDurationStat>? durations,
    List<HeroSynergy>? synergies,
    HeroDetailedStats? detailed,
    HeroAbilityPath? abilityPath,
    Map<String, List<PopularItem>>? popularItems,
    HeroTrend? trend,
    AppErrorType? error,
    bool clearError = false,
  }) {
    return HeroState(
      status: status ?? this.status,
      meta: meta ?? this.meta,
      counters: counters ?? this.counters,
      durations: durations ?? this.durations,
      synergies: synergies ?? this.synergies,
      detailed: detailed ?? this.detailed,
      abilityPath: abilityPath ?? this.abilityPath,
      popularItems: popularItems ?? this.popularItems,
      trend: trend ?? this.trend,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [
    status,
    meta,
    counters,
    durations,
    synergies,
    detailed,
    abilityPath,
    popularItems,
    trend,
    error,
  ];
}

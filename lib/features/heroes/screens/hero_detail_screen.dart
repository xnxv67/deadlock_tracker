import 'package:flutter/material.dart' hide Hero;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/hero.dart';
import '../../../domain/entities/hero_build.dart';
import '../../../domain/entities/hero_counter.dart';
import '../../../domain/entities/hero_detailed_stats.dart';
import '../../../domain/entities/hero_trend.dart';
import '../../../domain/repositories/hero_repository.dart';
import '../../../presentation/widgets/hero_trend_chart.dart';
import '../../../presentation/widgets/item_icon.dart';
import '../../secret/screens/labs_screen.dart';

/// Детальный экран героя: статистика, счётчики, сборки и тренд.
class HeroDetailScreen extends StatefulWidget {
  const HeroDetailScreen({super.key, required this.hero});

  final Hero hero;

  @override
  State<HeroDetailScreen> createState() => _HeroDetailScreenState();
}

class _HeroDetailScreenState extends State<HeroDetailScreen> {
  static const int _labsClicks = 10;

  int _clickCount = 0;

  HeroDetailedStats? _stats;
  List<HeroCounter> _counters = const [];
  List<HeroBuild> _builds = const [];
  HeroTrend? _trend;
  bool _loading = true;

  /// Пасхалка открывается только у Inferno (id 1 в Deadlock API).
  bool get _isInferno {
    final name = widget.hero.name.toLowerCase();
    return name == 'inferno' || name == 'infernus' || widget.hero.id == 1;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<T?> _safely<T>(Future<T?> Function() task) async {
    try {
      return await task();
    } catch (_) {
      return null;
    }
  }

  Future<void> _load() async {
    final repo = context.read<HeroRepository>();
    final heroId = widget.hero.id;

    // Запросы стартуют одновременно, падение одного не ломает остальные.
    final statsFuture = _safely(() => repo.getHeroDetailedStats(heroId));
    final countersFuture = _safely(() => repo.getCounters(heroId));
    final buildsFuture = _safely(() => repo.getBuilds(heroId));
    final trendFuture = _safely(() => repo.getHeroTrend(heroId));

    final stats = await statsFuture;
    final counters = await countersFuture;
    final builds = await buildsFuture;
    final trend = await trendFuture;

    if (!mounted) return;
    setState(() {
      _stats = stats;
      _counters = counters ?? const [];
      _builds = builds ?? const [];
      _trend = trend;
      _loading = false;
    });
  }

  Future<void> _onKdaTap() async {
    if (!_isInferno) return;
    _clickCount++;
    if (_clickCount >= _labsClicks) {
      _clickCount = 0;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const LabsScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.hero.name)),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            _banner(),
            const SizedBox(height: 16),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              _statsRow(),
              const SizedBox(height: 16),
              _countersSection(),
              const SizedBox(height: 16),
              _buildsSection(),
              const SizedBox(height: 16),
              _trendSection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _banner() {
    final hero = widget.hero;
    var url = hero.cardUrl;
    if (url.isEmpty) {
      url = hero.imageUrl;
    }
    if (url.isEmpty) {
      url = 'https://assets.deadlock-api.com/v2/heroes/${hero.id}/icon';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              color: AppColors.surfaceLight,
              child: Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Center(
                  child: Icon(
                    Icons.sports_esports_rounded,
                    size: 64,
                    color: AppColors.muted,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          hero.name,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.6,
          ),
        ),
        if (hero.role.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            hero.role,
            style: const TextStyle(
              color: AppColors.copper,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
        ],
      ],
    );
  }

  Widget _statsRow() {
    final stats = _stats;
    if (stats == null || !stats.hasData) {
      return const _SectionCard(
        title: 'Статистика',
        child: Text(
          'Нет данных по статистике',
          style: TextStyle(color: AppColors.muted, fontSize: 12),
        ),
      );
    }

    return _SectionCard(
      title: 'Статистика',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _StatBox(
                  label: 'Винрейт',
                  value: '${(stats.winRate * 100).toStringAsFixed(1)}%',
                  color: stats.winRate >= 0.5
                      ? AppColors.win
                      : AppColors.lose,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatBox(
                  label: 'Средний урон',
                  value: _compact(stats.playerDamage),
                  color: AppColors.copper,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _onKdaTap,
            behavior: HitTestBehavior.opaque,
            child: _StatBox(
              label: 'KDA',
              value: stats.kdaRatio.toStringAsFixed(2),
              color: AppColors.gold,
              subtitle:
                  '${stats.kills.toStringAsFixed(1)} / '
                  '${stats.deaths.toStringAsFixed(1)} / '
                  '${stats.assists.toStringAsFixed(1)}',
            ),
          ),
        ],
      ),
    );
  }

  Widget _countersSection() {
    if (_counters.isEmpty) {
      return const _SectionCard(
        title: 'Счётчики',
        child: Text(
          'Нет данных по счётчикам',
          style: TextStyle(color: AppColors.muted, fontSize: 12),
        ),
      );
    }
    final worst = [..._counters]
      ..sort((a, b) => a.winRate.compareTo(b.winRate));
    final shown = worst.take(5).toList();
    return _SectionCard(
      title: 'Худшие матчапы',
      child: Column(
        children: [
          for (var i = 0; i < shown.length; i++) ...[
            if (i > 0) const Divider(height: 18, color: AppColors.surfaceLight),
            _CounterRow(counter: shown[i]),
          ],
        ],
      ),
    );
  }

  Widget _buildsSection() {
    if (_builds.isEmpty) {
      return const _SectionCard(
        title: 'Топ сборок',
        child: Text(
          'Нет данных по сборкам',
          style: TextStyle(color: AppColors.muted, fontSize: 12),
        ),
      );
    }
    final best = _builds.first;
    return _SectionCard(
      title: 'Топ сборка',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  best.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(best.winRate * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  color: best.winRate >= 0.5 ? AppColors.win : AppColors.lose,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (best.items.isEmpty)
            const Text(
              'Предметы не указаны',
              style: TextStyle(color: AppColors.muted, fontSize: 11),
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final item in best.items.take(8))
                  ItemIcon(item: item, size: 32),
              ],
            ),
        ],
      ),
    );
  }

  Widget _trendSection() {
    final trend = _trend;
    if (trend == null || !trend.hasData) {
      return const _SectionCard(
        title: 'Тренды',
        child: Text(
          'Нет данных по трендам',
          style: TextStyle(color: AppColors.muted, fontSize: 12),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'ТРЕНДЫ',
            style: TextStyle(
              color: AppColors.copper,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
        ),
        HeroTrendChart(trend: trend),
      ],
    );
  }

  static String _compact(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(2)}M';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toStringAsFixed(0);
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: AppColors.copper,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.label,
    required this.value,
    required this.color,
    this.subtitle,
  });

  final String label;
  final String value;
  final Color color;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 8,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              height: 1.05,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 9,
                height: 1.1,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CounterRow extends StatelessWidget {
  const _CounterRow({required this.counter});

  final HeroCounter counter;

  @override
  Widget build(BuildContext context) {
    final wr = counter.winRate;
    return Row(
      children: [
        Expanded(
          child: Text(
            counter.enemy.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
        Text(
          '${(wr * 100).toStringAsFixed(1)}%',
          style: TextStyle(
            color: wr >= 0.5 ? AppColors.win : AppColors.lose,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

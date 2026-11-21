import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/match_record.dart';
import '../../../domain/entities/player_analysis.dart';
import '../../../presentation/widgets/surface_card.dart';
import '../player_insights.dart';
import 'profile_common.dart';

enum _CurveMetric {
  netWorth,
  kills,
  deaths,
  assists,
  damage,
  creepKills,
  denies,
}

class ProfileAnalysisTab extends StatefulWidget {
  const ProfileAnalysisTab({
    super.key,
    required this.analysis,
    required this.insights,
  });

  final PlayerAnalysis analysis;
  final PlayerInsights insights;

  @override
  State<ProfileAnalysisTab> createState() => _ProfileAnalysisTabState();
}

class _ProfileAnalysisTabState extends State<ProfileAnalysisTab> {
  _CurveMetric _metric = _CurveMetric.netWorth;

  @override
  Widget build(BuildContext context) {
    final rank = _RankSummary.fromInsights(widget.insights);
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 880;
        final left = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _rankCard(rank),
            const SizedBox(height: 12),
            _metricsCard(),
          ],
        );
        final right = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [_curveCard(), const SizedBox(height: 12), _notesCard()],
        );

        if (!wide) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [left, const SizedBox(height: 12), right],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 340, child: left),
            const SizedBox(width: 14),
            Expanded(child: right),
          ],
        );
      },
    );
  }

  Widget _rankCard(_RankSummary rank) {
    final color = AppColors.gold;
    return SurfaceCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ProfileSectionTitle(
            icon: Icons.military_tech_rounded,
            title: 'Ранговый прогресс',
            subtitle: 'По загруженной истории матчей',
          ),
          const SizedBox(height: 12),
          if (rank.isEmpty)
            const Text(
              'В последних матчах нет ранговых игр',
              style: TextStyle(color: AppColors.muted, fontSize: 10.5),
            )
          else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  rank.current == null ? '—' : _badgeText(rank.current!),
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                const SizedBox(width: 5),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    'текущий бейдж',
                    style: TextStyle(
                      color: color.withValues(alpha: 0.85),
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (rank.points.length >= 2)
              SizedBox(
                height: 76,
                child: CustomPaint(painter: _RankPainter(rank.points)),
              )
            else
              const SizedBox.shrink(),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _MiniStat(
                    label: 'Матчи',
                    value: '${rank.matches}',
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _MiniStat(
                    label: 'Пик',
                    value: rank.peak == null ? '—' : _badgeText(rank.peak!),
                    color: AppColors.gold,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _MiniStat(
                    label: 'Δ ранга',
                    value: rank.netDelta == 0
                        ? '0'
                        : '${rank.netDelta > 0 ? '+' : ''}${rank.netDelta}',
                    color: rank.netDelta >= 0 ? AppColors.win : AppColors.lose,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _curveCard() {
    final points = widget.analysis.curve;
    return SurfaceCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ProfileSectionTitle(
            icon: Icons.query_stats_rounded,
            title: 'Кривая показателей',
            subtitle: 'Средние значения по ходу матча',
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _MetricChip(
                  label: 'Net worth',
                  color: AppColors.win,
                  selected: _metric == _CurveMetric.netWorth,
                  onTap: () => setState(() => _metric = _CurveMetric.netWorth),
                ),
                _MetricChip(
                  label: 'Убийства',
                  color: AppColors.lose,
                  selected: _metric == _CurveMetric.kills,
                  onTap: () => setState(() => _metric = _CurveMetric.kills),
                ),
                _MetricChip(
                  label: 'Смерти',
                  color: AppColors.muted,
                  selected: _metric == _CurveMetric.deaths,
                  onTap: () => setState(() => _metric = _CurveMetric.deaths),
                ),
                _MetricChip(
                  label: 'Помощь',
                  color: AppColors.copper,
                  selected: _metric == _CurveMetric.assists,
                  onTap: () => setState(() => _metric = _CurveMetric.assists),
                ),
                _MetricChip(
                  label: 'Урон',
                  color: AppColors.ember,
                  selected: _metric == _CurveMetric.damage,
                  onTap: () => setState(() => _metric = _CurveMetric.damage),
                ),
                _MetricChip(
                  label: 'Крипы',
                  color: AppColors.gold,
                  selected: _metric == _CurveMetric.creepKills,
                  onTap: () =>
                      setState(() => _metric = _CurveMetric.creepKills),
                ),
                _MetricChip(
                  label: 'Денай',
                  color: AppColors.win,
                  selected: _metric == _CurveMetric.denies,
                  onTap: () => setState(() => _metric = _CurveMetric.denies),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (points.length < 2)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'Недостаточно данных для кривой',
                style: TextStyle(color: AppColors.muted, fontSize: 10.5),
              ),
            )
          else ...[
            SizedBox(
              height: 170,
              child: CustomPaint(
                painter: _CurvePainter(
                  points: points,
                  metric: _metric,
                  color: _metricColor(_metric),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: const [
                Text(
                  '0%',
                  style: TextStyle(color: AppColors.muted, fontSize: 8.5),
                ),
                Spacer(),
                Text(
                  '50%',
                  style: TextStyle(color: AppColors.muted, fontSize: 8.5),
                ),
                Spacer(),
                Text(
                  '100%',
                  style: TextStyle(color: AppColors.muted, fontSize: 8.5),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _metricsCard() {
    final metrics = widget.analysis.metrics;
    if (metrics.isEmpty) {
      return const SizedBox.shrink();
    }
    final rows = <Widget>[];
    for (final key in _metricOrder) {
      final metric = metrics[key];
      if (metric == null) {
        continue;
      }
      if (rows.isNotEmpty) {
        rows.add(const SizedBox(height: 10));
      }
      rows.add(_MetricRow(metric: metric));
    }

    return SurfaceCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ProfileSectionTitle(
            icon: Icons.percent_rounded,
            title: 'Разброс метрик',
            subtitle: 'Диапазон 25–75 процентилей ваших матчей',
          ),
          const SizedBox(height: 12),
          ...rows,
        ],
      ),
    );
  }

  Widget _notesCard() {
    return SurfaceCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ProfileSectionTitle(
            icon: Icons.info_outline_rounded,
            title: 'Как читать',
            subtitle: 'Данные аналитических эндпоинтов Deadlock API',
          ),
          const SizedBox(height: 8),
          const Text(
            'Кривая и метрики рассчитаны по вашим матчам за последние 90 дней. '
            'Ранговый прогресс использует последние загруженные матчи и '
            'появляется только там, где API вернул бейдж и дельту ранга.',
            style: TextStyle(color: AppColors.muted, fontSize: 9, height: 1.45),
          ),
        ],
      ),
    );
  }
}

const List<String> _metricOrder = [
  'kda',
  'kd',
  'kills',
  'deaths',
  'assists',
  'net_worth',
  'net_worth_per_min',
  'last_hits',
  'denies',
  'accuracy',
  'crit_shot_rate',
  'player_damage',
  'player_damage_per_min',
  'player_damage_taken_per_min',
];

String _badgeText(int badge) => '${badge ~/ 10}.${badge % 10}';

Color _metricColor(_CurveMetric metric) {
  return switch (metric) {
    _CurveMetric.netWorth => AppColors.win,
    _CurveMetric.kills => AppColors.lose,
    _CurveMetric.deaths => AppColors.muted,
    _CurveMetric.assists => AppColors.copper,
    _CurveMetric.damage => AppColors.ember,
    _CurveMetric.creepKills => AppColors.gold,
    _CurveMetric.denies => AppColors.win,
  };
}

String _formatMetricValue(String key, double value) {
  if (key == 'accuracy' || key == 'crit_shot_rate') {
    return formatPercent(value);
  }
  if (value.abs() >= 1000) {
    return formatCompact(value);
  }
  if (key == 'kda' || key == 'kd') {
    return value.toStringAsFixed(2);
  }
  return value.toStringAsFixed(1);
}

String _metricLabel(String key) {
  return switch (key) {
    'kda' => 'KDA',
    'kd' => 'KD',
    'kills' => 'Убийства',
    'deaths' => 'Смерти',
    'assists' => 'Помощь',
    'net_worth' => 'Net worth',
    'net_worth_per_min' => 'Net worth / мин',
    'last_hits' => 'Ластхиты',
    'denies' => 'Денай',
    'accuracy' => 'Точность',
    'crit_shot_rate' => 'Криты',
    'player_damage' => 'Урон по героям',
    'player_damage_per_min' => 'Урон / мин',
    'player_damage_taken_per_min' => 'Получено урона / мин',
    _ => key,
  };
}

double _curveValue(PlayerCurvePoint point, _CurveMetric metric) {
  return switch (metric) {
    _CurveMetric.netWorth => point.netWorth,
    _CurveMetric.kills => point.kills,
    _CurveMetric.deaths => point.deaths,
    _CurveMetric.assists => point.assists,
    _CurveMetric.damage => point.playerDamage,
    _CurveMetric.creepKills => point.creepKills,
    _CurveMetric.denies => point.denies,
  };
}

class _RankSummary {
  const _RankSummary({
    required this.points,
    required this.current,
    required this.peak,
    required this.matches,
    required this.netDelta,
  });

  final List<MatchRecord> points;
  final int? current;
  final int? peak;
  final int matches;
  final int netDelta;

  bool get isEmpty => points.isEmpty;

  factory _RankSummary.fromInsights(PlayerInsights insights) {
    final ranked = insights.matches.where((match) => match.isRanked).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    int? peak;
    var delta = 0;
    for (final match in ranked) {
      final badge = match.rankedBadge;
      if (badge != null) {
        peak = peak == null ? badge : math.max(peak, badge);
      }
      delta += match.rankedDelta ?? 0;
    }
    final current =
        insights.profile.badge?.badge ??
        (ranked.isEmpty ? null : ranked.last.rankedBadge);
    return _RankSummary(
      points: ranked,
      current: current,
      peak: peak,
      matches: ranked.length,
      netDelta: delta,
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 7,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 5),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(7),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: selected
                  ? color.withValues(alpha: 0.18)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(7),
              border: Border.all(
                color: selected
                    ? color.withValues(alpha: 0.75)
                    : AppColors.border,
              ),
            ),
            child: Text(
              label.toUpperCase(),
              style: TextStyle(
                color: selected ? color : AppColors.muted,
                fontSize: 8,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.metric});

  final MetricRange metric;

  @override
  Widget build(BuildContext context) {
    final isPercent =
        metric.key == 'accuracy' || metric.key == 'crit_shot_rate';
    final maxValue = math.max(metric.p75 * 1.25, metric.avg * 1.15);
    final safeMax = maxValue <= 0 ? 1.0 : maxValue;
    final bandStart = (metric.p25 / safeMax).clamp(0.0, 1.0).toDouble();
    final bandEnd = (metric.p75 / safeMax).clamp(0.0, 1.0).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _metricLabel(metric.key),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              isPercent
                  ? formatPercent(metric.avg)
                  : _formatMetricValue(metric.key, metric.avg),
              style: const TextStyle(
                color: AppColors.gold,
                fontSize: 11.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            return SizedBox(
              height: 6,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  Positioned(
                    left: width * bandStart,
                    width: math.max(2, width * (bandEnd - bandStart)),
                    top: 0,
                    bottom: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.copper.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  Positioned(
                    left: (width * (metric.avg / safeMax) - 1.5).clamp(
                      0.0,
                      width - 3,
                    ),
                    top: -1,
                    child: Container(
                      width: 3,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.text,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 3),
        Text(
          '25% ${isPercent ? formatPercent(metric.p25) : _formatMetricValue(metric.key, metric.p25)}'
          '  ·  75% ${isPercent ? formatPercent(metric.p75) : _formatMetricValue(metric.key, metric.p75)}',
          style: const TextStyle(color: AppColors.muted, fontSize: 8),
        ),
      ],
    );
  }
}

class _RankPainter extends CustomPainter {
  _RankPainter(this.points);

  final List<MatchRecord> points;

  @override
  void paint(Canvas canvas, Size size) {
    final profiles = points
        .map((match) => match.rankedBadge ?? 0)
        .toList(growable: false);
    var minBadge = profiles.first;
    var maxBadge = profiles.first;
    for (final badge in profiles) {
      minBadge = math.min(minBadge, badge);
      maxBadge = math.max(maxBadge, badge);
    }
    final span = math.max(1, maxBadge - minBadge);

    final grid = Paint()
      ..color = AppColors.surfaceLight
      ..strokeWidth = 1;
    for (var index = 1; index < 3; index++) {
      final y = size.height * index / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    Offset position(int index) {
      final x = profiles.length == 1
          ? 0.0
          : index / (profiles.length - 1) * size.width;
      final y = size.height - (profiles[index] - minBadge) / span * size.height;
      return Offset(x, y.clamp(0.0, size.height));
    }

    final path = Path()..moveTo(position(0).dx, position(0).dy);
    for (var index = 1; index < profiles.length; index++) {
      final offset = position(index);
      path.lineTo(offset.dx, offset.dy);
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.gold
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round,
    );

    for (var index = 0; index < profiles.length; index++) {
      canvas.drawCircle(
        position(index),
        2.2,
        Paint()..color = points[index].isWin ? AppColors.win : AppColors.lose,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RankPainter oldDelegate) {
    return oldDelegate.points != points;
  }
}

class _CurvePainter extends CustomPainter {
  _CurvePainter({
    required this.points,
    required this.metric,
    required this.color,
  });

  final List<PlayerCurvePoint> points;
  final _CurveMetric metric;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final values = points
        .map((point) => _curveValue(point, metric))
        .toList(growable: false);
    var maxValue = values.reduce(math.max);
    var minValue = values.reduce(math.min);
    if (maxValue == minValue) {
      maxValue += maxValue == 0 ? 1 : maxValue.abs() * 0.2;
    }
    final padding = (maxValue - minValue) * 0.12;
    maxValue += padding;
    minValue = math.max(0, minValue - padding);
    final span = maxValue - minValue;

    final grid = Paint()
      ..color = AppColors.surfaceLight
      ..strokeWidth = 1;
    for (var index = 1; index < 4; index++) {
      final y = size.height * index / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    Offset position(int index) {
      final point = points[index];
      final x = point.gameTime / 100 * size.width;
      final y = size.height - (values[index] - minValue) / span * size.height;
      return Offset(x, y.clamp(0.0, size.height));
    }

    final path = Path()..moveTo(position(0).dx, position(0).dy);
    for (var index = 1; index < points.length; index++) {
      final offset = position(index);
      path.lineTo(offset.dx, offset.dy);
    }

    final area = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0.28),
            color.withValues(alpha: 0.02),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round,
    );

    for (var index = 0; index < points.length; index++) {
      canvas.drawCircle(position(index), 2, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant _CurvePainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.metric != metric ||
        oldDelegate.color != color;
  }
}

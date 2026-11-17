import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/hero_trend.dart';
import 'surface_card.dart';

/// Линейный график тренда винрейта героя по дням.
class HeroTrendChart extends StatelessWidget {
  const HeroTrendChart({super.key, required this.trend});

  final HeroTrend trend;

  @override
  Widget build(BuildContext context) {
    final points = trend.points;
    final spots = <FlSpot>[
      for (var i = 0; i < points.length; i++)
        FlSpot(i.toDouble(), points[i].winRate * 100),
    ];

    var minY = 50.0;
    var maxY = 50.0;
    for (final spot in spots) {
      if (spot.y < minY) minY = spot.y;
      if (spot.y > maxY) maxY = spot.y;
    }
    // Отступы по оси Y, чтобы линия не прилипала к краям.
    minY = (minY - 2).clamp(0, 100);
    maxY = (maxY + 2).clamp(0, 100);
    if (maxY - minY < 4) {
      maxY = minY + 4;
    }

    final delta = trend.weekDelta;
    final deltaColor = delta >= 0 ? AppColors.win : AppColors.lose;

    return SurfaceCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Тренд винрейта',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Последние дни · дельта за неделю',
                      style: TextStyle(color: AppColors.muted, fontSize: 10.5),
                    ),
                  ],
                ),
              ),
              Text(
                '${delta >= 0 ? '+' : ''}${(delta * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  color: deltaColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 150,
            child: LineChart(
              LineChartData(
                minY: minY,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: (maxY - minY) / 2,
                  getDrawingHorizontalLine: (value) => const FlLine(
                    color: AppColors.surfaceLight,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 34,
                      interval: (maxY - minY) / 2,
                      getTitlesWidget: (value, meta) => Text(
                        '${value.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 9,
                          color: AppColors.muted,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: AppColors.gold,
                    barWidth: 2.5,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.gold.withValues(alpha: 0.25),
                          AppColors.gold.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

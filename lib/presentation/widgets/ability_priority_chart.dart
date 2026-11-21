import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/app_theme.dart';
import '../../data/datasources/deadlock_api.dart';
import '../../data/dto/ability_order_dto.dart';
import 'shimmer_skeleton.dart';

/// Горизонтальный BarChart: топ путей прокачки способностей по винрейту.
/// Использует /analytics/ability-order-stats. При пустом ответе показывает заглушку.
class AbilityPriorityChart extends StatefulWidget {
  const AbilityPriorityChart({super.key, required this.heroId});

  final int heroId;

  @override
  State<AbilityPriorityChart> createState() => _AbilityPriorityChartState();
}

class _AbilityPriorityChartState extends State<AbilityPriorityChart> {
  late Future<List<AbilityOrderDto>> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<DeadlockApi>().getAbilityOrderStats(widget.heroId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AbilityOrderDto>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 260,
            child: ShimmerBox(
              width: double.infinity,
              height: 260,
              borderRadius: 12,
            ),
          );
        }
        if (snapshot.hasError) {
          return const SizedBox(
            height: 80,
            child: Center(
              child: Text(
                'Не удалось загрузить порядок прокачки',
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ),
          );
        }
        final all = snapshot.data ?? const <AbilityOrderDto>[];
        if (all.isEmpty) {
          return const SizedBox(
            height: 80,
            child: Center(
              child: Text(
                'Нет данных по способностям',
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ),
          );
        }

        // Топ-8 путей по винрейту (при matches >= 100, чтобы отсечь шум)
        final filtered = all.where((e) => e.matches >= 100).toList()
          ..sort((a, b) => b.winRate.compareTo(a.winRate));
        final top = filtered.take(8).toList();
        if (top.isEmpty) {
          return const SizedBox(
            height: 80,
            child: Center(
              child: Text(
                'Недостаточно матчей для статистики',
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ),
          );
        }

        final maxMatches = top
            .map((e) => e.matches)
            .reduce((a, b) => a > b ? a : b);

        return SizedBox(
          height: 320,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: 100,
              minY: 0,
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
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
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) => Text(
                      '${value.toInt()}%',
                      style: const TextStyle(
                        fontSize: 9,
                        color: AppColors.muted,
                      ),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 46,
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      if (i < 0 || i >= top.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          '#${i + 1}\n${(top[i].matches / maxMatches * 100).toStringAsFixed(0)}%',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 8.5,
                            color: AppColors.muted,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              barGroups: [
                for (var i = 0; i < top.length; i++)
                  BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: top[i].winRate * 100,
                        width: 18,
                        color: top[i].winRate >= 0.5
                            ? AppColors.win
                            : AppColors.lose,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

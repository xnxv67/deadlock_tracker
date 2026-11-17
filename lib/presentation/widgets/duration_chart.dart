import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/app_theme.dart';
import '../../data/datasources/deadlock_api.dart';
import 'shimmer_skeleton.dart';

/// BarChart винрейта героя по 4 бакетам длительности (fl_chart).
class DurationChart extends StatefulWidget {
  const DurationChart({super.key, required this.heroId});

  final int heroId;

  @override
  State<DurationChart> createState() => _DurationChartState();
}

class _Bucket {
  const _Bucket(this.label, this.min, this.max);
  final String label;
  final int min;
  final int? max;
}

const _buckets = <_Bucket>[
  _Bucket('<20', 0, 1200),
  _Bucket('20-30', 1200, 1800),
  _Bucket('30-40', 1800, 2400),
  _Bucket('40+', 2400, null),
];

class _DurationChartState extends State<DurationChart> {
  late Future<List<double>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load(context.read<DeadlockApi>());
  }

  Future<List<double>> _load(DeadlockApi api) async {
    final result = <double>[];
    for (final b in _buckets) {
      final stats = await api.getHeroStats(
        minDurationSeconds: b.min,
        maxDurationSeconds: b.max,
      );
      final own = stats.where((s) => s.heroId == widget.heroId).toList();
      if (own.isEmpty || own.first.matches == 0) {
        result.add(0);
      } else {
        result.add(own.first.winRate);
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<double>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 180,
            child: ShimmerBox(
              width: double.infinity,
              height: 180,
              borderRadius: 12,
            ),
          );
        }
        if (snapshot.hasError) {
          return const SizedBox(
            height: 60,
            child: Center(
              child: Text('Не удалось загрузить длительности',
                  style: TextStyle(color: AppColors.muted, fontSize: 11)),
            ),
          );
        }
        final values = snapshot.data!;
        return SizedBox(
          height: 220,
          child: BarChart(
            BarChartData(
              minY: 0,
              maxY: 1,
              alignment: BarChartAlignment.spaceAround,
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      if (i < 0 || i >= _buckets.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(_buckets[i].label,
                            style: const TextStyle(
                                fontSize: 10, color: AppColors.muted)),
                      );
                    },
                  ),
                ),
              ),
              barGroups: [
                for (var i = 0; i < values.length; i++)
                  BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: values[i],
                        width: 22,
                        color: values[i] >= 0.5 ? AppColors.win : AppColors.lose,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4)),
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

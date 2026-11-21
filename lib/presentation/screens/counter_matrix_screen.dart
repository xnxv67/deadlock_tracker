import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/app_theme.dart';
import '../../data/datasources/deadlock_api.dart';
import '../../data/dto/hero_counter_dto.dart';
import '../widgets/page_header.dart';
import '../widgets/shimmer_skeleton.dart';

/// Матрица контр-пиков: строки — герои, столбцы — враги.
/// В ячейке — дельта винрейта пары относительно 50%.
class CounterMatrixScreen extends StatefulWidget {
  const CounterMatrixScreen({super.key});

  @override
  State<CounterMatrixScreen> createState() => _CounterMatrixScreenState();
}

class _MatrixData {
  const _MatrixData({
    required this.heroIds,
    required this.nameById,
    required this.byRow,
  });

  final List<int> heroIds;
  final Map<int, String> nameById;
  final Map<int, Map<int, HeroCounterDto>> byRow;
}

class _CounterMatrixScreenState extends State<CounterMatrixScreen> {
  late Future<_MatrixData> _future;
  final TextEditingController _search = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _future = _load(context.read<DeadlockApi>());
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<_MatrixData> _load(DeadlockApi api) async {
    final heroesFuture = api.getHeroes();
    final countersFuture = api.getHeroCounters();
    final heroes = await heroesFuture;
    final counters = await countersFuture;
    final nameById = <int, String>{for (final h in heroes) h.id: h.name};
    final byRow = <int, Map<int, HeroCounterDto>>{};
    for (final c in counters) {
      byRow.putIfAbsent(
        c.heroId,
        () => <int, HeroCounterDto>{},
      )[c.enemyHeroId] = c;
    }
    final ids = <int>{...nameById.keys, ...byRow.keys};
    final sortedIds = ids.toList()
      ..sort((a, b) {
        final an = nameById[a] ?? 'Hero $a';
        final bn = nameById[b] ?? 'Hero $b';
        return an.toLowerCase().compareTo(bn.toLowerCase());
      });
    return _MatrixData(heroIds: sortedIds, nameById: nameById, byRow: byRow);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<_MatrixData>(
          future: _future,
          builder: (context, snapshot) {
            final header = Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1180),
                  child: PageHeader(
                    eyebrow: 'Аналитика',
                    title: 'КОНТРПИКИ',
                    subtitle: 'Матрица винрейта пар · дельта к 50%',
                    watermark: 'CP',
                    trailing: IconButton(
                      tooltip: 'Обновить',
                      icon: const Icon(Icons.refresh_rounded, size: 20),
                      onPressed: () => setState(
                        () => _future = _load(context.read<DeadlockApi>()),
                      ),
                    ),
                  ),
                ),
              ),
            );

            if (snapshot.connectionState == ConnectionState.waiting) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  header,
                  const SizedBox(height: 14),
                  const Expanded(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16, 0, 16, 28),
                      child: SkeletonTable(
                        rows: 10,
                        showAvatar: false,
                        trailingBlocks: 4,
                      ),
                    ),
                  ),
                ],
              );
            }
            if (snapshot.hasError) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  header,
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Не удалось загрузить матрицу: ${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.muted),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }
            final data = snapshot.data!;
            final visible = data.heroIds.where((id) {
              if (_query.isEmpty) return true;
              final name = (data.nameById[id] ?? 'Hero $id').toLowerCase();
              return name.contains(_query);
            }).toList();

            return Column(
              children: [
                header,
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: TextField(
                    controller: _search,
                    decoration: InputDecoration(
                      hintText: 'Поиск героя (строка)',
                      prefixIcon: const Icon(Icons.search_rounded, size: 18),
                      isDense: true,
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.surfaceLight,
                        ),
                      ),
                    ),
                    onChanged: (v) =>
                        setState(() => _query = v.trim().toLowerCase()),
                  ),
                ),
                Expanded(
                  child: visible.isEmpty
                      ? const Center(
                          child: Text(
                            'Нет героев по запросу',
                            style: TextStyle(color: AppColors.muted),
                          ),
                        )
                      : Scrollbar(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.vertical,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: _MatrixTable(
                                data: data,
                                visibleRows: visible,
                              ),
                            ),
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MatrixTable extends StatelessWidget {
  const _MatrixTable({required this.data, required this.visibleRows});

  final _MatrixData data;
  final List<int> visibleRows;

  @override
  Widget build(BuildContext context) {
    final columns = data.heroIds;
    return DataTable(
      headingRowHeight: 44,
      dataRowMinHeight: 32,
      dataRowMaxHeight: 40,
      columnSpacing: 18,
      horizontalMargin: 12,
      columns: [
        const DataColumn(label: Text('Герой')),
        for (final id in columns)
          DataColumn(
            label: SizedBox(
              width: 54,
              child: Text(
                data.nameById[id] ?? '#$id',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 9.5, color: AppColors.muted),
              ),
            ),
          ),
      ],
      rows: [
        for (final rowId in visibleRows)
          DataRow(
            cells: [
              DataCell(
                SizedBox(
                  width: 110,
                  child: Text(
                    data.nameById[rowId] ?? '#$rowId',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              for (final colId in columns) _cell(rowId, colId),
            ],
          ),
      ],
    );
  }

  DataCell _cell(int rowId, int colId) {
    if (rowId == colId) {
      return const DataCell(SizedBox(width: 54));
    }
    final pair = data.byRow[rowId]?[colId];
    if (pair == null || pair.matches < 20) {
      return const DataCell(
        SizedBox(
          width: 54,
          child: Text(
            '—',
            textAlign: TextAlign.right,
            style: TextStyle(fontSize: 9.5, color: AppColors.muted),
          ),
        ),
      );
    }
    final delta = (pair.winRate - 0.5) * 100;
    final color = delta > 0 ? AppColors.win : AppColors.lose;
    final sign = delta > 0 ? '+' : '';
    return DataCell(
      SizedBox(
        width: 54,
        child: Text(
          '$sign${delta.toStringAsFixed(1)}%',
          textAlign: TextAlign.right,
          style: TextStyle(
            fontSize: 9.5,
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/datasources/deadlock_api.dart';
import '../../../domain/entities/item_meta.dart';
import '../../../presentation/widgets/item_icon.dart';

class ItemDetailScreen extends StatelessWidget {
  const ItemDetailScreen({super.key, required this.item});

  final ItemMeta item;

  @override
  Widget build(BuildContext context) {
    final meta = item;
    final it = meta.item;
    final category = it.slotType.isNotEmpty ? it.slotType : 'Без категории';

    return Scaffold(
      appBar: AppBar(title: Text(it.name)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.surfaceLight),
                ),
                child: ItemIcon(item: it, size: 120),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              it.name,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Center(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _ChipStat(
                    icon: Icons.monetization_on_rounded,
                    label: 'Стоимость',
                    value: it.cost > 0 ? '${formatCount(it.cost)} монет' : '—',
                    color: AppColors.gold,
                  ),
                  _ChipStat(
                    icon: Icons.category_rounded,
                    label: 'Категория',
                    value: category,
                    color: AppColors.text,
                  ),
                  if (it.tier > 0)
                    _ChipStat(
                      icon: Icons.layers_rounded,
                      label: 'Тир',
                      value: 'T${it.tier}',
                      color: AppColors.text,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const _SectionTitle('Характеристики'),
            const SizedBox(height: 8),
            _InfoCard(
              children: [
                _InfoRow(label: 'Win Rate', value: formatPercent(meta.winRate)),
                _InfoRow(
                  label: 'Pick Rate',
                  value: formatPercent(meta.pickRate),
                ),
                _InfoRow(label: 'Матчи', value: formatCount(meta.matches)),
                _InfoRow(label: 'Победы', value: formatCount(meta.wins)),
                _InfoRow(
                  label: 'Среднее время покупки',
                  value: meta.avgBuyTimeS > 0
                      ? '${(meta.avgBuyTimeS / 60).toStringAsFixed(1)} мин'
                      : '—',
                ),
                const SizedBox(height: 6),
                const Text(
                  'Урон / здоровье / броня: показываются, если доступны в данных API (в текущей модели предмета отдельные поля не передаются).',
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const _SectionTitle('Топ-3 героя, покупающих предмет'),
            const SizedBox(height: 8),
            _TopBuyersSection(itemId: it.id),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: AppColors.muted)),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _ChipStat extends StatelessWidget {
  const _ChipStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: AppColors.muted, fontSize: 10),
              ),
              Text(
                value,
                style: TextStyle(color: color, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TopBuyersSection extends StatefulWidget {
  const _TopBuyersSection({required this.itemId});
  final int itemId;

  @override
  State<_TopBuyersSection> createState() => _TopBuyersSectionState();
}

class _HeroBuyStat {
  const _HeroBuyStat({
    required this.heroId,
    required this.heroName,
    required this.pickPct,
  });
  final int heroId;
  final String heroName;
  final double pickPct;
}

class _TopBuyersSectionState extends State<_TopBuyersSection> {
  late Future<List<_HeroBuyStat>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<_HeroBuyStat>> _load() async {
    try {
      final api = context.read<DeadlockApi>();
      final heroes = await api.getHeroes();
      if (heroes.isEmpty) return const [];

      // Best-effort: query heroes in parallel batches to limit burstiness.
      final byHero = <int, _HeroBuyStat>{};
      const batchSize = 10;
      for (var i = 0; i < heroes.length; i += batchSize) {
        final batch = heroes.skip(i).take(batchSize).toList();
        final results = await Future.wait(
          batch.map((h) async {
            try {
              final popular = await api.getHeroPopularItems(h.id);
              double best = 0;
              for (final stageItems in popular.values) {
                for (final p in stageItems) {
                  if (p.itemId == widget.itemId && p.pickPct > best) {
                    best = p.pickPct;
                  }
                }
              }
              if (best <= 0) return null;
              final name = h.name.trim();
              return _HeroBuyStat(
                heroId: h.id,
                heroName: name.isEmpty ? 'Герой #${h.id}' : name,
                pickPct: best,
              );
            } catch (_) {
              return null;
            }
          }),
        );
        for (final r in results) {
          if (r == null) continue;
          final prev = byHero[r.heroId];
          if (prev == null || r.pickPct > prev.pickPct) {
            byHero[r.heroId] = r;
          }
        }
      }

      final list = byHero.values.toList()
        ..sort((a, b) => b.pickPct.compareTo(a.pickPct));
      return list.take(3).toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<_HeroBuyStat>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _InfoCard(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Center(child: CircularProgressIndicator()),
              ),
              SizedBox(height: 4),
              Text(
                'Загрузка данных по героям (если доступно в API)...',
                style: TextStyle(color: AppColors.muted, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          );
        }
        final data = snapshot.data ?? const [];
        if (data.isEmpty) {
          return const _InfoCard(
            children: [
              Text(
                'Данные о героях, чаще всего покупающих этот предмет, недоступны в API или не найдены.',
                style: TextStyle(color: AppColors.muted),
              ),
            ],
          );
        }
        return _InfoCard(
          children: [
            for (var i = 0; i < data.length; i++) ...[
              _InfoRow(
                label: '${i + 1}. ${data[i].heroName}',
                value: '${data[i].pickPct.toStringAsFixed(1)}% pick',
              ),
              if (i != data.length - 1)
                const Divider(height: 12, color: AppColors.surfaceLight),
            ],
          ],
        );
      },
    );
  }
}

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/item_meta.dart';
import '../../../domain/entities/match_record.dart';
import '../../../domain/repositories/items_repository.dart';
import '../../../presentation/widgets/hero_avatar.dart';
import '../../../presentation/widgets/item_icon.dart';

/// Детали одного матча: результат, KDA, урон, длительность и предметы.
///
/// `match-history` не отдаёт инвентарь и урон, поэтому такие поля
/// показываются как «Н/Д», а предметы — демонстрационный набор из
/// каталога, отсортированный по времени покупки.
class MatchDetailScreen extends StatefulWidget {
  const MatchDetailScreen({super.key, required this.match});

  final MatchRecord match;

  @override
  State<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends State<MatchDetailScreen> {
  List<_PurchasedItem> _items = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    ItemsRepository? repository;
    try {
      repository = context.read<ItemsRepository>();
    } catch (_) {
      repository = null;
    }
    if (repository == null) {
      if (mounted) {
        setState(() => _loading = false);
      }
      return;
    }

    try {
      final catalog = [...await repository.getItems()]
        ..sort((a, b) => a.item.id.compareTo(b.item.id));
      if (catalog.isEmpty) {
        if (mounted) {
          setState(() => _loading = false);
        }
        return;
      }

      // Детерминированный набор: один и тот же матч всегда даёт
      // одинаковый список. Тайминги растянуты по длительности игры.
      final count = math.min(6, catalog.length);
      final start = widget.match.matchId % catalog.length;
      final duration = widget.match.durationSeconds > 0
          ? widget.match.durationSeconds.toDouble()
          : 1800.0;
      final step = duration / (count + 2);

      final picked = <_PurchasedItem>[
        for (var index = 0; index < count; index++)
          _PurchasedItem(
            meta: catalog[(start + index) % catalog.length],
            seconds: ((index + 1) * step).round(),
          ),
      ];

      if (!mounted) return;
      setState(() {
        _items = picked;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final match = widget.match;
    final color = match.isWin ? AppColors.win : AppColors.lose;

    return Scaffold(
      appBar: AppBar(title: Text('Матч #${match.matchId}')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
        children: [
          _ResultBanner(match: match, color: color),
          const SizedBox(height: 12),
          _KdaCard(match: match, color: color),
          const SizedBox(height: 12),
          _factsGrid(match),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'ПРЕДМЕТЫ',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.3,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'В порядке покупки',
                      style: TextStyle(color: AppColors.muted, fontSize: 10),
                    ),
                  ],
                ),
              ),
              Text(
                _items.isEmpty ? '' : '${_items.length}',
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _itemsSection(),
        ],
      ),
    );
  }

  Widget _itemsSection() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (_items.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: const Text(
          'Данные о предметах недоступны',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.muted, fontSize: 11.5),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              for (var index = 0; index < _items.length; index++) ...[
                if (index > 0)
                  const Divider(height: 1, color: AppColors.surfaceLight),
                _ItemRow(index: index, item: _items[index]),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Демонстрационные предметы и тайминги: API не отдаёт инвентарь матча.',
          style: TextStyle(color: AppColors.muted, fontSize: 8.5, height: 1.3),
        ),
      ],
    );
  }

  Widget _factsGrid(MatchRecord match) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 8) / 2;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            SizedBox(
              width: width,
              child: _FactTile(
                label: 'Урон по героям',
                icon: Icons.whatshot_rounded,
                value: _formatDamage(match.heroDamage),
                hint: match.heroDamage == null
                    ? 'API не отдаёт поле'
                    : 'за матч',
                color: AppColors.copper,
              ),
            ),
            SizedBox(
              width: width,
              child: _FactTile(
                label: 'Урон по строениям',
                icon: Icons.apartment_rounded,
                value: _formatDamage(match.buildingDamage),
                hint: match.buildingDamage == null
                    ? 'API не отдаёт поле'
                    : 'за матч',
                color: AppColors.gold,
              ),
            ),
            SizedBox(
              width: width,
              child: _FactTile(
                label: 'Длительность',
                icon: Icons.timer_outlined,
                value: formatDuration(match.durationSeconds),
                hint: 'время матча',
                color: AppColors.text,
              ),
            ),
            SizedBox(
              width: width,
              child: _FactTile(
                label: 'Net Worth',
                icon: Icons.savings_rounded,
                value: match.netWorth == null
                    ? 'Н/Д'
                    : formatCount(match.netWorth!),
                hint: match.netWorth == null ? 'нет данных' : 'к концу матча',
                color: AppColors.win,
              ),
            ),
            SizedBox(
              width: width,
              child: _FactTile(
                label: 'Ластхиты',
                icon: Icons.agriculture_rounded,
                value: match.lastHits == null
                    ? 'Н/Д'
                    : formatCount(match.lastHits!),
                hint: match.lastHits == null ? 'нет данных' : 'добито крипов',
                color: AppColors.gold,
              ),
            ),
            SizedBox(
              width: width,
              child: _FactTile(
                label: 'Денай',
                icon: Icons.block_rounded,
                value: match.denies == null
                    ? 'Н/Д'
                    : formatCount(match.denies!),
                hint: match.denies == null ? 'нет данных' : 'отказано крипов',
                color: AppColors.muted,
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatDamage(int? value) {
    if (value == null || value <= 0) {
      return 'Н/Д';
    }
    return formatCompact(value.toDouble());
  }
}

class _PurchasedItem {
  const _PurchasedItem({required this.meta, required this.seconds});

  final ItemMeta meta;
  final int seconds;
}

class _ResultBanner extends StatelessWidget {
  const _ResultBanner({required this.match, required this.color});

  final MatchRecord match;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.45)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withValues(alpha: 0.22), AppColors.surface],
        ),
      ),
      child: Row(
        children: [
          HeroAvatar(hero: match.hero, size: 60),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  match.hero.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  formatDateFromSeconds(match.startTime),
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 10.5,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(color: color.withValues(alpha: 0.65)),
                  ),
                  child: Text(
                    match.isWin ? 'ПОБЕДА' : 'ПОРАЖЕНИЕ',
                    style: TextStyle(
                      color: color,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.7,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KdaCard extends StatelessWidget {
  const _KdaCard({required this.match, required this.color});

  final MatchRecord match;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 13),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Text(
                'KDA',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              Text(
                match.kda.toStringAsFixed(2),
                style: const TextStyle(
                  color: AppColors.gold,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Text(
                '  KDA',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _KdaValue(
                  label: 'Убийства',
                  value: match.kills,
                  color: AppColors.win,
                ),
              ),
              const _KdaDivider(),
              Expanded(
                child: _KdaValue(
                  label: 'Смерти',
                  value: match.deaths,
                  color: AppColors.lose,
                ),
              ),
              const _KdaDivider(),
              Expanded(
                child: _KdaValue(
                  label: 'Помощь',
                  value: match.assists,
                  color: AppColors.copper,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            '${match.kills} / ${match.deaths} / ${match.assists}',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _KdaValue extends StatelessWidget {
  const _KdaValue({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$value',
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 8,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}

class _KdaDivider extends StatelessWidget {
  const _KdaDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 30, color: AppColors.surfaceLight);
  }
}

class _FactTile extends StatelessWidget {
  const _FactTile({
    required this.label,
    required this.icon,
    required this.value,
    required this.hint,
    required this.color,
  });

  final String label;
  final IconData icon;
  final String value;
  final String hint;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(11, 9, 11, 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.7,
                  ),
                ),
              ),
              Icon(icon, size: 12, color: color.withValues(alpha: 0.8)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 17,
              fontWeight: FontWeight.w900,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            hint,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 8.5,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.index, required this.item});

  final int index;
  final _PurchasedItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 18,
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          ItemIcon(item: item.meta.item, size: 40),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item.meta.item.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            formatDuration(item.seconds),
            style: const TextStyle(
              color: AppColors.gold,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

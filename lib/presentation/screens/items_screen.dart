import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/error_messages.dart';
import '../../core/utils/formatters.dart';
import '../../domain/entities/item_meta.dart';
import '../../domain/repositories/items_repository.dart';
import '../bloc/items/items_bloc.dart';
import '../bloc/items/items_event.dart';
import '../bloc/items/items_sort.dart';
import '../bloc/items/items_state.dart';
import '../widgets/error_view.dart';
import '../widgets/item_icon.dart';
import '../widgets/page_header.dart';
import '../widgets/section_header.dart';
import '../widgets/shimmer_skeleton.dart';
import '../widgets/simple_table.dart';
import '../widgets/stat_tile.dart';

class ItemsScreen extends StatelessWidget {
  const ItemsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          ItemsBloc(context.read<ItemsRepository>())
            ..add(const ItemsRequested()),
      child: const _ItemsView(),
    );
  }
}

class _ItemsView extends StatelessWidget {
  const _ItemsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<ItemsBloc, ItemsState>(
          builder: (context, state) {
            return RefreshIndicator(
              onRefresh: () async {
                context.read<ItemsBloc>().add(const ItemsRefreshRequested());
                await Future<void>.delayed(const Duration(milliseconds: 700));
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1180),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const PageHeader(
                            eyebrow: 'Аналитика',
                            title: 'ПРЕДМЕТЫ',
                            subtitle: 'Винрейт, пикрейт и число покупок · все предметы',
                            watermark: 'IT',
                          ),
                          const SizedBox(height: 14),
                          _Summary(items: state.items),
                          const SizedBox(height: 20),
                          SectionHeader(
                            title: 'Предметы',
                            subtitle: 'Клик по заголовку — сортировка · по умолчанию Win Rate',
                            trailing:
                                state.status == ItemsStatus.loading &&
                                    state.hasData
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(height: 10),
                          _content(context, state),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _content(BuildContext context, ItemsState state) {
    if (!state.hasData) {
      if (state.status == ItemsStatus.failure) {
        return ErrorView(
          title: errorTitle(state.error),
          text: errorText(state.error),
          onRetry: () => context.read<ItemsBloc>().add(const ItemsRequested()),
        );
      }
      return const SkeletonTable(rows: 8, showAvatar: false);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SimpleTable(
          columns: [
            TableColumn(
              'Предмет',
              flex: 6,
              onTap: () => _sort(context, ItemSortField.name),
              sorted: state.sortField == ItemSortField.name,
              ascending: state.ascending,
            ),
            TableColumn(
              'Win Rate',
              flex: 2,
              align: Alignment.centerRight,
              onTap: () => _sort(context, ItemSortField.winRate),
              sorted: state.sortField == ItemSortField.winRate,
              ascending: state.ascending,
            ),
            TableColumn(
              'Pick Rate',
              flex: 2,
              align: Alignment.centerRight,
              onTap: () => _sort(context, ItemSortField.pickRate),
              sorted: state.sortField == ItemSortField.pickRate,
              ascending: state.ascending,
            ),
            TableColumn(
              'Матчи',
              flex: 2,
              align: Alignment.centerRight,
              onTap: () => _sort(context, ItemSortField.matches),
              sorted: state.sortField == ItemSortField.matches,
              ascending: state.ascending,
            ),
            TableColumn(
              'Buy',
              flex: 2,
              align: Alignment.centerRight,
              onTap: () => _sort(context, ItemSortField.buyTime),
              sorted: state.sortField == ItemSortField.buyTime,
              ascending: state.ascending,
            ),
          ],
          rows: [
            for (final item in state.items)
              TableRowData(
                cells: [
                  _ItemCell(item: item),
                  Text(
                    formatPercent(item.winRate),
                    style: TextStyle(
                      color: AppColors.winRateColor(item.winRate),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    formatPercent(item.pickRate),
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    formatCount(item.matches),
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    item.avgBuyTimeS > 0
                        ? '${(item.avgBuyTimeS / 60).round()}м'
                        : '—',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
          ],
        );
      },
    );
  }

  static void _sort(BuildContext context, ItemSortField field) {
    context.read<ItemsBloc>().add(ItemsSortRequested(field));
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.items});

  final List<ItemMeta> items;

  @override
  Widget build(BuildContext context) {
    var matches = 0;
    var wins = 0;
    for (final item in items) {
      matches += item.matches;
      wins += item.wins;
    }
    final average = matches == 0 ? 0.0 : wins / matches;

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 560;
        final width = wide
            ? (constraints.maxWidth - 20) / 3
            : (constraints.maxWidth - 10) / 2;

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            SizedBox(
              width: width,
              child: StatTile(
                label: 'Предметов',
                value: items.isEmpty ? '—' : '${items.length}',
                accent: AppColors.text,
              ),
            ),
            SizedBox(
              width: width,
              child: StatTile(
                label: 'Средний Win Rate',
                value: items.isEmpty ? '—' : formatPercent(average),
                accent: items.isEmpty
                    ? AppColors.muted
                    : AppColors.winRateColor(average),
              ),
            ),
            SizedBox(
              width: width,
              child: StatTile(
                label: 'Покупок',
                value: items.isEmpty ? '—' : formatCount(matches),
                accent: AppColors.gold,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ItemCell extends StatelessWidget {
  const _ItemCell({required this.item});

  final ItemMeta item;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ItemIcon(item: item.item, size: 30),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item.item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (item.item.tier > 0) ...[
                const SizedBox(height: 2),
                Text(
                  'T${item.item.tier} · ${formatCount(item.item.cost)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.muted, fontSize: 9.5),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

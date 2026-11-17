import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class TableColumn {
  const TableColumn(
    this.label, {
    required this.flex,
    this.align = Alignment.centerLeft,
    this.onTap,
    this.sorted = false,
    this.ascending = false,
  });

  final String label;
  final int flex;
  final Alignment align;
  final VoidCallback? onTap;
  final bool sorted;
  final bool ascending;
}

class TableRowData {
  const TableRowData({required this.cells, this.onTap, this.tint});

  final List<Widget> cells;
  final VoidCallback? onTap;
  final Color? tint;
}

/// Компактная полноширинная таблица вместо DataTable:
/// колонки тянутся по flex, строки подсвечиваются при наведении,
/// заголовки умеют сортировать.
class SimpleTable extends StatelessWidget {
  const SimpleTable({super.key, required this.columns, required this.rows});

  final List<TableColumn> columns;
  final List<TableRowData> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            color: AppColors.surfaceAlt,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Row(
              children: [
                for (final column in columns)
                  Expanded(
                    flex: column.flex,
                    child: _HeaderCell(column: column),
                  ),
              ],
            ),
          ),
          for (var index = 0; index < rows.length; index++)
            _TableRow(
              row: rows[index],
              columns: columns,
              striped: index.isOdd,
              last: index == rows.length - 1,
            ),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell({required this.column});

  final TableColumn column;

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            column.label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: column.sorted ? AppColors.gold : AppColors.muted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
        ),
        if (column.sorted) ...[
          const SizedBox(width: 3),
          Icon(
            column.ascending
                ? Icons.arrow_upward_rounded
                : Icons.arrow_downward_rounded,
            size: 12,
            color: AppColors.gold,
          ),
        ],
      ],
    );

    final child = Align(
      alignment: column.align,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: content,
      ),
    );

    if (column.onTap == null) {
      return child;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: column.onTap,
        borderRadius: BorderRadius.circular(6),
        hoverColor: AppColors.copper.withValues(alpha: 0.08),
        child: child,
      ),
    );
  }
}

class _TableRow extends StatelessWidget {
  const _TableRow({
    required this.row,
    required this.columns,
    required this.striped,
    required this.last,
  });

  final TableRowData row;
  final List<TableColumn> columns;
  final bool striped;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final background =
        row.tint ??
        (striped ? AppColors.surfaceAlt.withValues(alpha: 0.45) : null);

    return Material(
      color: background ?? Colors.transparent,
      child: InkWell(
        onTap: row.onTap,
        hoverColor: AppColors.copper.withValues(alpha: 0.08),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            border: last
                ? null
                : const Border(
                    bottom: BorderSide(color: AppColors.surfaceLight),
                  ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              for (var index = 0; index < columns.length; index++)
                Expanded(
                  flex: columns[index].flex,
                  child: Align(
                    alignment: columns[index].align,
                    child: index < row.cells.length
                        ? row.cells[index]
                        : const SizedBox.shrink(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

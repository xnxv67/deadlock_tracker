import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Базовый shimmer-контейнер: анимированная полоса-блик поверх
/// нейтрального «скелетонного» блока. Без внешних зависимостей.
class ShimmerBox extends StatefulWidget {
  const ShimmerBox({
    super.key,
    this.width,
    this.height = 14,
    this.borderRadius = 6,
    this.shape = BoxShape.rectangle,
  });

  final double? width;
  final double height;
  final double borderRadius;
  final BoxShape shape;

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = widget.shape == BoxShape.circle
        ? null
        : BorderRadius.circular(widget.borderRadius);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            final slide = _controller.value * 2 - 1;
            return LinearGradient(
              begin: Alignment(-1.5 + slide * 3, 0),
              end: Alignment(-0.5 + slide * 3, 0),
              colors: const [
                AppColors.surfaceLight,
                AppColors.surfaceAlt,
                AppColors.surfaceLight,
              ],
              stops: const [0.25, 0.5, 0.75],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          shape: widget.shape,
          borderRadius: borderRadius,
        ),
      ),
    );
  }
}

/// Скелетон строки таблицы: аватар + название + пара числовых колонок.
class SkeletonTableRow extends StatelessWidget {
  const SkeletonTableRow({
    super.key,
    this.showAvatar = true,
    this.trailingBlocks = 3,
    this.padding = const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
  });

  final bool showAvatar;
  final int trailingBlocks;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          if (showAvatar) ...[
            const ShimmerBox(width: 30, height: 30, borderRadius: 8),
            const SizedBox(width: 10),
          ],
          const Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: ShimmerBox(width: 140, height: 13),
            ),
          ),
          for (var i = 0; i < trailingBlocks; i++) ...[
            const SizedBox(width: 16),
            const ShimmerBox(width: 44, height: 12),
          ],
        ],
      ),
    );
  }
}

/// Скелетон-заглушка для табличного списка: несколько строк + рамка.
class SkeletonTable extends StatelessWidget {
  const SkeletonTable({
    super.key,
    this.rows = 6,
    this.showAvatar = true,
    this.trailingBlocks = 3,
  });

  final int rows;
  final bool showAvatar;
  final int trailingBlocks;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows; i++) ...[
            if (i > 0)
              const Divider(height: 1, color: AppColors.surfaceLight),
            SkeletonTableRow(
              showAvatar: showAvatar,
              trailingBlocks: trailingBlocks,
            ),
          ],
        ],
      ),
    );
  }
}

/// Скелетон карточки-статистики (StatTile).
class SkeletonStatTile extends StatelessWidget {
  const SkeletonStatTile({super.key, this.width, this.height = 74});

  final double? width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ShimmerBox(width: 70, height: 9),
            SizedBox(height: 10),
            ShimmerBox(width: 46, height: 16),
          ],
        ),
      ),
    );
  }
}

/// Скелетон детальной карточки-баннера (Hero/Meta header).
class SkeletonBanner extends StatelessWidget {
  const SkeletonBanner({super.key, this.height = 116});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ShimmerBox(
            width: height - 40,
            height: height - 40,
            borderRadius: 16,
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ShimmerBox(width: 160, height: 20),
                SizedBox(height: 10),
                ShimmerBox(width: 100, height: 10),
                SizedBox(height: 12),
                ShimmerBox(width: 220, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Обёртка экрана загрузки: баннер + блок статистик + таблица.
class ScreenSkeleton extends StatelessWidget {
  const ScreenSkeleton({
    super.key,
    this.showBanner = true,
    this.statTiles = 3,
    this.tableRows = 6,
    this.showAvatar = true,
  });

  final bool showBanner;
  final int statTiles;
  final int tableRows;
  final bool showAvatar;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (showBanner) ...[
                  const SkeletonBanner(),
                  const SizedBox(height: 18),
                ],
                if (statTiles > 0) ...[
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final wide = constraints.maxWidth >= 560;
                      final width = wide
                          ? (constraints.maxWidth - 20) / statTiles
                          : (constraints.maxWidth - 10) / 2;
                      return Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          for (var i = 0; i < statTiles; i++)
                            SkeletonStatTile(width: width),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                ],
                SkeletonTable(rows: tableRows, showAvatar: showAvatar),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

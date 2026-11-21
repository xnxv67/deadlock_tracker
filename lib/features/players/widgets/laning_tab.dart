import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/player_analysis.dart';
import '../../../presentation/widgets/surface_card.dart';
import 'profile_common.dart';

String laneName(int laneId) {
  return switch (laneId) {
    1 => 'Йорк',
    4 => 'Бродвей',
    6 => 'Гринвич',
    _ => 'Линия $laneId',
  };
}

Color laneColor(int laneId) {
  return switch (laneId) {
    1 => const Color(0xFFF1CC30),
    4 => const Color(0xFF29B1CC),
    6 => const Color(0xFF59B24A),
    _ => AppColors.copper,
  };
}

class ProfileLaningTab extends StatelessWidget {
  const ProfileLaningTab({super.key, required this.analysis});

  final PlayerAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    if (!analysis.hasLanes && analysis.soulCurve.isEmpty) {
      return const SurfaceCard(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Column(
            children: [
              Icon(Icons.alt_route_rounded, size: 30, color: AppColors.copper),
              SizedBox(height: 10),
              Text(
                'Недостаточно данных по линиям за последние 90 дней',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted, fontSize: 11.5),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 880;
        final lanes = _lanesCard();
        final curve = _soulCurveCard();

        if (!wide) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              curve,
              if (analysis.hasLanes) ...[const SizedBox(height: 12), lanes],
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: curve),
            if (analysis.hasLanes) ...[
              const SizedBox(width: 14),
              SizedBox(width: 340, child: lanes),
            ],
          ],
        );
      },
    );
  }

  Widget _lanesCard() {
    final totalMatches = analysis.lanes.fold<int>(
      0,
      (sum, lane) => sum + lane.matches,
    );
    final totalWins = analysis.lanes.fold<int>(
      0,
      (sum, lane) => sum + lane.wins,
    );
    final winRate = totalMatches == 0 ? 0.0 : totalWins / totalMatches;

    return SurfaceCard(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ProfileSectionTitle(
            icon: Icons.alt_route_rounded,
            title: 'Игра по линиям',
            subtitle: 'Последние 90 дней',
            trailing: Text(
              formatPercent(winRate, digits: 0),
              style: TextStyle(
                color: AppColors.winRateColor(winRate),
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${formatCount(totalMatches)} матчей · '
            '${formatCount(totalWins)} побед',
            style: const TextStyle(color: AppColors.muted, fontSize: 9),
          ),
          const SizedBox(height: 12),
          for (var index = 0; index < analysis.lanes.length; index++) ...[
            if (index > 0) const SizedBox(height: 12),
            _LaneRow(lane: analysis.lanes[index]),
          ],
        ],
      ),
    );
  }

  Widget _soulCurveCard() {
    final points = analysis.soulCurve;
    final at10 = _nearest(points, 600);
    final at20 = _nearest(points, 1200);

    return SurfaceCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ProfileSectionTitle(
            icon: Icons.stacked_line_chart_rounded,
            title: 'Разница душ на линии',
            subtitle: 'Среднее преимущество пары по ходу матча',
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _CurveMetric(label: 'К 10:00', point: at10),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CurveMetric(label: 'К 20:00', point: at20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CurveMetric(
                  label: 'Пик',
                  point: points.isEmpty
                      ? null
                      : points.reduce(
                          (best, point) =>
                              point.netWorthDiff > best.netWorthDiff
                              ? point
                              : best,
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (points.length < 2)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Text(
                'Недостаточно точек для кривой',
                style: TextStyle(color: AppColors.muted, fontSize: 10.5),
              ),
            )
          else
            SizedBox(
              height: 150,
              child: CustomPaint(painter: _SoulCurvePainter(points)),
            ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                points.isEmpty ? '—' : formatDuration(points.first.seconds),
                style: const TextStyle(color: AppColors.muted, fontSize: 8.5),
              ),
              const Spacer(),
              Text(
                points.isEmpty ? '—' : formatDuration(points.last.seconds),
                style: const TextStyle(color: AppColors.muted, fontSize: 8.5),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Положительная разница — ваша пара фармила быстрее соперников '
            'на линии. Данные Deadlock API за последние 90 дней.',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 8.5,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  LaneSoulPoint? _nearest(List<LaneSoulPoint> points, int seconds) {
    if (points.isEmpty) {
      return null;
    }
    LaneSoulPoint best = points.first;
    var bestDelta = (best.seconds - seconds).abs();
    for (final point in points) {
      final delta = (point.seconds - seconds).abs();
      if (delta < bestDelta) {
        best = point;
        bestDelta = delta;
      }
    }
    return best;
  }
}

class _LaneRow extends StatelessWidget {
  const _LaneRow({required this.lane});

  final LanePerformance lane;

  @override
  Widget build(BuildContext context) {
    final color = laneColor(lane.laneId);
    final winColor = AppColors.winRateColor(lane.winRate);
    final diffColor = lane.netWorthDiff >= 0 ? AppColors.win : AppColors.lose;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                laneName(lane.laneId),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Text(
              '${lane.matches} матчей',
              style: const TextStyle(color: AppColors.muted, fontSize: 9),
            ),
            const SizedBox(width: 8),
            Text(
              formatPercent(lane.winRate, digits: 0),
              style: TextStyle(
                color: winColor,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ProfileProgressBar(value: lane.winRate, color: winColor, height: 4),
        const SizedBox(height: 5),
        Row(
          children: [
            Text(
              '${lane.wins}–${lane.losses}',
              style: const TextStyle(color: AppColors.muted, fontSize: 8.5),
            ),
            const Spacer(),
            Text(
              '${lane.netWorthDiff >= 0 ? '+' : ''}'
              '${formatCount(lane.netWorthDiff.round())} душ к 10:00',
              style: TextStyle(
                color: diffColor,
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CurveMetric extends StatelessWidget {
  const _CurveMetric({required this.label, required this.point});

  final String label;
  final LaneSoulPoint? point;

  @override
  Widget build(BuildContext context) {
    final diff = point?.netWorthDiff;
    final color = diff == null
        ? AppColors.muted
        : diff >= 0
        ? AppColors.win
        : AppColors.lose;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 7.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            diff == null
                ? '—'
                : '${diff >= 0 ? '+' : ''}${formatCount(diff.round())}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _SoulCurvePainter extends CustomPainter {
  _SoulCurvePainter(this.points);

  final List<LaneSoulPoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = AppColors.surfaceLight
      ..strokeWidth = 1;
    for (var index = 1; index < 4; index++) {
      final y = size.height * index / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    var maxAbs = 200.0;
    for (final point in points) {
      maxAbs = math.max(maxAbs, point.netWorthDiff.abs());
    }
    maxAbs *= 1.2;
    final middle = size.height / 2;
    final zero = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1.2;
    canvas.drawLine(Offset(0, middle), Offset(size.width, middle), zero);

    final firstTime = points.first.seconds;
    final lastTime = points.last.seconds;
    final span = math.max(1, lastTime - firstTime).toDouble();

    Offset position(int index) {
      final point = points[index];
      final x = (point.seconds - firstTime) / span * size.width;
      final y = middle - point.netWorthDiff / maxAbs * middle;
      return Offset(x, y.clamp(0.0, size.height));
    }

    final line = Path()..moveTo(position(0).dx, position(0).dy);
    for (var index = 1; index < points.length; index++) {
      final offset = position(index);
      line.lineTo(offset.dx, offset.dy);
    }

    final area = Path.from(line)
      ..lineTo(size.width, middle)
      ..lineTo(0, middle)
      ..close();

    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.copper.withValues(alpha: 0.32),
            AppColors.copper.withValues(alpha: 0.02),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    canvas.drawPath(
      line,
      Paint()
        ..color = AppColors.gold
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round,
    );

    canvas.drawCircle(position(0), 2.6, Paint()..color = AppColors.ember);
    canvas.drawCircle(
      position(points.length - 1),
      2.6,
      Paint()..color = AppColors.ember,
    );
  }

  @override
  bool shouldRepaint(covariant _SoulCurvePainter oldDelegate) {
    return oldDelegate.points != points;
  }
}

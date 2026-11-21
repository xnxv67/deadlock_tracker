import '../../domain/entities/match_record.dart';
import '../../domain/entities/player_hero_stat.dart';
import '../../domain/entities/player_profile.dart';

/// Агрегаты и производные метрики профиля, которые нужны виджетам.
///
/// Всё считается локально из уже загруженного [PlayerProfile]:
/// история матчей (до 50 последних игр) и статистика по героям.
class PlayerInsights {
  PlayerInsights(this.profile)
    : matches = List<MatchRecord>.unmodifiable(
        [...profile.matches]
          ..sort((a, b) => b.startTime.compareTo(a.startTime)),
      ),
      heroes = List<PlayerHeroStat>.unmodifiable(
        [...profile.heroes]..sort((a, b) => b.matches.compareTo(a.matches)),
      );

  final PlayerProfile profile;

  /// Матчи от новых к старым.
  final List<MatchRecord> matches;

  /// Герои от самых сыгранных к редким.
  final List<PlayerHeroStat> heroes;

  int get totalMatches => profile.totalMatches;
  int get totalWins => profile.totalWins;
  int get totalLosses => (totalMatches - totalWins).clamp(0, totalMatches);
  double get winRate => profile.winRate;
  double get kda => profile.kda;

  bool get hasMatches => matches.isNotEmpty;
  bool get hasHeroes => heroes.isNotEmpty;
  bool get isEmpty => profile.isEmpty;

  int get _matchCount => matches.isEmpty ? 1 : matches.length;

  double get avgKills => matches.isEmpty
      ? 0
      : matches.fold<int>(0, (sum, m) => sum + m.kills) / _matchCount;

  double get avgDeaths => matches.isEmpty
      ? 0
      : matches.fold<int>(0, (sum, m) => sum + m.deaths) / _matchCount;

  double get avgAssists => matches.isEmpty
      ? 0
      : matches.fold<int>(0, (sum, m) => sum + m.assists) / _matchCount;

  int get avgDurationSeconds => matches.isEmpty
      ? 0
      : matches.fold<int>(0, (sum, m) => sum + m.durationSeconds) ~/
            _matchCount;

  double? get avgHeroDamage => _avgOptional((m) => m.heroDamage);

  double? get avgNetWorth => _avgOptional((m) => m.netWorth);

  double? get avgLastHits => _avgOptional((m) => m.lastHits);

  double? get avgDenies => _avgOptional((m) => m.denies);

  double? _avgOptional(int? Function(MatchRecord match) selector) {
    var sum = 0;
    var count = 0;
    for (final match in matches) {
      final value = selector(match);
      if (value != null && value > 0) {
        sum += value;
        count++;
      }
    }
    return count == 0 ? null : sum / count;
  }

  /// Герой с лучшим винрейтом (сначала рассматриваем 5+ матчей).
  PlayerHeroStat? get bestHero {
    if (heroes.isEmpty) {
      return null;
    }
    final eligible = heroes.where((hero) => hero.matches >= 5).toList();
    final pool = eligible.isEmpty ? heroes : eligible;
    return pool.reduce(
      (best, hero) => hero.winRate > best.winRate ? hero : best,
    );
  }

  /// Герой с худшим винрейтом среди тех, у кого есть матчи.
  PlayerHeroStat? get worstHero {
    final pool = heroes.where((hero) => hero.matches >= 3).toList();
    if (pool.isEmpty) {
      return null;
    }
    return pool.reduce(
      (worst, hero) => hero.winRate < worst.winRate ? hero : worst,
    );
  }

  PlayerHeroStat? get mostPlayedHero => heroes.isEmpty ? null : heroes.first;

  List<PlayerHeroStat> topHeroes([int count = 3]) =>
      heroes.take(count).toList();

  /// Условный индекс формы 0..100 из винрейта и KDA.
  double get performanceScore {
    if (totalMatches == 0) {
      return 0;
    }
    final winPart = winRate.clamp(0.0, 1.0) * 62;
    final kdaPart = (kda.clamp(0.0, 6.0) / 6.0) * 38;
    return (winPart + kdaPart).clamp(0.0, 100.0);
  }

  String get performanceLabel {
    final score = performanceScore;
    if (score >= 74) return 'Доминирует';
    if (score >= 62) return 'Сильный';
    if (score >= 50) return 'Стабильный';
    if (score >= 38) return 'Неровный';
    return 'Слабый';
  }

  /// Текущая серия: положительное число — победы, отрицательное — поражения.
  int get currentStreak {
    if (matches.isEmpty) {
      return 0;
    }
    final firstWin = matches.first.isWin;
    var streak = 0;
    for (final match in matches) {
      if (match.isWin != firstWin) {
        break;
      }
      streak++;
    }
    return firstWin ? streak : -streak;
  }

  int get longestWinStreak {
    final chronological = [...matches]
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    var current = 0;
    var best = 0;
    for (final match in chronological) {
      if (match.isWin) {
        current++;
        if (current > best) {
          best = current;
        }
      } else {
        current = 0;
      }
    }
    return best;
  }

  /// Оценка одного матча 0..100 для графика формы.
  double matchScore(MatchRecord match) {
    final base = match.isWin ? 68.0 : 32.0;
    final bonus = (match.kda.clamp(0.0, 6.0) / 6.0) * 32.0;
    return (base + bonus).clamp(0.0, 100.0);
  }

  /// Последние [count] матчей в хронологическом порядке для графика.
  List<FormPoint> recentForm([int count = 20]) {
    final recent = matches.take(count).toList().reversed.toList();
    return [
      for (var index = 0; index < recent.length; index++)
        FormPoint(
          index: index,
          match: recent[index],
          score: matchScore(recent[index]),
        ),
    ];
  }

  /// Серия результатов последних матчей (W/L) от нового к старому.
  List<bool> recentResults([int count = 10]) =>
      matches.take(count).map((match) => match.isWin).toList();

  /// Винрейт и количество матчей за последние [days] дней.
  RecentWindow recentWindow([int days = 7]) {
    final now = DateTime.now();
    final from = now.subtract(Duration(days: days));
    final previousFrom = now.subtract(Duration(days: days * 2));
    var wins = 0;
    var losses = 0;
    var previousWins = 0;
    var previousMatches = 0;
    for (final match in matches) {
      final date = DateTime.fromMillisecondsSinceEpoch(match.startTime * 1000);
      if (date.isBefore(from)) {
        if (!date.isBefore(previousFrom)) {
          previousMatches++;
          if (match.isWin) {
            previousWins++;
          }
        }
        continue;
      }
      if (match.isWin) {
        wins++;
      } else {
        losses++;
      }
    }
    final total = wins + losses;
    final previousRate = previousMatches == 0
        ? null
        : previousWins / previousMatches;
    return RecentWindow(
      wins: wins,
      losses: losses,
      winRate: total == 0 ? 0 : wins / total,
      previousWinRate: previousRate,
    );
  }

  /// Статистика по дням недели (Пн..Вс).
  List<WeekdayStat> get weekdayStats {
    final stats = List<WeekdayStat>.generate(
      7,
      (index) => WeekdayStat(weekday: index, matches: 0, wins: 0),
    );
    for (final match in matches) {
      final date = DateTime.fromMillisecondsSinceEpoch(match.startTime * 1000);
      final index = (date.weekday + 6) % 7;
      final current = stats[index];
      stats[index] = WeekdayStat(
        weekday: index,
        matches: current.matches + 1,
        wins: current.wins + (match.isWin ? 1 : 0),
      );
    }
    return stats;
  }

  /// Сетка активности за последние 12 недель (по неделям, Пн..Вс).
  ActivityGrid get activity {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayIndex = (today.weekday + 6) % 7;
    final currentWeekStart = today.subtract(Duration(days: todayIndex));
    final firstWeekStart = currentWeekStart.subtract(
      const Duration(days: 7 * 11),
    );

    final byDate = <int, List<bool>>{};
    for (final match in matches) {
      final date = DateTime.fromMillisecondsSinceEpoch(match.startTime * 1000);
      final key = _dateKey(date);
      byDate.putIfAbsent(key, () => <bool>[]).add(match.isWin);
    }

    final columns = <List<ActivityDay?>>[];
    var total = 0;
    var best = 0;
    for (var week = 0; week < 12; week++) {
      final column = <ActivityDay?>[];
      for (var day = 0; day < 7; day++) {
        final date = firstWeekStart.add(Duration(days: week * 7 + day));
        if (date.isAfter(today)) {
          column.add(null);
          continue;
        }
        final results = byDate[_dateKey(date)] ?? const <bool>[];
        final wins = results.where((win) => win).length;
        column.add(
          ActivityDay(date: date, matches: results.length, wins: wins),
        );
        total += results.length;
        if (results.length > best) {
          best = results.length;
        }
      }
      columns.add(column);
    }

    return ActivityGrid(
      columns: columns,
      totalMatches: total,
      maxMatches: best,
    );
  }
}

int _dateKey(DateTime date) => date.year * 10000 + date.month * 100 + date.day;

class FormPoint {
  const FormPoint({
    required this.index,
    required this.match,
    required this.score,
  });

  final int index;
  final MatchRecord match;
  final double score;
}

class RecentWindow {
  const RecentWindow({
    required this.wins,
    required this.losses,
    required this.winRate,
    required this.previousWinRate,
  });

  final int wins;
  final int losses;
  final double winRate;
  final double? previousWinRate;

  int get matches => wins + losses;

  double? get delta =>
      previousWinRate == null ? null : winRate - previousWinRate!;
}

class WeekdayStat {
  const WeekdayStat({
    required this.weekday,
    required this.matches,
    required this.wins,
  });

  /// 0 — понедельник, 6 — воскресенье.
  final int weekday;
  final int matches;
  final int wins;

  double get winRate => matches == 0 ? 0 : wins / matches;
}

class ActivityGrid {
  const ActivityGrid({
    required this.columns,
    required this.totalMatches,
    required this.maxMatches,
  });

  /// 12 колонок по 7 дней; `null` — день вне диапазона (будущее).
  final List<List<ActivityDay?>> columns;
  final int totalMatches;
  final int maxMatches;
}

class ActivityDay {
  const ActivityDay({
    required this.date,
    required this.matches,
    required this.wins,
  });

  final DateTime date;
  final int matches;
  final int wins;

  bool get hasGames => matches > 0;
  bool get allWins => matches > 0 && wins == matches;
  bool get hasLosses => wins < matches;
}

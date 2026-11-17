import 'package:equatable/equatable.dart';

import 'match_record.dart';
import 'player_badge.dart';
import 'player_hero_stat.dart';

/// Профиль игрока: агрегаты по героям и последние матчи.
class PlayerProfile extends Equatable {
  const PlayerProfile({
    required this.accountId,
    required this.heroes,
    required this.matches,
    required this.badge,
  });

  final int accountId;
  final List<PlayerHeroStat> heroes;
  final List<MatchRecord> matches;
  final PlayerBadge? badge;

  bool get isEmpty => heroes.isEmpty && matches.isEmpty;

  int get totalMatches {
    var total = 0;
    for (final hero in heroes) {
      total += hero.matches;
    }
    return total;
  }

  int get totalWins {
    var total = 0;
    for (final hero in heroes) {
      total += hero.wins;
    }
    return total;
  }

  double get winRate => totalMatches == 0 ? 0 : totalWins / totalMatches;

  int get totalKills {
    var total = 0;
    for (final hero in heroes) {
      total += hero.kills;
    }
    return total;
  }

  int get totalDeaths {
    var total = 0;
    for (final hero in heroes) {
      total += hero.deaths;
    }
    return total;
  }

  int get totalAssists {
    var total = 0;
    for (final hero in heroes) {
      total += hero.assists;
    }
    return total;
  }

  /// Общий KDA по всем героям.
  double get kda {
    if (totalDeaths <= 0) {
      return (totalKills + totalAssists).toDouble();
    }
    return (totalKills + totalAssists) / totalDeaths;
  }

  /// Самый сыгранный герой (по числу матчей).
  PlayerHeroStat? get mostPlayedHero {
    if (heroes.isEmpty) {
      return null;
    }
    return heroes.reduce(
      (best, hero) => hero.matches > best.matches ? hero : best,
    );
  }

  /// Лучший герой по винрейту среди тех, у кого >= 5 матчей.
  PlayerHeroStat? get bestHeroByWinRate {
    final eligible = heroes.where((h) => h.matches >= 5).toList();
    if (eligible.isEmpty) {
      return null;
    }
    return eligible.reduce(
      (best, hero) => hero.winRate > best.winRate ? hero : best,
    );
  }

  @override
  List<Object?> get props => [accountId, heroes, matches, badge];
}

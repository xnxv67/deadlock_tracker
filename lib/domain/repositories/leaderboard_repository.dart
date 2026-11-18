import '../entities/leaderboard_player.dart';

/// Регионы, поддерживаемые /v1/leaderboard/{region}.
enum LeaderboardRegion {
  europe('Europe', 'EUROPE'),
  asia('Asia', 'ASIA'),
  na('NAmerica', 'СЕВ. АМЕРИКА'),
  sa('SAmerica', 'ЮЖ. АМЕРИКА'),
  oceania('Oceania', 'OCEANIA');

  const LeaderboardRegion(this.apiValue, this.label);

  final String apiValue;
  final String label;
}

abstract class LeaderboardRepository {
  /// Топ-100 игроков региона.
  Future<List<LeaderboardPlayer>> getLeaderboard({
    LeaderboardRegion region = LeaderboardRegion.europe,
  });
}

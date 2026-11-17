import 'json_utils.dart';

/// Строка `/v1/leaderboard/{region}`.
class LeaderboardEntryDto {
  const LeaderboardEntryDto({
    required this.position,
    required this.name,
    required this.possibleAccountIds,
    required this.topHeroIds,
  });

  final int position;
  final String name;
  final List<int> possibleAccountIds;
  final List<int> topHeroIds;

  factory LeaderboardEntryDto.fromJson(
    Map<String, dynamic> json, {
    required int fallbackPosition,
  }) {
    final rank = jsonInt(json['rank'], fallbackPosition);

    return LeaderboardEntryDto(
      position: rank > 0 ? rank : fallbackPosition,
      name: jsonString(json['account_name'], 'Игрок #$fallbackPosition'),
      possibleAccountIds: jsonList(json['possible_account_ids'])
          .map((value) => jsonInt(value))
          .where((id) => id > 0)
          .toList(growable: false),
      topHeroIds: jsonList(json['top_hero_ids'])
          .map((value) => jsonInt(value))
          .where((id) => id > 0)
          .toList(growable: false),
    );
  }
}

import 'json_utils.dart';

/// Ответ /v1/players/steam-search — профиль Steam.
class SteamProfileDto {
  const SteamProfileDto({
    required this.accountId,
    required this.personaName,
    required this.profileUrl,
    required this.avatar,
    required this.avatarMedium,
    required this.avatarFull,
    required this.countryCode,
    required this.lastUpdated,
  });

  final int accountId;
  final String personaName;
  final String profileUrl;
  final String avatar;
  final String avatarMedium;
  final String avatarFull;
  final String countryCode;
  final String lastUpdated;

  factory SteamProfileDto.fromJson(Map<String, dynamic> json) {
    return SteamProfileDto(
      accountId: jsonInt(json['account_id']),
      personaName: jsonString(json['personaname']),
      profileUrl: jsonString(json['profileurl']),
      avatar: jsonString(json['avatar']),
      avatarMedium: jsonString(json['avatarmedium']),
      avatarFull: jsonString(json['avatarfull']),
      countryCode: jsonString(json['countrycode']),
      lastUpdated: jsonString(json['last_updated']),
    );
  }
}

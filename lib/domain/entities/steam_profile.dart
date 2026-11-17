import 'package:equatable/equatable.dart';

/// Профиль Steam из /v1/players/steam-search.
class SteamProfile extends Equatable {
  const SteamProfile({
    required this.accountId,
    required this.personaName,
    required this.avatar,
    required this.avatarMedium,
    required this.profileUrl,
    required this.countryCode,
  });

  final int accountId;
  final String personaName;
  final String avatar;
  final String avatarMedium;
  final String profileUrl;
  final String countryCode;

  @override
  List<Object?> get props => [accountId, personaName, avatar];
}

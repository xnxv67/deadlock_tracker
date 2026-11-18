import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/error_messages.dart';
import '../../../domain/entities/player_badge.dart';
import '../../../domain/entities/steam_profile.dart';
import '../../../domain/repositories/player_repository.dart';
import '../../../presentation/widgets/error_view.dart';
import '../../../presentation/widgets/rank_badge_chip.dart';
import '../../../presentation/widgets/remote_image.dart';
import '../../../presentation/widgets/shimmer_skeleton.dart';
import 'player_profile_screen.dart';

/// Поиск игроков по нику Steam с debounce и переходом в профиль.
class PlayerSearchScreen extends StatefulWidget {
  const PlayerSearchScreen({super.key});

  @override
  State<PlayerSearchScreen> createState() => _PlayerSearchScreenState();
}

class _PlayerSearchScreenState extends State<PlayerSearchScreen> {
  final TextEditingController _controller = TextEditingController();

  Timer? _debounce;
  List<SteamProfile> _results = const [];
  Map<int, PlayerBadge> _ranks = const {};
  bool _loading = false;
  bool _searched = false;
  AppErrorType? _error;
  int _requestId = 0;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    final query = value.trim();
    if (query.isEmpty) {
      _requestId++;
      setState(() {
        _results = const [];
        _ranks = const {};
        _loading = false;
        _searched = false;
        _error = null;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 350), () {
      _search(query);
    });
  }

  Future<void> _search(String query) async {
    final requestId = ++_requestId;
    final repository = context.read<PlayerRepository>();

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await repository.searchSteam(query);
      if (!mounted || requestId != _requestId) return;

      Map<int, PlayerBadge> ranks = const {};
      if (results.isNotEmpty) {
        try {
          ranks = await repository.getRanks(
            results.map((profile) => profile.accountId).toList(),
          );
        } catch (_) {
          // Ранг — украшение, результаты поиска важнее.
        }
      }
      if (!mounted || requestId != _requestId) return;

      setState(() {
        _results = results;
        _ranks = ranks;
        _loading = false;
        _searched = true;
      });
    } on AppException catch (error) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _error = error.type;
        _loading = false;
        _searched = true;
      });
    } catch (_) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _error = AppErrorType.unknown;
        _loading = false;
        _searched = true;
      });
    }
  }

  void _openProfile(SteamProfile profile) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PlayerProfileScreen(
          accountId: profile.accountId,
          personaName: profile.personaName,
          avatarUrl: profile.avatarMedium.isNotEmpty
              ? profile.avatarMedium
              : profile.avatar,
          badge: _ranks[profile.accountId],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
          child: TextField(
            controller: _controller,
            onChanged: _onQueryChanged,
            textInputAction: TextInputAction.search,
            onSubmitted: (value) {
              _debounce?.cancel();
              final query = value.trim();
              if (query.isNotEmpty) {
                _search(query);
              }
            },
            decoration: InputDecoration(
              hintText: 'Ник в Steam...',
              isDense: true,
              prefixIcon: const Icon(
                Icons.person_search_rounded,
                size: 20,
                color: AppColors.muted,
              ),
              suffixIcon: ValueListenableBuilder<TextEditingValue>(
                valueListenable: _controller,
                builder: (context, value, child) {
                  if (value.text.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 18),
                    onPressed: () {
                      _debounce?.cancel();
                      _controller.clear();
                      _onQueryChanged('');
                    },
                  );
                },
              ),
            ),
          ),
        ),
        Expanded(child: _body()),
      ],
    );
  }

  Widget _body() {
    if (_loading) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
        children: const [
          SkeletonTable(rows: 6, showAvatar: true, trailingBlocks: 1),
        ],
      );
    }

    if (_error != null) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
        children: [
          ErrorView(
            title: errorTitle(_error),
            text: errorText(_error),
            onRetry: () {
              final query = _controller.text.trim();
              if (query.isNotEmpty) {
                _search(query);
              }
            },
          ),
        ],
      );
    }

    if (!_searched) {
      return const _Hint();
    }

    if (_results.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
        children: const [
          _EmptyCard(text: 'Игроки с таким ником не найдены'),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
      itemCount: _results.length + 1,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 2),
            child: Text(
              'НАЙДЕНО: ${_results.length}',
              style: const TextStyle(
                color: AppColors.copper,
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
              ),
            ),
          );
        }
        final profile = _results[index - 1];
        return _PlayerResultTile(
          profile: profile,
          badge: _ranks[profile.accountId],
          onTap: () => _openProfile(profile),
        );
      },
    );
  }
}

class _PlayerResultTile extends StatelessWidget {
  const _PlayerResultTile({
    required this.profile,
    required this.badge,
    required this.onTap,
  });

  final SteamProfile profile;
  final PlayerBadge? badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = profile.avatarMedium.isNotEmpty
        ? profile.avatarMedium
        : profile.avatar;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: AppColors.border),
                ),
                clipBehavior: Clip.antiAlias,
                child: RemoteImage(
                  url: avatarUrl,
                  fallback: const DeadlockImageFallback(),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      profile.personaName.isEmpty
                          ? 'Игрок #${profile.accountId}'
                          : profile.personaName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          'ID ${profile.accountId}',
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                        if (profile.countryCode.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Text(
                            profile.countryCode.toUpperCase(),
                            style: const TextStyle(
                              color: AppColors.copper,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (badge != null) RankBadgeChip(badge: badge, compact: true),
              const SizedBox(width: 3),
              const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: AppColors.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 24),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 34),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.person_search_rounded,
                size: 40,
                color: AppColors.copper,
              ),
              const SizedBox(height: 12),
              const Text(
                'Найди игрока',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              const Text(
                'Начни вводить ник Steam — поиск сработает автоматически. '
                'Затем открой профиль с винрейтом и любимыми героями.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 11.5,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.search_off_rounded,
            size: 34,
            color: AppColors.muted,
          ),
          const SizedBox(height: 10),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

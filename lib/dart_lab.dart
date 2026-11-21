// Лабораторная работа №2: базовый синтаксис Dart.
// Файл самостоятельный: его не импортирует приложение, но он компилируется
// и может быть запущен командой `dart lib/dart_lab.dart`.
// ignore_for_file: avoid_print

import 'dart:async';

enum HeroRole { carry, support, tank }

extension StringCapitalize on String {
  /// Делает первую букву заглавной, остальные оставляет как есть.
  String capitalize() {
    if (isEmpty) {
      return this;
    }
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}

class Player {
  Player({
    required this.name,
    required this.hero,
    required this.kda,
    this.role = HeroRole.carry,
  });

  final String name;
  final String hero;
  final double kda;
  final HeroRole role;

  bool isCarry() => role == HeroRole.carry;

  String get displayName => name.capitalize();

  @override
  String toString() =>
      '$displayName ($hero, ${role.name}): KDA ${kda.toStringAsFixed(2)}';
}

/// Имитация загрузки игроков с сервера через [Future].
Future<List<Player>> loadPlayers() async {
  await Future<void>.delayed(const Duration(milliseconds: 300));

  return <Player>[
    Player(name: 'shroud', hero: 'Haze', kda: 6.4),
    Player(name: 'mikaelS', hero: 'Abrams', kda: 4.1, role: HeroRole.tank),
    Player(
      name: 'average_jon',
      hero: 'Dynamo',
      kda: 5.2,
      role: HeroRole.support,
    ),
    Player(name: 'lumi', hero: 'Infernus', kda: 3.8),
  ];
}

void main() async {
  final players = await loadPlayers();

  print('=== Все игроки ===');
  for (final player in players) {
    print(player);
  }

  // Анонимная функция в качестве компаратора: сортировка по KDA.
  players.sort((a, b) => b.kda.compareTo(a.kda));

  print('\n=== Топ по KDA ===');
  for (final player in players) {
    print('${player.displayName}: ${player.kda.toStringAsFixed(2)}');
  }

  final carries = players.where((player) => player.isCarry()).toList();
  print('\nКерри в списке: ${carries.length}');

  // Явная демонстрация Future.delayed.
  await Future<void>.delayed(const Duration(milliseconds: 100));
  print('Данные загружены асинхронно.');
}

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'items_screen.dart';
import 'leaderboard_screen.dart';
import 'meta_screen.dart';
import 'player_screen.dart';
import 'counter_matrix_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  /// Вкладки создаются лениво: при старте грузится только мета.
  final Set<int> _visited = {0};

  static const List<Widget> _tabs = [
    MetaScreen(),
    PlayerScreen(),
    ItemsScreen(),
    LeaderboardScreen(),
    CounterMatrixScreen(),
  ];

  void _select(int index) {
    if (index == _index) {
      return;
    }
    setState(() {
      _index = index;
      _visited.add(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          for (var index = 0; index < _tabs.length; index++)
            _visited.contains(index) ? _tabs[index] : const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.surfaceLight)),
        ),
        child: BottomNavigationBar(
          currentIndex: _index,
          onTap: _select,
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.gold,
          unselectedItemColor: AppColors.muted,
          selectedFontSize: 10.5,
          unselectedFontSize: 10,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.insights_rounded),
              label: 'Мета',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_search_rounded),
              label: 'Игрок',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2_rounded),
              label: 'Предметы',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.emoji_events_rounded),
              label: 'Лидеры',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.grid_on_rounded),
              label: 'Матрица',
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../features/heroes/screens/main_screen.dart';
import '../../features/items/screens/items_screen.dart';
import 'counter_matrix_screen.dart';
import 'leaderboard_screen.dart';
import 'player_screen.dart';

/// Единая оболочка приложения: все разделы в одном нижнем меню.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final PageController _pageController = PageController();
  int _index = 0;

  static const List<Widget> _tabs = [
    MainScreen(),
    PlayerScreen(),
    LeaderboardScreen(),
    CounterMatrixScreen(),
    ItemsScreen(),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _select(int index) {
    if (index == _index) {
      return;
    }
    setState(() => _index = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (index) {
          if (index != _index) {
            setState(() => _index = index);
          }
        },
        children: _tabs,
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
          selectedFontSize: 11,
          unselectedFontSize: 11,
          selectedLabelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.people_alt_rounded),
              label: 'Герои',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_search_rounded),
              label: 'Игрок',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.emoji_events_rounded),
              label: 'Лидеры',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.grid_on_rounded),
              label: 'Контрпики',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.backpack_rounded),
              label: 'Предметы',
            ),
          ],
        ),
      ),
    );
  }
}

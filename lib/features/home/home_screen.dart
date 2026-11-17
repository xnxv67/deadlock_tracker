import 'package:flutter/material.dart';

/// Главный экран лабораторной работы №1.
///
/// В AppBar выводится подпись студента. Позже надпись можно будет скрыть
/// настройкой — для этого текст вынесен в отдельную константу.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  /// Замени на свои ФИО и группу.
  static const String studentLabel = 'Иванов И.И., группа 3-ИС-21';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text(studentLabel)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.sports_esports_outlined,
              size: 64,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text('Deadlock Tracker', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Лабораторная работа №1',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

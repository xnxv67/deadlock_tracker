import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Секретная страница с лабораторными работами (пасхалка).
class LabsScreen extends StatelessWidget {
  const LabsScreen({super.key});

  static const List<String> _labs = [
    'Лабораторная 1 — Экран приветствия',
    'Лабораторная 2 — Основы Dart',
    'Лабораторная 3 — Карточки героев',
    'Лабораторная 4 — Лайки, Snackbar и детали',
    'Лабораторная 5 — Сетевой клиент',
    'Лабораторная 6 — Поиск с BLoC и debounce',
    'Лабораторная 7 — Иконка, локализация, SharedPreferences',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Лабораторные работы')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.copper.withValues(alpha: 0.35),
              ),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2B0F16), Color(0xFF171214)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 3,
                      decoration: BoxDecoration(
                        color: AppColors.copper,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 9),
                    const Text(
                      'DEADLOCK',
                      style: TextStyle(
                        color: AppColors.gold,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Лабораторные работы',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 14),
                _InfoRow(label: 'Студент', value: 'Павлов Никита Сергеевич'),
                const SizedBox(height: 6),
                _InfoRow(label: 'Группа', value: 'ПДО-37'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 10),
            child: Text(
              'ВЫПОЛНЕННЫЕ РАБОТЫ',
              style: TextStyle(
                color: AppColors.copper,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
          ),
          for (var i = 0; i < _labs.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: Color(0xFF1F3A28),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: AppColors.win,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _labs[i],
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 22),
          const Text(
            'Секретная страница найдена! 🎉',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.gold,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 78,
          child: Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

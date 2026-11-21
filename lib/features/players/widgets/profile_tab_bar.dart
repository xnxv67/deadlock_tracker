import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class ProfileTabItem {
  const ProfileTabItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

class ProfileTabBar extends StatelessWidget {
  const ProfileTabBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<ProfileTabItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.7)),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var index = 0; index < items.length; index++)
              Padding(
                padding: EdgeInsets.only(
                  right: index == items.length - 1 ? 0 : 4,
                ),
                child: _ProfileTabButton(
                  item: items[index],
                  selected: index == selectedIndex,
                  onTap: () => onSelected(index),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProfileTabButton extends StatelessWidget {
  const _ProfileTabButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final ProfileTabItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        hoverColor: AppColors.copper.withValues(alpha: 0.1),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.ember : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                item.icon,
                size: 14,
                color: selected ? Colors.black : AppColors.muted,
              ),
              const SizedBox(width: 6),
              Text(
                item.label.toUpperCase(),
                style: TextStyle(
                  color: selected ? Colors.black : AppColors.muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.7,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

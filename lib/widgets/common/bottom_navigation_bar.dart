import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class CustomBottomNavigationBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<CustomBottomNavigationBar> createState() =>
      _CustomBottomNavigationBarState();
}

class _CustomBottomNavigationBarState extends State<CustomBottomNavigationBar> {
  final List<BottomNavItem> _navItems = [
    BottomNavItem(title: 'Trang chủ', icon: Icons.home),
    BottomNavItem(title: 'Sức khỏe', icon: Icons.favorite),
    BottomNavItem(title: 'Tâm trạng', icon: Icons.mood),
    BottomNavItem(title: 'AI Calo', icon: Icons.fastfood_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: _navItems.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return _buildBottomNavItem(item, index);
        }).toList(),
      ),
    );
  }

  Widget _buildBottomNavItem(BottomNavItem item, int index) {
    bool isSelected = widget.currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => widget.onTap(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                item.icon,
                color: isSelected ? AppColors.primary : AppColors.textTertiary,
                size: 24,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                item.title,
                style: AppTextStyles.caption.copyWith(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textTertiary,
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BottomNavItem {
  final String title;
  final IconData icon;

  BottomNavItem({required this.title, required this.icon});
}

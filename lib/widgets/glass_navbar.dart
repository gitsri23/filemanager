import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class GlassNavBar extends StatelessWidget {
  final int selectedIndex;
  final void Function(int) onItemSelected;

  const GlassNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      _NavItem(Icons.home_rounded, Icons.home_outlined, 'Home'),
      _NavItem(Icons.folder_rounded, Icons.folder_outlined, 'Files'),
      _NavItem(Icons.cleaning_services_rounded,
          Icons.cleaning_services_outlined, 'Clean'),
      _NavItem(Icons.settings_rounded, Icons.settings_outlined, 'Settings'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        border: const Border(
          top: BorderSide(color: Color(0xFF1A1A1A), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 64,
          child: Row(
            children: items
                .asMap()
                .entries
                .map((e) => Expanded(
                      child: _NavBarItem(
                        item: e.value,
                        isSelected: selectedIndex == e.key,
                        onTap: () => onItemSelected(e.key),
                      ),
                    ))
                .toList(),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData selectedIcon;
  final IconData unselectedIcon;
  final String label;
  const _NavItem(this.selectedIcon, this.unselectedIcon, this.label);
}

class _NavBarItem extends StatelessWidget {
  final _NavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryColor.withOpacity(0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isSelected ? item.selectedIcon : item.unselectedIcon,
                color: isSelected ? AppTheme.primaryColor : Colors.white30,
                size: 24,
              ),
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 250),
              style: TextStyle(
                color: isSelected ? AppTheme.primaryColor : Colors.white30,
                fontSize: 11,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
              child: Text(item.label),
            ),
          ],
        ),
      ),
    );
  }
}

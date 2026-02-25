import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/colors.dart';

class BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;

  const BottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      decoration: BoxDecoration(
        color: AppColors.navBarDark.withValues(alpha: 0.95),
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.05),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            index: 0,
            icon: Icons.explore,
            label: 'Discovery',
            isSelected: selectedIndex == 0,
          ),
          _buildNavItem(
            index: 1,
            icon: Icons.folder_special,
            label: 'My Models',
            isSelected: selectedIndex == 1,
          ),
          _buildNavItem(
            index: 2,
            icon: Icons.chat_bubble,
            label: 'Chat',
            isSelected: selectedIndex == 2,
          ),
          _buildNavItem(
            index: 3,
            icon: Icons.hub,
            label: 'Server',
            isSelected: selectedIndex == 3,
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(
              horizontal: isSelected ? 24 : 0,
              vertical: isSelected ? 10 : 0,
            ),
            decoration: BoxDecoration(
              color: isSelected 
                  ? AppColors.primary.withValues(alpha: 0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: isSelected
                ? Container(
                    width: 64,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      icon,
                      size: 24,
                      color: AppColors.primary,
                    ),
                  )
                : SizedBox(
                    height: 32,
                    child: Icon(
                      icon,
                      size: 24,
                      color: AppColors.textSecondaryDark,
                    ),
                  ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.notoSans(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? Colors.white : AppColors.textSecondaryDark,
            ),
          ),
        ],
      ),
    );
  }
}


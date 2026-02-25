import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/colors.dart';
import '../../app/data/models/ai_model.dart';

class FilterChipWidget extends StatelessWidget {
  final FilterCategory category;
  final VoidCallback onTap;

  const FilterChipWidget({
    super.key,
    required this.category,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: category.isSelected ? AppColors.primary : AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(18),
          border: category.isSelected
              ? null
              : Border.all(color: Colors.white.withValues(alpha: 0.1)),
          boxShadow: category.isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (category.icon != null) ...[
              Icon(
                category.icon,
                size: 16,
                color: category.iconColor ?? Colors.white,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              category.name,
              style: GoogleFonts.notoSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: category.isSelected
                    ? Colors.white
                    : AppColors.textSecondaryDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
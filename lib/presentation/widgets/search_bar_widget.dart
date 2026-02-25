import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';

class SearchBarWidget extends StatelessWidget {
  final Function(String) onChanged;
  final VoidCallback? onMicTap;

  const SearchBarWidget({
    super.key,
    required this.onChanged,
    this.onMicTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          Icon(
            Icons.search,
            color: AppColors.textSecondaryDark,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              onChanged: onChanged,
              style: const TextStyle(
                color: AppColors.textPrimaryDark,
                fontSize: 16,
              ),
              decoration: InputDecoration(
                hintText: 'Find Llama, Mistral, Gemma...',
                hintStyle: TextStyle(
                  color: AppColors.textSecondaryDark.withValues(alpha: 0.7),
                  fontSize: 16,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          GestureDetector(
            onTap: onMicTap,
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Icon(
                Icons.mic,
                color: AppColors.textSecondaryDark,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}
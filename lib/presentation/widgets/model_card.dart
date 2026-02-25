import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/colors.dart';
import '../../app/data/models/ai_model.dart';

class ModelCard extends StatelessWidget {
  final AIModel model;
  final VoidCallback onDownload;
  final VoidCallback? onCancelDownload;

  const ModelCard({
    super.key,
    required this.model,
    required this.onDownload,
    this.onCancelDownload,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        children: [
          // Top section
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: model.iconBackgroundColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  model.icon,
                  size: 28,
                  color: model.iconColor,
                ),
              ),
              const SizedBox(width: 16),
              // Title and description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      model.name,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimaryDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            model.version,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondaryDark,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '•',
                          style: TextStyle(
                            color: AppColors.textSecondaryDark,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            model.description,
                            style: GoogleFonts.notoSans(
                              fontSize: 12,
                              color: AppColors.textSecondaryDark,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Status indicator
              _buildStatusIndicator(),
            ],
          ),
          const SizedBox(height: 12),
          // Divider
          Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.05),
          ),
          const SizedBox(height: 12),
          // Bottom section - Stats or Progress
          model.status == ModelStatus.downloading
              ? _buildProgressSection()
              : _buildStatsSection(),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator() {
    Color backgroundColor;
    Color iconColor;
    IconData icon;

    if (model.readiness == ModelReadiness.phoneReady) {
      backgroundColor = AppColors.success.withValues(alpha: 0.2);
      iconColor = AppColors.success;
      icon = Icons.bolt;
    } else {
      backgroundColor = AppColors.warning.withValues(alpha: 0.2);
      iconColor = AppColors.warning;
      icon = Icons.memory;
    }

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: 18,
        color: iconColor,
      ),
    );
  }

  Widget _buildStatsSection() {
    return Row(
      children: [
        // Size
        _buildStatColumn('SIZE', model.size),
        const SizedBox(width: 24),
        // Quant
        _buildStatColumn('QUANT', model.quantization),
        const Spacer(),
        // Download button
        GestureDetector(
          onTap: onDownload,
          child: Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.download,
                  size: 16,
                  color: Colors.white,
                ),
                const SizedBox(width: 6),
                Text(
                  'Get',
                  style: GoogleFonts.notoSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
            color: AppColors.textSecondaryDark.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimaryDark,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressSection() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 6,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: model.downloadProgress,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '${(model.downloadProgress * 100).toInt()}%',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onCancelDownload,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.transparent,
            ),
            child: Icon(
              Icons.close,
              size: 18,
              color: AppColors.textSecondaryDark,
            ),
          ),
        ),
      ],
    );
  }
}



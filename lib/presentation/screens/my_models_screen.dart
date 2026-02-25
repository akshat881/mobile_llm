import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/services/model_manager.dart';
import '../../app/services/inference_service.dart';
import '../../core/theme/colors.dart';

class MyModelsScreen extends StatelessWidget {
  const MyModelsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final modelManager = Get.find<ModelManager>();
    final inferenceService = Get.find<InferenceService>();

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 12,
              bottom: 16,
              left: 16,
              right: 16,
            ),
            decoration: BoxDecoration(
              color: AppColors.backgroundDark.withValues(alpha: 0.95),
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Local Models',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimaryDark,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: AppColors.textPrimaryDark),
                  onPressed: () => modelManager.scanForModels(),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: Obx(() {
              if (modelManager.isScanning.value) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              }

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Storage section
                  _buildStorageSection(modelManager),
                  const SizedBox(height: 16),
                  // Active model info
                  Obx(() => inferenceService.isModelLoaded.value
                      ? _buildActiveModelBanner(inferenceService)
                      : const SizedBox()),
                  // Active downloads
                  Obx(() {
                    if (modelManager.activeDownloads.isEmpty) {
                      return const SizedBox();
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24),
                        Text(
                          'DOWNLOADING',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.5,
                            color: AppColors.textSecondaryDark,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...modelManager.activeDownloads.values.map(
                          (task) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildDownloadingCard(task, modelManager),
                          ),
                        ),
                      ],
                    );
                  }),
                  const SizedBox(height: 24),
                  // Downloaded models header
                  Obx(() => Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Downloaded (${modelManager.downloadedModels.length})',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimaryDark,
                            ),
                          ),
                        ],
                      )),
                  const SizedBox(height: 16),
                  // Model cards or empty state
                  Obx(() {
                    if (modelManager.downloadedModels.isEmpty) {
                      return _buildEmptyState();
                    }
                    return Column(
                      children: modelManager.downloadedModels.map((model) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildModelCard(
                            model: model,
                            inferenceService: inferenceService,
                            modelManager: modelManager,
                          ),
                        );
                      }).toList(),
                    );
                  }),
                  const SizedBox(height: 100),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.download_for_offline_outlined,
            size: 64,
            color: AppColors.textSecondaryDark.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No Models Yet',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondaryDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Go to the Discover tab to search\nand download models',
            textAlign: TextAlign.center,
            style: GoogleFonts.notoSans(
              fontSize: 14,
              color: AppColors.textSecondaryDark.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadingCard(DownloadTask task, ModelManager modelManager) {
    return Obx(() => Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.downloading,
                        color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.modelId.split('/').last,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimaryDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          task.statusText.value,
                          style: GoogleFonts.notoSans(
                            fontSize: 12,
                            color: AppColors.textSecondaryDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close,
                        color: AppColors.textSecondaryDark, size: 20),
                    onPressed: () => modelManager.cancelDownload(task.modelId),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: task.progress.value,
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${(task.progress.value * 100).toInt()}%',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ));
  }

  Widget _buildActiveModelBanner(InferenceService inferenceService) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.success.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.memory, color: AppColors.success, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ACTIVE MODEL',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(height: 2),
                Obx(() => Text(
                      inferenceService.currentModelName.value,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimaryDark,
                      ),
                    )),
              ],
            ),
          ),
          TextButton(
            onPressed: () => inferenceService.unloadModel(),
            child: Text(
              'Unload',
              style: GoogleFonts.notoSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStorageSection(ModelManager modelManager) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Obx(() => Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MODEL STORAGE',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                      color: AppColors.textSecondaryDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${modelManager.downloadedModels.length}',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimaryDark,
                    ),
                  ),
                  Text(
                    'Models',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      color: AppColors.textSecondaryDark,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      modelManager.totalStorageUsedFormatted,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      'Used',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 10,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          )),
    );
  }

  Widget _buildModelCard({
    required LocalModel model,
    required InferenceService inferenceService,
    required ModelManager modelManager,
  }) {
    return Obx(() {
      final isActive =
          inferenceService.currentModelPath.value == model.filePath;

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive
                ? AppColors.primary.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.05),
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: isActive
                        ? const LinearGradient(
                            colors: [AppColors.primary, AppColors.blue],
                          )
                        : null,
                    color:
                        isActive ? null : Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.smart_toy,
                      size: 24,
                      color:
                          isActive ? Colors.white : AppColors.textSecondaryDark,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        model.name,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimaryDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              model.sizeFormatted,
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondaryDark,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'GGUF',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondaryDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: AppColors.textSecondaryDark),
                  onPressed: () => _confirmDelete(model, modelManager),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(height: 1, color: Colors.white.withValues(alpha: 0.05)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    isActive ? 'Loaded in RAM' : 'Not Loaded',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isActive
                          ? AppColors.success
                          : AppColors.textSecondaryDark,
                    ),
                  ),
                ),
                SizedBox(
                  height: 32,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (isActive) {
                        await inferenceService.unloadModel();
                      } else {
                        try {
                          // Validate minimum size (10MB) — reject projectors/corrupted files
                          if (model.sizeBytes < 10 * 1024 * 1024) {
                            Get.snackbar(
                              'Invalid Model',
                              'This file is too small (${model.sizeFormatted}) to be a valid model. Please download a proper GGUF model from the Discover tab.',
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: AppColors.error.withValues(alpha: 0.8),
                              colorText: Colors.white,
                              duration: const Duration(seconds: 4),
                            );
                            return;
                          }
                          await inferenceService.loadModel(
                            model.filePath,
                            modelName: model.name,
                          );
                          Get.snackbar('Model Loaded',
                              '${model.name} is ready for chat.',
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor:
                                  AppColors.success.withValues(alpha: 0.8),
                              colorText: Colors.white);
                        } catch (e) {
                          Get.snackbar('Error', e.toString(),
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor:
                                  AppColors.error.withValues(alpha: 0.8),
                              colorText: Colors.white);
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isActive
                          ? AppColors.error.withValues(alpha: 0.2)
                          : AppColors.primary,
                      foregroundColor:
                          isActive ? AppColors.error : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: Text(
                      isActive ? 'Unload' : 'Load',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  void _confirmDelete(LocalModel model, ModelManager modelManager) {
    Get.defaultDialog(
      title: 'Delete Model',
      titleStyle: GoogleFonts.spaceGrotesk(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimaryDark,
      ),
      middleText: 'Delete "${model.name}"? This cannot be undone.',
      middleTextStyle: GoogleFonts.notoSans(
        fontSize: 14,
        color: AppColors.textSecondaryDark,
      ),
      backgroundColor: AppColors.surfaceDark,
      textCancel: 'Cancel',
      textConfirm: 'Delete',
      confirmTextColor: Colors.white,
      cancelTextColor: AppColors.textSecondaryDark,
      buttonColor: AppColors.error,
      onConfirm: () {
        modelManager.deleteModel(model.id);
        Get.back();
      },
    );
  }
}

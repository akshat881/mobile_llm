import 'dart:io';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';

class LocalModel {
  final String id;
  final String name;
  final String filePath;
  final int sizeBytes;
  final DateTime addedAt;
  final String? repoId; // HuggingFace repo ID

  LocalModel({
    required this.id,
    required this.name,
    required this.filePath,
    required this.sizeBytes,
    required this.addedAt,
    this.repoId,
  });

  String get sizeFormatted {
    if (sizeBytes >= 1024 * 1024 * 1024) {
      return '${(sizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    } else if (sizeBytes >= 1024 * 1024) {
      return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    }
  }
}

/// Tracks an active download
class DownloadTask {
  final String modelId;
  final String url;
  final String destinationPath;
  final RxDouble progress;
  final RxBool isDownloading;
  final RxString statusText;
  CancelToken? cancelToken;

  DownloadTask({
    required this.modelId,
    required this.url,
    required this.destinationPath,
  })  : progress = 0.0.obs,
        isDownloading = true.obs,
        statusText = 'Starting...'.obs;
}

class ModelManager extends GetxService {
  final Dio _dio = Dio();
  final RxList<LocalModel> downloadedModels = <LocalModel>[].obs;
  final RxMap<String, DownloadTask> activeDownloads = <String, DownloadTask>{}.obs;
  final isScanning = false.obs;

  /// Get the directory where models are stored
  Future<Directory> getModelsDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final modelsDir = Directory('${appDir.path}/models');
    if (!await modelsDir.exists()) {
      await modelsDir.create(recursive: true);
    }
    return modelsDir;
  }

  /// Scan the models directory for .gguf files and populate the list
  Future<void> scanForModels() async {
    isScanning.value = true;
    try {
      final modelsDir = await getModelsDirectory();
      final files = await modelsDir
          .list()
          .where((entity) =>
              entity is File && entity.path.toLowerCase().endsWith('.gguf'))
          .toList();

      final models = <LocalModel>[];
      for (final entity in files) {
        final file = entity as File;
        final stat = await file.stat();
        final fileName = file.path.split('/').last;
        models.add(LocalModel(
          id: fileName.hashCode.toString(),
          name: fileName.replaceAll('.gguf', ''),
          filePath: file.path,
          sizeBytes: stat.size,
          addedAt: stat.modified,
        ));
      }

      models.sort((a, b) => b.addedAt.compareTo(a.addedAt));
      downloadedModels.value = models;
    } finally {
      isScanning.value = false;
    }
  }

  /// Download a model from a URL (e.g., HuggingFace)
  Future<void> downloadModel({
    required String modelId,
    required String url,
    required String filename,
  }) async {
    final modelsDir = await getModelsDirectory();
    final destPath = '${modelsDir.path}/$filename';

    // Check if already downloaded
    if (await File(destPath).exists()) {
      await scanForModels();
      return;
    }

    // Create download task
    final task = DownloadTask(
      modelId: modelId,
      url: url,
      destinationPath: destPath,
    );
    task.cancelToken = CancelToken();
    activeDownloads[modelId] = task;

    try {
      task.statusText.value = 'Downloading...';

      await _dio.download(
        url,
        destPath,
        cancelToken: task.cancelToken,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            task.progress.value = received / total;
            final receivedMB = (received / (1024 * 1024)).toStringAsFixed(1);
            final totalMB = (total / (1024 * 1024)).toStringAsFixed(1);
            task.statusText.value = '$receivedMB / $totalMB MB';
          }
        },
      );

      task.progress.value = 1.0;
      task.isDownloading.value = false;
      task.statusText.value = 'Complete';

      // Remove from active downloads
      activeDownloads.remove(modelId);

      // Rescan to pick up the new file
      await scanForModels();
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        // Download was cancelled, clean up partial file
        final file = File(destPath);
        if (await file.exists()) await file.delete();
        task.statusText.value = 'Cancelled';
      } else {
        task.statusText.value = 'Error: ${e.message}';
      }
      task.isDownloading.value = false;
      activeDownloads.remove(modelId);
    }
  }

  /// Cancel an active download
  void cancelDownload(String modelId) {
    final task = activeDownloads[modelId];
    if (task != null) {
      task.cancelToken?.cancel('User cancelled');
      activeDownloads.remove(modelId);
    }
  }

  /// Check if a model is currently downloading
  bool isDownloading(String modelId) {
    return activeDownloads.containsKey(modelId);
  }

  /// Get download progress for a model
  double getDownloadProgress(String modelId) {
    return activeDownloads[modelId]?.progress.value ?? 0.0;
  }

  /// Check if a model file already exists locally
  Future<bool> isModelDownloaded(String filename) async {
    final modelsDir = await getModelsDirectory();
    return File('${modelsDir.path}/$filename').exists();
  }

  /// Delete a model from the models directory
  Future<void> deleteModel(String modelId) async {
    final model = downloadedModels.firstWhereOrNull((m) => m.id == modelId);
    if (model != null) {
      final file = File(model.filePath);
      if (await file.exists()) {
        await file.delete();
      }
      await scanForModels();
    }
  }

  /// Get total storage used by models
  int get totalStorageUsed {
    return downloadedModels.fold(0, (sum, m) => sum + m.sizeBytes);
  }

  String get totalStorageUsedFormatted {
    final bytes = totalStorageUsed;
    if (bytes >= 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    } else if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
  }

  @override
  void onInit() {
    super.onInit();
    scanForModels();
  }
}

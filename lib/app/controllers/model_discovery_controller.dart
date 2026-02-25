import '../../core/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../data/models/ai_model.dart';
import '../services/huggingface_service.dart';
import '../services/model_manager.dart';
import '../../core/theme/app_theme.dart';

class ModelDiscoveryController extends GetxController {
  final HuggingFaceService _hfService = Get.find<HuggingFaceService>();
  final ModelManager _modelManager = Get.find<ModelManager>();

  final RxString searchQuery = ''.obs;
  final RxList<FilterCategory> filterCategories = <FilterCategory>[].obs;
  final RxList<HFModel> searchResults = <HFModel>[].obs;
  final Rx<HFModel?> featuredModel = Rx<HFModel?>(null);
  final RxBool isLoading = false.obs;
  final RxBool isSearching = false.obs;
  final RxString selectedCategory = 'all'.obs;

  // AIModel list for existing widget compatibility
  final RxList<AIModel> trendingModels = <AIModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    _loadFilterCategories();
    _loadTrendingModels();
  }

  void _loadFilterCategories() {
    filterCategories.value = [
      FilterCategory(id: 'all', name: 'All', isSelected: true),
      FilterCategory(id: 'text', name: 'Text Generation'),
      FilterCategory(id: 'coding', name: 'Coding'),
      FilterCategory(id: 'roleplay', name: 'Roleplay'),
      FilterCategory(
        id: 'phone_ready',
        name: 'Phone Ready',
        icon: Icons.bolt,
        iconColor: AppColors.success,
      ),
    ];
  }

  /// Load trending/popular models from HuggingFace
  Future<void> _loadTrendingModels() async {
    isLoading.value = true;
    try {
      final models = await _hfService.getTrendingModels(limit: 15);
      
      // The user specifically wants Gemma 3 1B. Since it's too new to be in the all-time top 15 trending,
      // let's fetch it explicitly and put it at the top of the dashboard.
      try {
        final gemma = await _hfService.getModelDetails('unsloth/gemma-3-1b-it-GGUF');
        if (gemma != null) {
          // Remove if it's already there to avoid duplicates
          models.removeWhere((m) => m.id == gemma.id);
          models.insert(0, gemma);
        }
      } catch (_) {} // Ignore if fetch fails for some reason

      searchResults.value = models;

      // Show results immediately, then enrich with sizes in background
      _syncToAIModels(models);

      // Fetch sizes for all models in parallel
      _enrichModelsInBackground(models);
    } finally {
      isLoading.value = false;
    }
  }

  /// Fetch details for all models in background to get sizes
  Future<void> _enrichModelsInBackground(List<HFModel> models) async {
    final enriched = await _hfService.enrichWithDetails(models);
    searchResults.value = enriched;
    _syncToAIModels(enriched);
  }

  /// Search HuggingFace for models
  Future<void> searchModels(String query) async {
    if (query.trim().isEmpty) {
      _loadTrendingModels();
      return;
    }

    isSearching.value = true;
    try {
      final results = await _hfService.searchModels(query: query, limit: 20);
      searchResults.value = results;
      featuredModel.value = null;

      // Show immediately
      _syncToAIModels(results);

      // Then enrich with sizes
      _enrichModelsInBackground(results);
    } finally {
      isSearching.value = false;
    }
  }

  void selectFilter(String filterId) {
    selectedCategory.value = filterId;
    filterCategories.value = filterCategories.map((category) {
      return category.copyWith(isSelected: category.id == filterId);
    }).toList();

    if (filterId == 'all') {
      _loadTrendingModels();
    } else {
      _searchByCategory(filterId);
    }
  }

  Future<void> _searchByCategory(String category) async {
    isLoading.value = true;
    try {
      final results = await _hfService.searchByCategory(category, limit: 20);
      searchResults.value = results;
      featuredModel.value = null;
      _syncToAIModels(results);
      _enrichModelsInBackground(results);
    } finally {
      isLoading.value = false;
    }
  }

  void updateSearchQuery(String query) {
    searchQuery.value = query;
    if (query.length >= 2 || query.isEmpty) {
      searchModels(query);
    }
  }

  /// Download a model — fetches details, finds the best GGUF file, downloads
  Future<void> downloadModel(String modelId) async {
    // Find the HFModel in search results
    final hfModel = searchResults.firstWhereOrNull((m) => m.id == modelId);
    if (hfModel == null) return;

    // Get detailed info using already-enriched data or fetch fresh
    HFModel? detail;
    if (hfModel.ggufFiles.isNotEmpty) {
      detail = hfModel;
    } else {
      detail = await _hfService.getModelDetails(modelId);
    }

    if (detail == null || detail.ggufFiles.isEmpty) {
      Get.snackbar(
        'No GGUF File',
        'This model doesn\'t have a downloadable GGUF model file.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
      return;
    }

    // Use the best file (picks ideal quantization, skips projectors)
    final ggufFile = detail.bestGgufFile ?? detail.ggufFiles.first;

    // Update UI to show downloading
    final idx = trendingModels.indexWhere((m) => m.id == modelId);
    if (idx != -1) {
      trendingModels[idx] = trendingModels[idx].copyWith(
        status: ModelStatus.downloading,
        downloadProgress: 0.0,
      );
    }

    // Start real download
    _modelManager.downloadModel(
      modelId: modelId,
      url: ggufFile.downloadUrl,
      filename: ggufFile.filename,
    );

    // Listen to progress and update the UI
    _trackDownloadProgress(modelId);
  }

  void _trackDownloadProgress(String modelId) async {
    while (_modelManager.isDownloading(modelId)) {
      await Future.delayed(const Duration(milliseconds: 300));
      final progress = _modelManager.getDownloadProgress(modelId);
      final idx = trendingModels.indexWhere((m) => m.id == modelId);
      if (idx != -1) {
        trendingModels[idx] = trendingModels[idx].copyWith(
          downloadProgress: progress,
          status: ModelStatus.downloading,
        );
      }
    }

    // Download complete
    final idx = trendingModels.indexWhere((m) => m.id == modelId);
    if (idx != -1) {
      trendingModels[idx] = trendingModels[idx].copyWith(
        status: ModelStatus.downloaded,
        downloadProgress: 1.0,
      );
    }
  }

  void cancelDownload(String modelId) {
    _modelManager.cancelDownload(modelId);
    final idx = trendingModels.indexWhere((m) => m.id == modelId);
    if (idx != -1) {
      trendingModels[idx] = trendingModels[idx].copyWith(
        status: ModelStatus.available,
        downloadProgress: 0.0,
      );
    }
  }

  /// Palette for model icons
  static const _modelColors = [
    AppColors.orange,
    AppColors.blue,
    AppColors.purple,
    AppColors.teal,
  ];

  static const _modelIcons = [
    Icons.auto_awesome,
    Icons.token,
    Icons.grid_view,
    Icons.diamond,
    Icons.code,
    Icons.psychology,
    Icons.smart_toy,
    Icons.memory,
  ];

  /// Convert HFModel list to AIModel list for widget compatibility
  void _syncToAIModels(List<HFModel> hfModels) {
    trendingModels.value = hfModels.asMap().entries.map((entry) {
      final i = entry.key;
      final hf = entry.value;
      final color = _modelColors[i % _modelColors.length];
      final icon = _modelIcons[i % _modelIcons.length];

      return AIModel(
        id: hf.id,
        name: hf.modelName,
        description: hf.author,
        version: hf.paramCount.isNotEmpty
            ? hf.paramCount
            : hf.architecture ?? '',
        size: hf.sizeFormatted,
        quantization: hf.quantization,
        status: ModelStatus.available,
        readiness: hf.isPhoneReady
            ? ModelReadiness.phoneReady
            : ModelReadiness.heavyMemory,
        iconBackgroundColor: color.withValues(alpha: 0.2),
        iconColor: color,
        icon: icon,
      );
    }).toList();
  }
}

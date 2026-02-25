import 'package:dio/dio.dart';
import 'package:get/get.dart';

/// Represents a GGUF model from HuggingFace
class HFModel {
  final String id;
  final String author;
  final String modelName;
  final int downloads;
  final int likes;
  final List<String> tags;
  final String? pipelineTag;
  final DateTime createdAt;
  final List<HFModelFile> ggufFiles;
  final int? totalSize;
  final String? architecture;
  final int? contextLength;

  HFModel({
    required this.id,
    required this.author,
    required this.modelName,
    required this.downloads,
    required this.likes,
    required this.tags,
    this.pipelineTag,
    required this.createdAt,
    this.ggufFiles = const [],
    this.totalSize,
    this.architecture,
    this.contextLength,
  });

  HFModel copyWith({
    String? id,
    String? author,
    String? modelName,
    int? downloads,
    int? likes,
    List<String>? tags,
    String? pipelineTag,
    DateTime? createdAt,
    List<HFModelFile>? ggufFiles,
    int? totalSize,
    String? architecture,
    int? contextLength,
  }) {
    return HFModel(
      id: id ?? this.id,
      author: author ?? this.author,
      modelName: modelName ?? this.modelName,
      downloads: downloads ?? this.downloads,
      likes: likes ?? this.likes,
      tags: tags ?? this.tags,
      pipelineTag: pipelineTag ?? this.pipelineTag,
      createdAt: createdAt ?? this.createdAt,
      ggufFiles: ggufFiles ?? this.ggufFiles,
      totalSize: totalSize ?? this.totalSize,
      architecture: architecture ?? this.architecture,
      contextLength: contextLength ?? this.contextLength,
    );
  }

  /// Parse from search API response
  factory HFModel.fromSearchJson(Map<String, dynamic> json) {
    final id = json['id'] as String;
    final parts = id.split('/');
    return HFModel(
      id: id,
      author: parts.isNotEmpty ? parts[0] : '',
      modelName: parts.length > 1 ? parts[1] : id,
      downloads: json['downloads'] as int? ?? 0,
      likes: json['likes'] as int? ?? 0,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      pipelineTag: json['pipeline_tag'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  /// Parse from model detail API response
  factory HFModel.fromDetailJson(Map<String, dynamic> json) {
    final id = json['id'] as String;
    final parts = id.split('/');

    // Filter out non-model GGUF files (projectors, tokenizers, etc.)
    final siblings = (json['siblings'] as List<dynamic>?)
            ?.where((s) {
              final fname = (s['rfilename'] as String).toLowerCase();
              if (!fname.endsWith('.gguf')) return false;
              // Skip multimodal projector files, tokenizer files, etc.
              if (fname.contains('mmproj')) return false;
              if (fname.contains('projector')) return false;
              if (fname.contains('tokenizer')) return false;
              if (fname.contains('vocab')) return false;
              return true;
            })
            .map((s) => HFModelFile(
                  filename: s['rfilename'] as String,
                  repoId: id,
                ))
            .toList() ??
        [];

    final ggufData = json['gguf'] as Map<String, dynamic>?;

    // Try to get size from usedStorage as fallback
    int? totalSize = ggufData?['total'] as int?;
    totalSize ??= json['usedStorage'] as int?;

    return HFModel(
      id: id,
      author: parts.isNotEmpty ? parts[0] : '',
      modelName: parts.length > 1 ? parts[1] : id,
      downloads: json['downloads'] as int? ?? 0,
      likes: json['likes'] as int? ?? 0,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      pipelineTag: json['pipeline_tag'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      ggufFiles: siblings,
      totalSize: totalSize,
      architecture: ggufData?['architecture'] as String?,
      contextLength: ggufData?['context_length'] as int?,
    );
  }

  String get sizeFormatted {
    if (totalSize != null) {
      final gb = totalSize! / (1024 * 1024 * 1024);
      if (gb >= 1) return '${gb.toStringAsFixed(1)} GB';
      final mb = totalSize! / (1024 * 1024);
      if (mb >= 1) return '${mb.toStringAsFixed(0)} MB';
      return '${(totalSize! / 1024).toStringAsFixed(0)} KB';
    }
    // Fallback: show downloads count instead
    return '${downloadsFormatted} ↓';
  }

  String get downloadsFormatted {
    if (downloads >= 1000000) {
      return '${(downloads / 1000000).toStringAsFixed(1)}M';
    }
    if (downloads >= 1000) return '${(downloads / 1000).toStringAsFixed(1)}K';
    return downloads.toString();
  }

  /// Guess quantization from model name or files
  String get quantization {
    final name = modelName.toUpperCase();
    final quants = [
      'Q2_K', 'Q3_K_S', 'Q3_K_M', 'Q3_K_L', 'Q4_0', 'Q4_K_S',
      'Q4_K_M', 'Q5_0', 'Q5_K_S', 'Q5_K_M', 'Q6_K', 'Q8_0', 'F16', 'F32',
    ];
    for (final q in quants) {
      if (name.contains(q)) return q;
    }
    if (ggufFiles.isNotEmpty) {
      for (final q in quants) {
        if (ggufFiles.first.filename.toUpperCase().contains(q)) return q;
      }
    }
    return 'GGUF';
  }

  /// Guess param count from name
  String get paramCount {
    final match = RegExp(r'(\d+\.?\d*)[Bb]').firstMatch(modelName);
    if (match != null) return '${match.group(1)}B';
    return '';
  }

  /// Check if this is likely phone-ready (small model)
  bool get isPhoneReady {
    if (totalSize != null) {
      return totalSize! <= 4 * 1024 * 1024 * 1024; // <=4GB
    }
    final p = paramCount;
    if (p.isNotEmpty) {
      final num = double.tryParse(p.replaceAll('B', ''));
      if (num != null) return num <= 7;
    }
    return false;
  }

  /// Get the best GGUF file to download (largest non-projector file)
  HFModelFile? get bestGgufFile {
    if (ggufFiles.isEmpty) return null;
    // If only one, return it
    if (ggufFiles.length == 1) return ggufFiles.first;
    // Prefer files with quantization in the name
    for (final file in ggufFiles) {
      final fname = file.filename.toUpperCase();
      if (fname.contains('Q4_K_M') || fname.contains('Q5_K_M') ||
          fname.contains('Q4_K_S') || fname.contains('Q8_0')) {
        return file;
      }
    }
    return ggufFiles.first;
  }
}

class HFModelFile {
  final String filename;
  final String repoId;

  HFModelFile({required this.filename, required this.repoId});

  String get downloadUrl =>
      'https://huggingface.co/$repoId/resolve/main/$filename';
}

class HuggingFaceService extends GetxService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://huggingface.co/api',
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
  ));

  /// Search for GGUF models, then fetch details in parallel to get sizes
  Future<List<HFModel>> searchModels({
    String query = '',
    int limit = 20,
    String sort = 'downloads',
  }) async {
    try {
      final response = await _dio.get('/models', queryParameters: {
        'search': query.isEmpty ? 'gguf' : '$query gguf',
        'filter': 'gguf',
        'sort': sort,
        'direction': '-1',
        'limit': limit,
      });

      if (response.data is List) {
        final searchResults = (response.data as List)
            .map((json) =>
                HFModel.fromSearchJson(json as Map<String, dynamic>))
            .toList();

        return searchResults;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Fetch details for a list of models in parallel (for sizes)
  Future<List<HFModel>> enrichWithDetails(List<HFModel> models) async {
    try {
      final futures = models.map((m) => getModelDetails(m.id));
      final details = await Future.wait(futures);

      return models.asMap().entries.map((entry) {
        final detail = details[entry.key];
        if (detail != null) {
          // Merge search result with detail data
          return entry.value.copyWith(
            totalSize: detail.totalSize,
            ggufFiles: detail.ggufFiles,
            architecture: detail.architecture,
            contextLength: detail.contextLength,
          );
        }
        return entry.value;
      }).toList();
    } catch (e) {
      return models;
    }
  }

  /// Get detailed model info including file list
  Future<HFModel?> getModelDetails(String modelId) async {
    try {
      final response = await _dio.get('/models/$modelId');
      if (response.data is Map<String, dynamic>) {
        return HFModel.fromDetailJson(response.data as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get trending/popular GGUF models
  Future<List<HFModel>> getTrendingModels({int limit = 10}) async {
    return searchModels(query: '', limit: limit, sort: 'downloads');
  }

  /// Search with category filter
  Future<List<HFModel>> searchByCategory(String category,
      {int limit = 20}) async {
    String query;
    switch (category) {
      case 'coding':
        query = 'coder OR code';
        break;
      case 'text':
        query = 'instruct';
        break;
      case 'roleplay':
        query = 'roleplay';
        break;
      case 'phone_ready':
        // HF search is finicky with multiple terms. We'll search for '1B' and sort by downloads. 
        // We'll also specifically add gemma 3 to make sure the newest mobile models appear.
        query = 'gemma 3 1b OR qwen 0.5b OR llama 1b';
        break;
      default:
        query = '';
    }
    return searchModels(query: query, limit: limit);
  }
}

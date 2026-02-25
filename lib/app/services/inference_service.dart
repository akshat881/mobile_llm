import 'dart:async';
import 'dart:io';
import 'package:get/get.dart';
import 'package:flutter_llama/flutter_llama.dart';
import '../data/models/chat_message.dart';

class InferenceService extends GetxService {
  final FlutterLlama _llama = FlutterLlama.instance;

  // Reactive state
  final isModelLoaded = false.obs;
  final isGenerating = false.obs;
  final currentModelName = ''.obs;
  final currentModelPath = ''.obs;
  final tokensPerSecond = 0.0.obs;
  final loadingStatus = ''.obs;

  bool _shouldCancel = false;

  /// Load a GGUF model from the given path
  Future<void> loadModel(String modelPath, {String? modelName}) async {
    await unloadModel();

    // Verify file exists
    final file = File(modelPath);
    if (!await file.exists()) {
      throw Exception('Model file not found at: $modelPath');
    }

    final fileSize = await file.length();
    final fileSizeMB = (fileSize / (1024 * 1024)).toStringAsFixed(1);
    loadingStatus.value = 'Loading model ($fileSizeMB MB)...';

    try {
      final config = LlamaConfig(
        modelPath: modelPath,
        nThreads: 4,     // 4 threads is a good sweet spot for mobile
        nGpuLayers: 0,   // CPU only 
        contextSize: 2048, // Must be large enough for context + generation
        batchSize: 2048,   // MUST be equal to contextSize because flutter_llama evaluates the whole prompt at once
        useGpu: false,
        verbose: true,
      );

      final success = await _llama.loadModel(config);
      if (!success) {
        final fileName = modelPath.split('/').last;
        throw Exception(
          'Failed to load "$fileName" ($fileSizeMB MB). '
          'Possible causes:\n'
          '• Model is too large for device RAM\n'
          '• File is not a valid GGUF model\n'
          '• Try a smaller model (under 1-2 GB)',
        );
      }

      currentModelPath.value = modelPath;
      currentModelName.value =
          modelName ?? modelPath.split('/').last.replaceAll('.gguf', '');
      isModelLoaded.value = true;
      loadingStatus.value = '';
    } catch (e) {
      loadingStatus.value = '';
      await unloadModel();
      rethrow;
    }
  }

  Future<void> unloadModel() async {
    _shouldCancel = true;

    try {
      await _llama.unloadModel();
    } catch (_) {}

    isModelLoaded.value = false;
    isGenerating.value = false;
    currentModelName.value = '';
    currentModelPath.value = '';
    tokensPerSecond.value = 0.0;
  }

  /// Build a chat prompt from messages
  String _buildChatPrompt(List<ChatMessage> messages) {
    final buffer = StringBuffer();
    // Using ChatML format which works best for Qwen and most modern instruct models
    buffer.writeln('<|im_start|>system\nYou are a helpful AI assistant. Be concise and clear.<|im_end|>');

    // Keep only the recent messages to avoid exceeding the 2048 token context
    final recentMessages = messages.length > 10 
        ? messages.sublist(messages.length - 10) 
        : messages;

    for (final msg in recentMessages) {
      switch (msg.role) {
        case MessageRole.system:
          // System prompt handled at the top
          break;
        case MessageRole.user:
          buffer.writeln('<|im_start|>user\n${msg.content.trim()}<|im_end|>');
          break;
        case MessageRole.assistant:
          buffer.writeln('<|im_start|>assistant\n${msg.content.trim()}<|im_end|>');
          break;
      }
    }

    buffer.write('<|im_start|>assistant\n');
    return buffer.toString();
  }

  /// Generate a response from chat messages
  /// Uses blocking generate() instead of streaming to avoid EventChannel issues
  Stream<String> chat(List<ChatMessage> messages) async* {
    if (!isModelLoaded.value) {
      throw Exception('No model loaded. Please load a model first.');
    }

    if (isGenerating.value) {
      throw Exception('Already generating a response.');
    }

    isGenerating.value = true;
    _shouldCancel = false;
    final stopwatch = Stopwatch()..start();

    try {
      final prompt = _buildChatPrompt(messages);
      final params = GenerationParams(
        prompt: prompt,
        temperature: 0.7,
        topP: 0.9,
        topK: 40,
        maxTokens: 512,
        repeatPenalty: 1.1,
      );

      // Use blocking generate — more reliable than streaming on Android
      final response = await _llama.generate(params);

      stopwatch.stop();
      if (response.tokensGenerated > 0 && stopwatch.elapsedMilliseconds > 0) {
        tokensPerSecond.value =
            response.tokensGenerated / (stopwatch.elapsedMilliseconds / 1000.0);
      }

      // Clean up the response to prevent hallucinated turns
      String text = response.text;
      
      // List of common stop tokens and hallucinated next-turns
      final stopMarkers = [
        '<|im_end|>', 
        '<|end_of_text|>', 
        '<|eot_id|>', 
        '<end_of_turn>',
        '\nUser:',
        '\nuser:',
        '<|im_start|>user',
        '\nHuman:',
      ];
      
      for (final marker in stopMarkers) {
        final index = text.indexOf(marker);
        if (index != -1) {
          text = text.substring(0, index);
        }
      }
      
      text = text.trim();

      // Simulate streaming by yielding word chunks for smooth UI
      if (text.isNotEmpty) {
        final words = text.split(' ');
        for (int i = 0; i < words.length; i++) {
          if (_shouldCancel) break;
          final word = i == 0 ? words[i] : ' ${words[i]}';
          yield word;
          // Small delay for visual streaming effect
          await Future.delayed(const Duration(milliseconds: 20));
        }
      }
    } finally {
      stopwatch.stop();
      isGenerating.value = false;
    }
  }

  /// Simple single-prompt generation
  Stream<String> generate(String prompt) async* {
    if (!isModelLoaded.value) {
      throw Exception('No model loaded. Please load a model first.');
    }

    isGenerating.value = true;
    _shouldCancel = false;
    final stopwatch = Stopwatch()..start();

    try {
      final params = GenerationParams(
        prompt: prompt,
        temperature: 0.7,
        topP: 0.9,
        topK: 40,
        maxTokens: 512,
        repeatPenalty: 1.1,
      );

      final response = await _llama.generate(params);

      stopwatch.stop();
      if (response.tokensGenerated > 0 && stopwatch.elapsedMilliseconds > 0) {
        tokensPerSecond.value =
            response.tokensGenerated / (stopwatch.elapsedMilliseconds / 1000.0);
      }

      final text = response.text.trim();
      if (text.isNotEmpty) {
        yield text;
      }
    } finally {
      stopwatch.stop();
      isGenerating.value = false;
    }
  }

  void stopGeneration() {
    _shouldCancel = true;
  }

  @override
  void onClose() {
    unloadModel();
    super.onClose();
  }
}

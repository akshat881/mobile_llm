import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../data/models/chat_message.dart';
import '../data/models/chat_session.dart';
import '../services/chat_history_service.dart';
import '../services/inference_service.dart';
import '../services/model_manager.dart';

class ChatController extends GetxController {
  final InferenceService _inferenceService = Get.find<InferenceService>();
  final ModelManager _modelManager = Get.find<ModelManager>();
  final ChatHistoryService _historyService = Get.find<ChatHistoryService>();

  final RxList<ChatMessage> messages = <ChatMessage>[].obs;
  final TextEditingController textController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  
  // Current active session
  final Rx<ChatSession?> currentSession = Rx<ChatSession?>(null);

  // Reactive state
  RxBool get isModelLoaded => _inferenceService.isModelLoaded;
  RxBool get isGenerating => _inferenceService.isGenerating;
  RxString get currentModelName => _inferenceService.currentModelName;
  RxDouble get tokensPerSecond => _inferenceService.tokensPerSecond;

  /// Load a specific chat session
  Future<void> loadSession(ChatSession session) async {
    currentSession.value = session;
    messages.value = await _historyService.getMessagesForSession(session.id);
    _scrollToBottom();
  }

  /// Start a new chat session
  void startNewChat() {
    currentSession.value = null;
    messages.clear();
  }

  /// Send a user message and generate a response
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    if (!_inferenceService.isModelLoaded.value) {
      Get.snackbar(
        'No Model Loaded',
        'Please load a model from My Models tab first.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      return;
    }

    // Create session if it doesn't exist
    if (currentSession.value == null) {
      // Use the first user message as the title, truncated
      String title = text.trim();
      if (title.length > 30) {
        title = '${title.substring(0, 30)}...';
      }
      currentSession.value = await _historyService.createSession(
        title, 
        modelId: currentModelName.value,
      );
    }

    // Add user message
    final userMessage = ChatMessage(
      content: text.trim(),
      role: MessageRole.user,
    );
    messages.add(userMessage);
    await _historyService.saveMessage(currentSession.value!.id, userMessage);
    
    textController.clear();
    _scrollToBottom();

    // Add an empty assistant message that will be streamed into
    final assistantMessage = ChatMessage(
      content: '',
      role: MessageRole.assistant,
      isStreaming: true,
    );
    messages.add(assistantMessage);
    _scrollToBottom();

    // Stream the response
    try {
      final buffer = StringBuffer();
      final stream = _inferenceService.chat(messages.toList());

      await for (final token in stream) {
        buffer.write(token);
        // Update the last message with accumulated content
        final idx = messages.length - 1;
        messages[idx] = messages[idx].copyWith(
          content: buffer.toString(),
        );
        _scrollToBottom();
      }

      // Mark as done streaming and save to DB
      final idx = messages.length - 1;
      final finalMessage = messages[idx].copyWith(
        isStreaming: false,
        tokenCount: buffer.toString().split(' ').length,
        tokensPerSecond: _inferenceService.tokensPerSecond.value,
      );
      messages[idx] = finalMessage;
      
      await _historyService.saveMessage(currentSession.value!.id, finalMessage);

    } catch (e) {
      // Update the assistant message with error
      final idx = messages.length - 1;
      messages[idx] = messages[idx].copyWith(
        content: 'Error: ${e.toString()}',
        isStreaming: false,
      );
    }
  }

  /// Stop the current generation
  void stopGeneration() {
    _inferenceService.stopGeneration();
  }

  /// Load a model by path
  Future<void> loadModel(String modelPath, {String? modelName}) async {
    try {
      await _inferenceService.loadModel(modelPath, modelName: modelName);
      Get.snackbar(
        'Model Loaded',
        '${_inferenceService.currentModelName.value} is ready.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withValues(alpha: 0.8),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(
        'Error Loading Model',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }

  /// Unload the current model
  Future<void> unloadModel() async {
    await _inferenceService.unloadModel();
  }

  /// Clear all messages
  void clearChat() {
    messages.clear();
  }

  /// Get the list of available local models
  RxList<LocalModel> get availableModels => _modelManager.downloadedModels;

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 50), () {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void onClose() {
    textController.dispose();
    scrollController.dispose();
    super.onClose();
  }
}

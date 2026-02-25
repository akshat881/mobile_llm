import 'package:uuid/uuid.dart';

enum MessageRole { user, assistant, system }

class ChatMessage {
  final String id;
  final String content;
  final MessageRole role;
  final DateTime timestamp;
  final bool isStreaming;
  final int? tokenCount;
  final double? tokensPerSecond;

  ChatMessage({
    String? id,
    required this.content,
    required this.role,
    DateTime? timestamp,
    this.isStreaming = false,
    this.tokenCount,
    this.tokensPerSecond,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();

  ChatMessage copyWith({
    String? id,
    String? content,
    MessageRole? role,
    DateTime? timestamp,
    bool? isStreaming,
    int? tokenCount,
    double? tokensPerSecond,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      role: role ?? this.role,
      timestamp: timestamp ?? this.timestamp,
      isStreaming: isStreaming ?? this.isStreaming,
      tokenCount: tokenCount ?? this.tokenCount,
      tokensPerSecond: tokensPerSecond ?? this.tokensPerSecond,
    );
  }
}

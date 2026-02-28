import 'package:uuid/uuid.dart';
import 'attachment.dart';

enum MessageRole { user, assistant, system }

class ChatMessage {
  final String id;
  final String content;
  final MessageRole role;
  final DateTime timestamp;
  final bool isStreaming;
  final int? tokenCount;
  final double? tokensPerSecond;
  final List<Attachment>? attachments;

  ChatMessage({
    String? id,
    required this.content,
    required this.role,
    DateTime? timestamp,
    this.isStreaming = false,
    this.tokenCount,
    this.tokensPerSecond,
    this.attachments,
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
    List<Attachment>? attachments,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      role: role ?? this.role,
      timestamp: timestamp ?? this.timestamp,
      isStreaming: isStreaming ?? this.isStreaming,
      tokenCount: tokenCount ?? this.tokenCount,
      tokensPerSecond: tokensPerSecond ?? this.tokensPerSecond,
      attachments: attachments ?? this.attachments,
    );
  }

  Map<String, dynamic> toMap(String sessionId) {
    return {
      'id': id,
      'sessionId': sessionId,
      'content': content,
      'role': role.name,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] as String,
      content: map['content'] as String,
      role: MessageRole.values.firstWhere(
        (e) => e.name == map['role'],
        orElse: () => MessageRole.user,
      ),
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }
}

import 'package:equatable/equatable.dart';

/// 消息角色
enum MessageRole {
  user,
  assistant,
  system,
}

/// 对话消息模型
class ConversationMessage extends Equatable {
  final String id;
  final String conversationId;
  final MessageRole role;
  final String content;
  final bool isStreaming; // 是否正在流式接收
  final bool isStarred; // 是否收藏
  final bool isDifficulty; // 是否标记为疑难
  final DateTime createdAt;

  const ConversationMessage({
    required this.id,
    required this.conversationId,
    required this.role,
    required this.content,
    this.isStreaming = false,
    this.isStarred = false,
    this.isDifficulty = false,
    required this.createdAt,
  });

  ConversationMessage copyWith({
    String? id,
    String? conversationId,
    MessageRole? role,
    String? content,
    bool? isStreaming,
    bool? isStarred,
    bool? isDifficulty,
    DateTime? createdAt,
  }) {
    return ConversationMessage(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      role: role ?? this.role,
      content: content ?? this.content,
      isStreaming: isStreaming ?? this.isStreaming,
      isStarred: isStarred ?? this.isStarred,
      isDifficulty: isDifficulty ?? this.isDifficulty,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        conversationId,
        role,
        content,
        isStreaming,
        isStarred,
        isDifficulty,
        createdAt,
      ];
}

/// 对话会话模型
class Conversation extends Equatable {
  final String id; // UUID
  final String bookId;
  final String? chapterId;
  final String? flowState; // 关联的精读流程状态
  final String title;
  final int messageCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Conversation({
    required this.id,
    required this.bookId,
    this.chapterId,
    this.flowState,
    this.title = '',
    this.messageCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  Conversation copyWith({
    String? id,
    String? bookId,
    String? chapterId,
    String? flowState,
    String? title,
    int? messageCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Conversation(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      chapterId: chapterId ?? this.chapterId,
      flowState: flowState ?? this.flowState,
      title: title ?? this.title,
      messageCount: messageCount ?? this.messageCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        bookId,
        chapterId,
        flowState,
        title,
        messageCount,
        createdAt,
        updatedAt,
      ];
}

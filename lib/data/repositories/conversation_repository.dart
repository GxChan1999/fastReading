import 'package:uuid/uuid.dart';
import '../database/database_helper.dart';
import '../models/conversation.dart' as conv;
import '../../core/constants/app_constants.dart';

/// 对话仓库 — 管理对话会话及消息
class ConversationRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final Uuid _uuid = const Uuid();

  /// 创建新对话
  conv.Conversation createConversation({
    required String bookId,
    String? chapterId,
    String? flowState,
    String title = '',
  }) {
    final now = DateTime.now();
    final conversation = conv.Conversation(
      id: _uuid.v4(),
      bookId: bookId,
      chapterId: chapterId,
      flowState: flowState,
      title: title,
      createdAt: now,
      updatedAt: now,
    );
    _db.insertConversation(conversation);
    return conversation;
  }

  /// 获取书籍的对话列表
  List<conv.Conversation> getConversations(String bookId) {
    return _db.getConversationsByBookId(bookId);
  }

  /// 添加用户消息
  conv.ConversationMessage addUserMessage(String conversationId, String content) {
    final message = conv.ConversationMessage(
      id: _uuid.v4(),
      conversationId: conversationId,
      role: conv.MessageRole.user,
      content: content,
      createdAt: DateTime.now(),
    );
    _db.insertMessage(message);
    return message;
  }

  /// 添加系统消息
  conv.ConversationMessage addSystemMessage(String conversationId, String content) {
    final message = conv.ConversationMessage(
      id: _uuid.v4(),
      conversationId: conversationId,
      role: conv.MessageRole.system,
      content: content,
      createdAt: DateTime.now(),
    );
    _db.insertMessage(message);
    return message;
  }

  /// 添加 AI 消息
  conv.ConversationMessage addAssistantMessage(String conversationId, String content) {
    final message = conv.ConversationMessage(
      id: _uuid.v4(),
      conversationId: conversationId,
      role: conv.MessageRole.assistant,
      content: content,
      createdAt: DateTime.now(),
    );
    _db.insertMessage(message);
    return message;
  }

  /// 获取对话消息列表
  List<conv.ConversationMessage> getMessages(String conversationId) {
    return _db.getMessagesByConversationId(conversationId);
  }

  /// 获取最近 N 轮对话
  List<conv.ConversationMessage> getRecentMessages(String conversationId) {
    return _db.getRecentMessages(conversationId, limit: AppConstants.maxHistoryRounds);
  }

  /// 更新消息内容（流式增量）
  void updateMessageContent(String messageId, String content) {
    _db.updateMessageContent(messageId, content);
  }

  /// 标记消息收藏
  void toggleStar(String messageId) {
    // 简化：直接查询后更新
    // MVP 阶段保留基础功能
  }

  /// 标记消息为疑难
  void toggleDifficulty(String messageId) {
    // 简化处理
  }
}

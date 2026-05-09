import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/conversation.dart' as conv;
import '../data/repositories/conversation_repository.dart';
import '../services/ai_engine/ai_engine.dart';
import '../services/ai_engine/ai_request_builder.dart';

/// 对话消息列表
final messageListProvider =
    StateNotifierProvider.family<MessageListNotifier, List<conv.ConversationMessage>, String>(
  (ref, conversationId) => MessageListNotifier(conversationId),
);

class MessageListNotifier extends StateNotifier<List<conv.ConversationMessage>> {
  final String conversationId;
  final ConversationRepository _repository = ConversationRepository();

  MessageListNotifier(this.conversationId) : super([]);

  /// 加载消息
  void loadMessages() {
    state = _repository.getMessages(conversationId);
  }

  /// 添加用户消息
  void addUserMessage(String content) {
    _repository.addUserMessage(conversationId, content);
    loadMessages();
  }

  /// 添加 AI 消息
  conv.ConversationMessage addAssistantMessage(String content) {
    final msg = _repository.addAssistantMessage(conversationId, content);
    loadMessages();
    return msg;
  }

  /// 更新消息内容（流式更新）
  void updateMessage(String messageId, String content) {
    _repository.updateMessageContent(messageId, content);
    state = state.map((m) {
      if (m.id == messageId) return m.copyWith(content: content);
      return m;
    }).toList();
  }
}

/// 对话会话列表
final conversationListProvider =
    FutureProvider.family<List<conv.Conversation>, String>((ref, bookId) {
  final repo = ConversationRepository();
  return repo.getConversations(bookId);
});

/// AI 引擎提供者
final aiEngineProvider = Provider<AIEngine>((ref) {
  return AIEngine.instance;
});

/// 发送消息（带 AI 响应的完整对话流程）
final sendChatMessageProvider = Provider.autoDispose<SendChatMessage>((ref) {
  return SendChatMessage(ref);
});

class SendChatMessage {
  final Ref _ref;
  SendChatMessage(this._ref);

  Future<void> call({
    required String conversationId,
    required String userMessage,
    required String systemPrompt,
    String? bookInfo,
    String? readingContent,
    String? chatHistory,
    String? currentProgress,
    String? feynmanContext,
    void Function(String chunk)? onChunk,
  }) async {
    final engine = _ref.read(aiEngineProvider);
    final messageNotifier = _ref.read(messageListProvider(conversationId).notifier);

    // 1. 添加用户消息
    messageNotifier.addUserMessage(userMessage);

    // 2. 构建请求
    final builder = AIRequestBuilder()
        .withSystemPrompt(systemPrompt)
        .withBookInfo(bookInfo ?? '')
        .withCurrentProgress(currentProgress ?? '')
        .withReadingContent(readingContent ?? '')
        .withChatHistory(chatHistory ?? '')
        .withFeynmanContext(feynmanContext ?? '')
        .withUserInstruction(userMessage);

    // 3. 创建空的 AI 消息占位
    final assistantMsg = messageNotifier.addAssistantMessage('');

    // 4. 发送流式请求
    var fullContent = '';
    await engine.sendChat(
      messages: builder.buildMessages(),
      onChunk: (chunk) {
        fullContent += chunk;
        messageNotifier.updateMessage(assistantMsg.id, fullContent);
      },
      onComplete: (content) {
        messageNotifier.updateMessage(assistantMsg.id, content);
      },
      onError: (error) {
        messageNotifier.updateMessage(assistantMsg.id, '错误：$error');
      },
    );
  }
}

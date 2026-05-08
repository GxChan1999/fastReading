import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/book_repository.dart';
import '../../../data/repositories/conversation_repository.dart';
import '../../../providers/chat_provider.dart';
import '../../../services/prompt_service.dart';
import 'widgets/message_bubble.dart';
import 'widgets/chat_input_bar.dart';

/// 对话页 — 全屏对话界面
class ChatPage extends ConsumerStatefulWidget {
  final String bookId;
  final String? chapterId;

  const ChatPage({
    super.key,
    required this.bookId,
    this.chapterId,
  });

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final ConversationRepository _conversationRepo = ConversationRepository();
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String? _currentConversationId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureConversation();
    });
  }

  void _ensureConversation() {
    final conversations = _conversationRepo.getConversations(widget.bookId);
    final existing = conversations.where((c) => c.chapterId == widget.chapterId).toList();
    if (existing.isNotEmpty) {
      _currentConversationId = existing.first.id;
    } else {
      final conv = _conversationRepo.createConversation(
        bookId: widget.bookId,
        chapterId: widget.chapterId,
        title: '阅读对话',
      );
      _currentConversationId = conv.id;
    }
    if (_currentConversationId != null) {
      ref.read(messageListProvider(_currentConversationId!).notifier).loadMessages();
    }
  }

  Future<void> _sendMessage(String text) async {
    if (_currentConversationId == null) return;
    setState(() => _isLoading = true);

    final systemPrompt = PromptService.instance.getCurrentPromptContent() ?? '';
    final bookRepo = BookRepository();
    final book = bookRepo.getBookById(widget.bookId);
    final bookInfo = '《${book?.name ?? ""}》 ${book?.author ?? ""}';

    await ref.read(sendChatMessageProvider).call(
      conversationId: _currentConversationId!,
      userMessage: text,
      systemPrompt: systemPrompt,
      bookInfo: bookInfo,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentConversationId == null) {
      return Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(title: const Text('对话')),
        body: const Center(child: Text('初始化对话失败')),
      );
    }

    final messages = ref.watch(messageListProvider(_currentConversationId!));

    return Scaffold(
      appBar: AppBar(
        title: const Text('对话'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: '清空对话',
            onPressed: () {
              // TODO: 清空当前对话
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey[300]),
                        const SizedBox(height: 12),
                        Text(
                          '开始与 AI 讨论阅读内容',
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      return MessageBubble(message: messages[index]);
                    },
                  ),
          ),
          ChatInputBar(
            controller: _inputController,
            onSend: _sendMessage,
            isLoading: _isLoading,
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../providers/chat_provider.dart';
import '../../../../providers/session_provider.dart';
import '../../chat/widgets/chat_input_bar.dart';
import '../../chat/widgets/message_bubble.dart';
import '../../session_archive/session_edit_page.dart';

/// 独立聊天面板 — ConsumerWidget 隔离重建范围
class ChatPanel extends ConsumerWidget {
  final String bookId;
  final String? conversationId;
  final String? chapterTitle;
  final String selectedText;
  final TextEditingController inputController;
  final VoidCallback onClearSelectedText;
  final ValueChanged<String> onSend;
  final VoidCallback onArchive;
  final VoidCallback onClearContext;
  final VoidCallback? onClose;
  final bool isEmbedded;

  const ChatPanel({
    super.key,
    required this.bookId,
    this.conversationId,
    this.chapterTitle,
    required this.selectedText,
    required this.inputController,
    required this.onClearSelectedText,
    required this.onSend,
    required this.onArchive,
    required this.onClearContext,
    this.onClose,
    this.isEmbedded = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(
          '对话 · ${chapterTitle ?? "全书"}',
          style: const TextStyle(fontSize: 14),
        ),
        automaticallyImplyLeading: false,
        leading: isEmbedded
            ? null
            : (onClose != null
                ? IconButton(icon: const Icon(Icons.close), onPressed: onClose)
                : null),
        actions: [
          IconButton(
            icon: const Icon(Icons.archive_outlined, size: 18),
            tooltip: '归档本轮对话',
            onPressed: onArchive,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18),
            tooltip: '清空上下文',
            onPressed: onClearContext,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: conversationId == null
                ? const Center(
                    child: Text(
                      '选择章节后开始对话',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  )
                : _MessageList(conversationId: conversationId!),
          ),
          if (selectedText.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(8),
              color: AppTheme.accentColor.withOpacity(0.1),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      selectedText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: onClearSelectedText,
                  ),
                ],
              ),
            ),
          ChatInputBar(
            controller: inputController,
            hintText: '输入提问...',
            onSend: onSend,
          ),
        ],
      ),
    );
  }
}

/// 消息列表 — 仅监听自己的 Provider
class _MessageList extends ConsumerWidget {
  final String conversationId;
  const _MessageList({required this.conversationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messages = ref.watch(messageListProvider(conversationId));

    if (messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline, size: 48, color: AppTheme.textHint),
            const SizedBox(height: 12),
            const Text(
              '选中文本或输入问题开始对话',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: messages.length,
      itemBuilder: (context, index) =>
          MessageBubble(message: messages[index]),
    );
  }
}

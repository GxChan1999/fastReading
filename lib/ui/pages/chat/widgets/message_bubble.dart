import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/conversation.dart' as conv;

/// 消息气泡组件 — 支持 Markdown 渲染
class MessageBubble extends StatelessWidget {
  final conv.ConversationMessage message;

  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    // 系统消息渲染为居中轻量标签
    if (message.role == conv.MessageRole.system) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.elevatedColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.goldBorder, width: 0.5),
            ),
            child: Text(
              message.content,
              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
            ),
          ),
        ),
      );
    }

    final isUser = message.role == conv.MessageRole.user;
    final isStreaming = message.isStreaming;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) _buildAvatar(context),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isUser ? AppTheme.primaryColor : AppTheme.cardColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(12),
                  topRight: const Radius.circular(12),
                  bottomLeft: Radius.circular(isUser ? 12 : 2),
                  bottomRight: Radius.circular(isUser ? 2 : 12),
                ),
                border: isUser
                    ? null
                    : Border.all(color: AppTheme.goldBorder, width: 0.5),
              ),
              child: isUser
                  ? _buildUserContent(isStreaming)
                  : _buildAssistantContent(isStreaming),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
          if (isUser) _buildAvatar(context),
        ],
      ),
    );
  }

  Widget _buildUserContent(bool isStreaming) {
    return Text(
      message.content + (isStreaming ? '▋' : ''),
      style: TextStyle(
        fontSize: 15,
        color: AppTheme.backgroundColor,
        height: 1.5,
      ),
    );
  }

  Widget _buildAssistantContent(bool isStreaming) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        MarkdownBody(
          data: message.content + (isStreaming ? '▋' : ''),
          selectable: true,
          styleSheet: MarkdownStyleSheet(
            p: const TextStyle(
              fontSize: 15,
              color: AppTheme.textPrimary,
              height: 1.6,
            ),
            h1: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
              height: 1.4,
            ),
            h2: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryLight,
              height: 1.4,
            ),
            h3: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
              height: 1.4,
            ),
            strong: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryLight,
            ),
            code: TextStyle(
              fontSize: 13,
              fontFamily: 'monospace',
              backgroundColor: AppTheme.backgroundColor,
              color: AppTheme.primaryLight,
            ),
            codeblockDecoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.dividerColor),
            ),
            blockquoteDecoration: BoxDecoration(
              border: const Border(
                left: BorderSide(color: AppTheme.primaryColor, width: 2),
              ),
              color: AppTheme.backgroundColor.withOpacity(0.5),
            ),
            blockquotePadding: const EdgeInsets.only(left: 12, top: 4, bottom: 4),
            listBullet: const TextStyle(color: AppTheme.primaryColor),
            horizontalRuleDecoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: AppTheme.dividerColor, width: 0.5),
              ),
            ),
            tableBorder: TableBorder.all(color: AppTheme.dividerColor, width: 0.5),
            tableHead: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
            tableBody: const TextStyle(color: AppTheme.textPrimary),
          ),
        ),
        if (message.isStarred || message.isDifficulty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (message.isStarred)
                  const Icon(Icons.star, size: 14,
                      color: AppTheme.accentColor),
                if (message.isDifficulty)
                  const Icon(Icons.help_outline, size: 14,
                      color: AppTheme.warningColor),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildAvatar(BuildContext context) {
    final isUser = message.role == conv.MessageRole.user;
    return CircleAvatar(
      radius: 14,
      backgroundColor:
          isUser ? AppTheme.primaryColor : AppTheme.primaryDark,
      child: Icon(
        isUser ? Icons.person : Icons.auto_awesome,
        size: 16,
        color: AppTheme.backgroundColor,
      ),
    );
  }
}

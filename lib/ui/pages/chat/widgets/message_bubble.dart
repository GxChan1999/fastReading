import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/conversation.dart' as conv;

/// 消息气泡组件
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
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              message.content,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
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
                color: isUser ? AppTheme.primaryColor : Colors.grey[100],
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content + (isStreaming ? '▋' : ''),
                    style: TextStyle(
                      fontSize: 15,
                      color: isUser ? Colors.white : AppTheme.textPrimary,
                      height: 1.5,
                    ),
                  ),
                  if (message.isStarred || message.isDifficulty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (message.isStarred)
                            const Icon(Icons.star, size: 14, color: AppTheme.accentColor),
                          if (message.isDifficulty)
                            const Icon(Icons.help_outline, size: 14, color: AppTheme.warningColor),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
          if (isUser) _buildAvatar(context),
        ],
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    final isUser = message.role == conv.MessageRole.user;
    return CircleAvatar(
      radius: 14,
      backgroundColor: isUser ? AppTheme.primaryColor : AppTheme.successColor,
      child: Icon(
        isUser ? Icons.person : Icons.auto_awesome,
        size: 16,
        color: Colors.white,
      ),
    );
  }
}

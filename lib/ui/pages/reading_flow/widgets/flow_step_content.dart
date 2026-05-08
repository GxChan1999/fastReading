import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/reading_flow_service.dart';

/// 流程步骤内容组件
class FlowStepContent extends StatelessWidget {
  final ReadingFlowState state;
  final String aiResponse;
  final bool isLoading;
  final VoidCallback onStartAction;

  const FlowStepContent({
    super.key,
    required this.state,
    this.aiResponse = '',
    this.isLoading = false,
    required this.onStartAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 步骤标题
          Row(
            children: [
              Icon(_getStepIcon(), size: 24, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Text(
                state.label,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            state.description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),

          // AI 响应区
          Expanded(
            child: isLoading
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 12),
                        Text('AI 思考中...'),
                      ],
                    ),
                  )
                : aiResponse.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_getStepIcon(), size: 48, color: Colors.grey[200]),
                            const SizedBox(height: 12),
                            Text(
                              '点击下方按钮开始${state.label}',
                              style: TextStyle(color: Colors.grey[400]),
                            ),
                          ],
                        ),
                      )
                    : Markdown(
                        data: aiResponse,
                        selectable: true,
                        styleSheet: MarkdownStyleSheet(
                          p: const TextStyle(fontSize: 16, height: 1.8),
                        ),
                      ),
          ),

          // 操作按钮
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isLoading ? null : onStartAction,
                  icon: Icon(aiResponse.isEmpty ? Icons.play_arrow : Icons.refresh),
                  label: Text(aiResponse.isEmpty ? '开始${state.label}' : '重新生成'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStepIcon() {
    switch (state) {
      case ReadingFlowState.framework:
        return Icons.account_tree;
      case ReadingFlowState.preliminaryQuiz:
        return Icons.quiz;
      case ReadingFlowState.chapterIntensive:
        return Icons.menu_book;
      case ReadingFlowState.chapterDiscussion:
        return Icons.forum;
      case ReadingFlowState.correction:
        return Icons.tune;
      case ReadingFlowState.gapMining:
        return Icons.explore;
      case ReadingFlowState.archive:
        return Icons.archive;
    }
  }
}

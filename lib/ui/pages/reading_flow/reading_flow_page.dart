import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/flow_provider.dart';
import '../../../services/reading_flow_service.dart';
import 'widgets/flow_step_indicator.dart';
import 'widgets/flow_step_content.dart';

/// 精读流程主控页
class ReadingFlowPage extends ConsumerWidget {
  final String bookId;

  const ReadingFlowPage({super.key, required this.bookId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flowState = ref.watch(readingFlowProvider(bookId));
    final flowNotifier = ref.read(readingFlowProvider(bookId).notifier);
    final allStates = flowNotifier.getAllStates();
    final progress = flowNotifier.getProgress();

    return Scaffold(
      appBar: AppBar(
        title: const Text('精读流程'),
        actions: [
          // 重置按钮
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '重置流程',
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('重置流程'),
                  content: const Text('确定要重置精读流程吗？所有进度将丢失。'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('取消'),
                    ),
                    TextButton(
                      onPressed: () {
                        flowNotifier.reset();
                        Navigator.pop(ctx);
                      },
                      style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
                      child: const Text('重置'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 进度条
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '整体进度',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                    Text(
                      '${(progress * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                  ),
                ),
              ],
            ),
          ),
          // 步骤指示器
          FlowStepIndicator(steps: allStates, currentStep: flowState),
          const Divider(height: 1),
          // 步骤内容
          Expanded(
            child: FlowStepContent(
              state: flowState,
              onStartAction: () {
                // TODO: 触发 AI 请求
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('开始${flowState.label}（AI 请求待集成）')),
                );
              },
            ),
          ),
          // 导航按钮
          _buildNavigationBar(context, flowNotifier, flowState),
        ],
      ),
    );
  }

  Widget _buildNavigationBar(
      BuildContext context, ReadingFlowNotifier notifier, ReadingFlowState current) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        children: [
          // 上一步
          if (current != ReadingFlowState.framework)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => notifier.retreat(),
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('上一步'),
              ),
            ),
          if (current != ReadingFlowState.framework) const SizedBox(width: 12),
          // 下一步
          if (current != ReadingFlowState.archive)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => notifier.advance(),
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: const Text('下一步'),
              ),
            ),
        ],
      ),
    );
  }
}

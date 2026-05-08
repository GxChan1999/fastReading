import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/reading_flow_service.dart';

/// 精读流程状态提供者
final readingFlowProvider =
    StateNotifierProvider.family<ReadingFlowNotifier, ReadingFlowState, String>((ref, bookId) {
  return ReadingFlowNotifier(bookId);
});

class ReadingFlowNotifier extends StateNotifier<ReadingFlowState> {
  final String bookId;
  final ReadingFlowService _service = ReadingFlowService();

  ReadingFlowNotifier(this.bookId) : super(ReadingFlowState.framework) {
    _loadState();
  }

  void _loadState() {
    state = _service.getCurrentState(bookId);
  }

  /// 推进到下一阶段
  void advance() {
    state = _service.advanceFlow(bookId);
  }

  /// 回退到上一阶段
  void retreat() {
    state = _service.retreatFlow(bookId);
  }

  /// 跳转到指定阶段
  void jumpTo(ReadingFlowState target) {
    state = _service.jumpToState(bookId, target);
  }

  /// 重置流程
  void reset() {
    state = _service.resetFlow(bookId);
  }

  /// 获取当前阶段自动 Prompt
  String getCurrentPrompt() => _service.getCurrentPrompt(bookId);

  /// 获取流程进度
  double getProgress() => _service.getFlowProgress(bookId);

  /// 获取所有阶段
  List<ReadingFlowState> getAllStates() => _service.getAllStates();
}

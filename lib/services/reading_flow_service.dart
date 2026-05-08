import '../../core/constants/app_constants.dart';
import '../data/database/database_helper.dart';
import '../data/models/book.dart';
import '../data/models/reading_snapshot.dart';
import '../data/repositories/book_repository.dart';
import 'file_system_service.dart';

/// 精读流程状态定义
enum ReadingFlowState {
  framework('framework', '全书框架梳理', '了解全书结构和核心论点'),
  preliminaryQuiz('preliminary_quiz', '摸底提问', '检验已有知识储备'),
  chapterIntensive('chapter_intensive', '分章精读', '逐章深入阅读'),
  chapterDiscussion('chapter_discussion', '章节讨论', '与 AI 讨论章节内容'),
  correction('correction', '理解纠偏', '纠正理解偏差'),
  gapMining('gap_mining', '缺漏挖掘', '发现知识盲区'),
  archive('archive', '沉淀归档', '整理阅读成果');

  final String key;
  final String label;
  final String description;
  const ReadingFlowState(this.key, this.label, this.description);

  static ReadingFlowState fromKey(String key) {
    return ReadingFlowState.values.firstWhere(
      (s) => s.key == key,
      orElse: () => ReadingFlowState.framework,
    );
  }

  ReadingFlowState get next {
    final nextIndex = this.index + 1;
    if (nextIndex >= ReadingFlowState.values.length) return this;
    return ReadingFlowState.values[nextIndex];
  }

  ReadingFlowState get previous {
    final prevIndex = this.index - 1;
    if (prevIndex < 0) return this;
    return ReadingFlowState.values[prevIndex];
  }
}

/// 精读流程服务 — 状态机管理核心阅读流程
class ReadingFlowService {
  static final ReadingFlowService _instance = ReadingFlowService._();
  factory ReadingFlowService() => _instance;
  ReadingFlowService._();

  final DatabaseHelper _db = DatabaseHelper.instance;
  final BookRepository _bookRepo = BookRepository();
  final FileSystemService _fileSystem = FileSystemService();

  // 各状态对应的自动 Prompt 触发模板
  static const Map<ReadingFlowState, String> _flowPrompts = {
    ReadingFlowState.framework: '''
请对这本书进行全书框架梳理，包括：
1. 核心主题与作者意图
2. 全书结构总览（几个部分、逻辑关系）
3. 各章节核心观点摘要
4. 本书适合谁读、解决什么问题
请以清晰的结构化方式呈现。
''',
    ReadingFlowState.preliminaryQuiz: '''
基于本书内容，对我进行摸底提问：
1. 提出 5-8 个核心问题，检验我对本书主题的了解程度
2. 问题应覆盖基础概念和核心观点
3. 在我回答后，给出反馈和补充
4. 根据我的回答水平，调整后续精读重点
''',
    ReadingFlowState.chapterDiscussion: '''
基于当前章节内容，与我深入讨论：
1. 解析本章核心观点和论证逻辑
2. 指出章节中的关键概念和术语
3. 结合实际场景说明章节内容的适用性
4. 提出 2-3 个思考题检验理解
''',
    ReadingFlowState.correction: '''
根据之前的讨论和我的回答，检查我的理解是否有偏差：
1. 指出理解不准确的地方，引用原文依据
2. 澄清容易混淆的概念
3. 补充我遗漏的重要信息
4. 确保我的理解方向正确
''',
    ReadingFlowState.gapMining: '''
基于已完成的内容，找出我的知识盲区：
1. 识别本书中我可能忽略的重要概念
2. 提出深度追问，挖掘理解深度
3. 跨章节联系，检验知识贯通度
4. 给出针对性补充阅读建议
''',
    ReadingFlowState.archive: '''
对全书精读进行总结归档：
1. 全书核心知识体系总结
2. 我的问答精华整理
3. 尚未解决的疑难问题汇总
4. 后续复习和实践建议
以 Markdown 格式输出，便于存档。
''',
  };

  /// 获取当前流程状态
  ReadingFlowState getCurrentState(String bookId) {
    final book = _bookRepo.getBookById(bookId);
    if (book?.currentFlowState == null) return ReadingFlowState.framework;
    return ReadingFlowState.fromKey(book!.currentFlowState!);
  }

  /// 推进到下一状态
  ReadingFlowState advanceFlow(String bookId) {
    final current = getCurrentState(bookId);
    final next = current.next;
    _updateFlowState(bookId, next);
    return next;
  }

  /// 回退到上一状态
  ReadingFlowState retreatFlow(String bookId) {
    final current = getCurrentState(bookId);
    final previous = current.previous;
    _updateFlowState(bookId, previous);
    return previous;
  }

  /// 跳转到指定状态
  ReadingFlowState jumpToState(String bookId, ReadingFlowState target) {
    _updateFlowState(bookId, target);
    return target;
  }

  /// 重置流程
  ReadingFlowState resetFlow(String bookId) {
    _updateFlowState(bookId, ReadingFlowState.framework);
    return ReadingFlowState.framework;
  }

  /// 获取当前状态的自动 Prompt
  String getCurrentPrompt(String bookId) {
    final state = getCurrentState(bookId);
    return _flowPrompts[state] ?? '';
  }

  /// 获取指定状态的自动 Prompt
  String getPromptForState(ReadingFlowState state) {
    return _flowPrompts[state] ?? '';
  }

  /// 获取所有流程状态
  List<ReadingFlowState> getAllStates() => ReadingFlowState.values.toList();

  /// 获取流程总进度 (0.0 ~ 1.0)
  double getFlowProgress(String bookId) {
    final current = getCurrentState(bookId);
    return (current.index + 1) / ReadingFlowState.values.length;
  }

  /// 创建阅读快照
  Future<void> createSnapshot(String bookId, {
    String? chapterId,
    double scrollPosition = 0.0,
    String? conversationContext,
  }) async {
    final now = DateTime.now();
    final book = _bookRepo.getBookById(bookId);
    if (book == null) return;

    final snapshot = ReadingSnapshot(
      id: 'snapshot_${now.millisecondsSinceEpoch}',
      bookId: bookId,
      chapterId: chapterId,
      scrollPosition: scrollPosition,
      currentFlowState: book.currentFlowState,
      conversationContext: conversationContext,
      createdAt: now,
    );

    _db.insertSnapshot(snapshot);

    // 同时保存快照到文件系统
    final snapshotDir = _getSnapshotDir(bookId);
    await _fileSystem.exportFile(
      '', // TODO: 序列化快照内容
      '${snapshot.id}.json',
    );
  }

  /// 获取历史快照列表
  List<ReadingSnapshot> getSnapshots(String bookId) {
    return _db.getSnapshotsByBookId(bookId);
  }

  /// 获取最新快照
  ReadingSnapshot? getLatestSnapshot(String bookId) {
    return _db.getLatestSnapshot(bookId);
  }

  /// 更新书籍流程状态
  void _updateFlowState(String bookId, ReadingFlowState state) {
    final book = _bookRepo.getBookById(bookId);
    if (book == null) return;

    final updated = book.copyWith(
      currentFlowState: state.key,
      updatedAt: DateTime.now(),
    );
    _bookRepo.updateBook(updated);
  }

  String _getSnapshotDir(String bookId) {
    return AppConstants.getSnapshotsDir(bookId);
  }
}

import 'package:equatable/equatable.dart';

/// 阅读快照模型 — 用于断点续读
class ReadingSnapshot extends Equatable {
  final String id; // UUID
  final String bookId;
  final String? chapterId;
  final int pageIndex;
  final double scrollPosition;
  final String? currentFlowState;
  final String? conversationContext; // 对话上下文摘要（JSON）
  final String? notes;
  final DateTime createdAt;

  const ReadingSnapshot({
    required this.id,
    required this.bookId,
    this.chapterId,
    this.pageIndex = 0,
    this.scrollPosition = 0.0,
    this.currentFlowState,
    this.conversationContext,
    this.notes,
    required this.createdAt,
  });

  ReadingSnapshot copyWith({
    String? id,
    String? bookId,
    String? chapterId,
    int? pageIndex,
    double? scrollPosition,
    String? currentFlowState,
    String? conversationContext,
    String? notes,
    DateTime? createdAt,
  }) {
    return ReadingSnapshot(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      chapterId: chapterId ?? this.chapterId,
      pageIndex: pageIndex ?? this.pageIndex,
      scrollPosition: scrollPosition ?? this.scrollPosition,
      currentFlowState: currentFlowState ?? this.currentFlowState,
      conversationContext: conversationContext ?? this.conversationContext,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        bookId,
        chapterId,
        pageIndex,
        scrollPosition,
        currentFlowState,
        conversationContext,
        notes,
        createdAt,
      ];
}

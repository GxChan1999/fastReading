import 'package:equatable/equatable.dart';

/// 费曼归档 —— 单次阅读会话的完整记录
/// 对标费曼学习提效工具的「单次阅读归档区」格式
class ReadingSession extends Equatable {
  final String id;
  final String bookId;
  final String? chapterId;
  final String chapterTitle;
  final String? pageRange;
  final String? contentSummary;         // 当次阅读核心内容概述
  final String? discussionConclusions;  // 本次讨论核心结论
  final String? feynmanOutput;          // 用户费曼输出核心内容
  final String? blindSpots;             // 排查出的知识盲区
  final String? actionItems;            // 后续行动项
  final DateTime createdAt;
  final DateTime updatedAt;

  const ReadingSession({
    required this.id,
    required this.bookId,
    this.chapterId,
    this.chapterTitle = '',
    this.pageRange,
    this.contentSummary,
    this.discussionConclusions,
    this.feynmanOutput,
    this.blindSpots,
    this.actionItems,
    required this.createdAt,
    required this.updatedAt,
  });

  ReadingSession copyWith({
    String? id,
    String? bookId,
    String? chapterId,
    String? chapterTitle,
    String? pageRange,
    String? contentSummary,
    String? discussionConclusions,
    String? feynmanOutput,
    String? blindSpots,
    String? actionItems,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReadingSession(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      chapterId: chapterId ?? this.chapterId,
      chapterTitle: chapterTitle ?? this.chapterTitle,
      pageRange: pageRange ?? this.pageRange,
      contentSummary: contentSummary ?? this.contentSummary,
      discussionConclusions: discussionConclusions ?? this.discussionConclusions,
      feynmanOutput: feynmanOutput ?? this.feynmanOutput,
      blindSpots: blindSpots ?? this.blindSpots,
      actionItems: actionItems ?? this.actionItems,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isEmpty {
    return (contentSummary ?? '').isEmpty &&
        (discussionConclusions ?? '').isEmpty &&
        (feynmanOutput ?? '').isEmpty &&
        (blindSpots ?? '').isEmpty &&
        (actionItems ?? '').isEmpty;
  }

  @override
  List<Object?> get props => [
        id, bookId, chapterId, chapterTitle, pageRange,
        contentSummary, discussionConclusions, feynmanOutput,
        blindSpots, actionItems, createdAt, updatedAt,
      ];
}

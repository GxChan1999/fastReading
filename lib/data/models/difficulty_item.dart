import 'package:equatable/equatable.dart';

/// 疑难清单模型
class DifficultyItem extends Equatable {
  final String id; // UUID
  final String bookId;
  final String? chapterId;
  final String content; // 疑难内容描述
  final String? selectedText; // 相关原文
  final String? aiExplanation; // AI 解释
  final bool isResolved;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DifficultyItem({
    required this.id,
    required this.bookId,
    this.chapterId,
    required this.content,
    this.selectedText,
    this.aiExplanation,
    this.isResolved = false,
    required this.createdAt,
    required this.updatedAt,
  });

  DifficultyItem copyWith({
    String? id,
    String? bookId,
    String? chapterId,
    String? content,
    String? selectedText,
    String? aiExplanation,
    bool? isResolved,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DifficultyItem(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      chapterId: chapterId ?? this.chapterId,
      content: content ?? this.content,
      selectedText: selectedText ?? this.selectedText,
      aiExplanation: aiExplanation ?? this.aiExplanation,
      isResolved: isResolved ?? this.isResolved,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        bookId,
        chapterId,
        content,
        selectedText,
        aiExplanation,
        isResolved,
        createdAt,
        updatedAt,
      ];
}

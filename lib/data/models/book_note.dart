import 'package:equatable/equatable.dart';

/// 阅读笔记模型
class BookNote extends Equatable {
  final String id; // UUID
  final String bookId;
  final String? chapterId;
  final String content;
  final String? selectedText; // 选中的原文文本
  final String? noteType; // 笔记类型: question/insight/summary/comment
  final DateTime createdAt;
  final DateTime updatedAt;

  const BookNote({
    required this.id,
    required this.bookId,
    this.chapterId,
    required this.content,
    this.selectedText,
    this.noteType,
    required this.createdAt,
    required this.updatedAt,
  });

  BookNote copyWith({
    String? id,
    String? bookId,
    String? chapterId,
    String? content,
    String? selectedText,
    String? noteType,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BookNote(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      chapterId: chapterId ?? this.chapterId,
      content: content ?? this.content,
      selectedText: selectedText ?? this.selectedText,
      noteType: noteType ?? this.noteType,
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
        noteType,
        createdAt,
        updatedAt,
      ];
}

import 'package:equatable/equatable.dart';

/// 书籍章节模型
class BookChapter extends Equatable {
  final String id; // UUID
  final String bookId;
  final int index; // 章节序号
  final String title;
  final String textFilePath; // 章节文本文件路径
  final String? fullText; // 完整文本（非持久化，运行时加载）
  final int pageCount; // 页数（PDF 适用）
  final bool isRead;
  final DateTime createdAt;

  const BookChapter({
    required this.id,
    required this.bookId,
    required this.index,
    required this.title,
    required this.textFilePath,
    this.fullText,
    this.pageCount = 0,
    this.isRead = false,
    required this.createdAt,
  });

  BookChapter copyWith({
    String? id,
    String? bookId,
    int? index,
    String? title,
    String? textFilePath,
    String? fullText,
    int? pageCount,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return BookChapter(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      index: index ?? this.index,
      title: title ?? this.title,
      textFilePath: textFilePath ?? this.textFilePath,
      fullText: fullText ?? this.fullText,
      pageCount: pageCount ?? this.pageCount,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        bookId,
        index,
        title,
        textFilePath,
        fullText,
        pageCount,
        isRead,
        createdAt,
      ];
}

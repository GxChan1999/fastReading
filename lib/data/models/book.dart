import 'package:equatable/equatable.dart';

/// 书籍格式枚举
enum BookFormat {
  epub,
  pdf,
  txt;

  String get extension {
    switch (this) {
      case BookFormat.epub:
        return '.epub';
      case BookFormat.pdf:
        return '.pdf';
      case BookFormat.txt:
        return '.txt';
    }
  }

  static BookFormat fromExtension(String ext) {
    switch (ext.toLowerCase()) {
      case '.epub':
        return BookFormat.epub;
      case '.pdf':
        return BookFormat.pdf;
      case '.txt':
        return BookFormat.txt;
      default:
        throw ArgumentError('不支持的书籍格式: $ext');
    }
  }
}

/// 书籍阅读状态枚举
enum ReadingStatus {
  idle, // 未开始
  reading, // 阅读中
  finished, // 已读完
}

/// 书籍主模型
class Book extends Equatable {
  final String id; // UUID
  final String name;
  final String author;
  final BookFormat format;
  final String filePath; // 源文件路径
  final String chapterTextsDir; // 章节文本目录
  final String? coverPath; // 封面路径
  final int totalChapters;
  final int currentChapter;
  final double progress; // 0.0 - 1.0
  final ReadingStatus status;
  final String? currentFlowState; // 当前精读流程状态
  final DateTime createdAt;
  final DateTime updatedAt;

  const Book({
    required this.id,
    required this.name,
    this.author = '',
    required this.format,
    required this.filePath,
    required this.chapterTextsDir,
    this.coverPath,
    this.totalChapters = 0,
    this.currentChapter = 0,
    this.progress = 0.0,
    this.status = ReadingStatus.idle,
    this.currentFlowState,
    required this.createdAt,
    required this.updatedAt,
  });

  Book copyWith({
    String? id,
    String? name,
    String? author,
    BookFormat? format,
    String? filePath,
    String? chapterTextsDir,
    String? coverPath,
    int? totalChapters,
    int? currentChapter,
    double? progress,
    ReadingStatus? status,
    String? currentFlowState,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Book(
      id: id ?? this.id,
      name: name ?? this.name,
      author: author ?? this.author,
      format: format ?? this.format,
      filePath: filePath ?? this.filePath,
      chapterTextsDir: chapterTextsDir ?? this.chapterTextsDir,
      coverPath: coverPath ?? this.coverPath,
      totalChapters: totalChapters ?? this.totalChapters,
      currentChapter: currentChapter ?? this.currentChapter,
      progress: progress ?? this.progress,
      status: status ?? this.status,
      currentFlowState: currentFlowState ?? this.currentFlowState,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        author,
        format,
        filePath,
        chapterTextsDir,
        coverPath,
        totalChapters,
        currentChapter,
        progress,
        status,
        currentFlowState,
        createdAt,
        updatedAt,
      ];
}

import 'package:uuid/uuid.dart';
import '../database/database_helper.dart';
import '../models/book.dart';
import '../models/book_chapter.dart';
import '../../core/constants/app_constants.dart';

/// 书籍仓库 — 管理书籍及章节数据的增删改查
class BookRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final Uuid _uuid = const Uuid();

  /// 导入书籍记录
  Future<Book> createBook({
    required String name,
    required String author,
    required BookFormat format,
    required String filePath,
    required String chapterTextsDir,
    String? coverPath,
    int totalChapters = 0,
  }) async {
    final now = DateTime.now();
    final book = Book(
      id: _uuid.v4(),
      name: name,
      author: author,
      format: format,
      filePath: filePath,
      chapterTextsDir: chapterTextsDir,
      coverPath: coverPath,
      totalChapters: totalChapters,
      createdAt: now,
      updatedAt: now,
    );
    _db.insertBook(book);
    return book;
  }

  /// 获取所有书籍
  List<Book> getAllBooks() => _db.getAllBooks();

  /// 获取单本书籍
  Book? getBookById(String id) => _db.getBookById(id);

  /// 更新书籍信息
  void updateBook(Book book) => _db.updateBook(book);

  /// 删除书籍（同时清理文件由 FileSystemService 处理）
  void deleteBook(String id) => _db.deleteBook(id);

  /// 更新阅读进度
  void updateProgress(String bookId, int currentChapter, double progress) {
    _db.updateReadingProgress(bookId, currentChapter, progress);
  }

  /// 批量保存章节
  List<BookChapter> saveChapters(String bookId, List<MapEntry<String, String>> chapterTitlesAndFiles) {
    final now = DateTime.now();
    final chapters = chapterTitlesAndFiles.asMap().entries.map((entry) {
      final index = entry.key;
      final title = entry.value.key;
      final filePath = entry.value.value;
      return BookChapter(
        id: _uuid.v4(),
        bookId: bookId,
        index: index,
        title: title,
        textFilePath: filePath,
        createdAt: now,
      );
    }).toList();

    _db.insertChapters(chapters);
    return chapters;
  }

  /// 获取书籍所有章节
  List<BookChapter> getChapters(String bookId) {
    return _db.getChaptersByBookId(bookId);
  }

  /// 获取单个章节
  BookChapter? getChapter(String chapterId) {
    return _db.getChapterById(chapterId);
  }

  /// 标记章节已读
  void markChapterRead(String chapterId) {
    _db.markChapterRead(chapterId);
  }

  /// 搜索书籍
  List<Book> searchBooks(String query) {
    final all = _db.getAllBooks();
    final lowerQuery = query.toLowerCase();
    return all
        .where((b) =>
            b.name.toLowerCase().contains(lowerQuery) ||
            b.author.toLowerCase().contains(lowerQuery))
        .toList();
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/book.dart';
import '../data/repositories/book_repository.dart';

/// 书籍列表提供者
final bookListProvider = StateNotifierProvider<BookListNotifier, List<Book>>((ref) {
  return BookListNotifier();
});

class BookListNotifier extends StateNotifier<List<Book>> {
  final BookRepository _repository = BookRepository();

  BookListNotifier() : super([]);

  /// 加载书籍列表
  void loadBooks() {
    state = _repository.getAllBooks();
  }

  /// 添加书籍
  void addBook(Book book) {
    // book 已由外部通过 repository 创建
    loadBooks();
  }

  /// 删除书籍
  void removeBook(String bookId) {
    _repository.deleteBook(bookId);
    state = state.where((b) => b.id != bookId).toList();
  }

  /// 搜索书籍
  void search(String query) {
    if (query.isEmpty) {
      loadBooks();
    } else {
      state = _repository.searchBooks(query);
    }
  }

  /// 刷新
  void refresh() => loadBooks();
}

/// 当前选中的书籍
final currentBookProvider = StateProvider.family<Book?, String>((ref, bookId) {
  final repo = BookRepository();
  return repo.getBookById(bookId);
});

/// 书籍章节列表提供者
final chapterListProvider = FutureProvider.family<List, String>((ref, bookId) {
  final repo = BookRepository();
  return repo.getChapters(bookId);
});

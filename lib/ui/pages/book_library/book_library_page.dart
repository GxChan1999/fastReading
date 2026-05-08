import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;

import '../../../core/constants/app_constants.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/file_utils.dart';
import '../../../data/models/book.dart';
import '../../../data/repositories/book_repository.dart';
import '../../../providers/book_provider.dart';
import '../../../services/ebook_service.dart';
import '../../../services/file_system_service.dart';
import 'widgets/book_card.dart';
import 'widgets/import_button.dart';

/// 书籍库首页
class BookLibraryPage extends ConsumerStatefulWidget {
  const BookLibraryPage({super.key});

  @override
  _BookLibraryPageState createState() => _BookLibraryPageState();
}

class _BookLibraryPageState extends ConsumerState<BookLibraryPage> {
  final EbookService _ebookService = EbookService();
  final BookRepository _bookRepo = BookRepository();
  final FileSystemService _fileSystem = FileSystemService();
  bool _isImporting = false;
  bool _isDragActive = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bookListProvider.notifier).loadBooks();
    });
  }

  Future<void> _importBook() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['epub', 'pdf', 'txt'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return;

      final filePath = result.files.single.path;
      if (filePath == null) return;

      setState(() => _isImporting = true);

      // 1. 解析书籍（含章节文本写入磁盘）
      final importResult = await _ebookService.importBook(filePath);
      final bookMeta = importResult.book;
      final chapterEntries = importResult.chapterEntries;

      // 2. 创建数据库记录
      final book = await _bookRepo.createBook(
        name: bookMeta.name,
        author: bookMeta.author,
        format: bookMeta.format,
        filePath: bookMeta.filePath,
        chapterTextsDir: bookMeta.chapterTextsDir,
        coverPath: bookMeta.coverPath,
        totalChapters: bookMeta.totalChapters,
      );

      // 3. 保存章节到数据库
      _bookRepo.saveChapters(book.id, chapterEntries);

      // 4. 刷新列表
      ref.read(bookListProvider.notifier).refresh();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('《${book.name}》导入成功')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('导入失败: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  void _openBook(Book book) {
    Navigator.of(context).pushNamed(
      AppRoutes.readingRoute(book.id),
    );
  }

  void _confirmDelete(Book book) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除书籍'),
        content: Text('确定要删除《${book.name}》吗？\n相关文件和数据将一并删除。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              try {
                // 1. 先清理磁盘文件
                final bookDir = p.dirname(book.chapterTextsDir);
                await FileUtils.deleteDirectory(bookDir);
                // 2. 再删数据库记录
                ref.read(bookListProvider.notifier).removeBook(book.id);
                if (mounted) Navigator.pop(ctx);
              } catch (e) {
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('删除失败：$e'),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final books = ref.watch(bookListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的书库'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: '阅读历史',
            onPressed: () => Navigator.pushNamed(context, AppRoutes.history),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: '设置',
            onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
          ),
        ],
      ),
      body: Column(
        children: [
          // 搜索栏
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: '搜索书籍...',
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onChanged: (value) {
                _searchQuery = value;
                ref.read(bookListProvider.notifier).search(value);
              },
            ),
          ),
          // 导入按钮
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _isImporting
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : ImportButton(onTap: _importBook),
          ),
          const SizedBox(height: 8),
          // 书籍列表
          Expanded(
            child: books.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.menu_book, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          '还没有书籍',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[400],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '点击上方按钮导入你的第一本书',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: _calculateCrossAxisCount(context),
                      childAspectRatio: 0.7,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: books.length,
                    itemBuilder: (context, index) {
                      final book = books[index];
                      return BookCard(
                        book: book,
                        onTap: () => _openBook(book),
                        onDelete: () => _confirmDelete(book),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  int _calculateCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 6;
    if (width > 900) return 4;
    if (width > 600) return 3;
    return 2;
  }
}

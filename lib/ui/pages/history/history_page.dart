import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';
import '../../../data/models/reading_snapshot.dart';
import '../../../data/repositories/book_repository.dart';
import '../../../services/reading_flow_service.dart';
import 'widgets/timeline_view.dart';
import 'widgets/chapter_history_view.dart';

/// 历史记录页 — 支持时间线和章节双维度浏览
class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key});

  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final BookRepository _bookRepo = BookRepository();
  final ReadingFlowService _flowService = ReadingFlowService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  void _restoreSnapshot(ReadingSnapshot snapshot) {
    Navigator.pushNamed(
      context,
      AppRoutes.readingRoute(snapshot.bookId),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final books = _bookRepo.getAllBooks();

    return Scaffold(
      appBar: AppBar(
        title: const Text('阅读历史'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '时间线'),
            Tab(text: '按章节'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 时间线视图
          _buildTimelineTab(books),
          // 章节视图
          _buildChapterTab(books),
        ],
      ),
    );
  }

  Widget _buildTimelineTab(List<dynamic> books) {
    // 收集所有快照
    final allSnapshots = <ReadingSnapshot>[];
    for (final book in books) {
      allSnapshots.addAll(_flowService.getSnapshots(book.id));
    }
    allSnapshots.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return TimelineView(
      snapshots: allSnapshots,
      onTap: _restoreSnapshot,
    );
  }

  Widget _buildChapterTab(List<dynamic> books) {
    if (books.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.book, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(
              '还没有阅读记录',
              style: TextStyle(color: Colors.grey[400]),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.bookLibrary),
              child: const Text('去导入书籍'),
            ),
          ],
        ),
      );
    }

    // 显示第一本书的章节（后续可添加书籍选择）
    final firstBook = books.first;
    final chapters = _bookRepo.getChapters(firstBook.id);

    return ChapterHistoryView(
      chapters: chapters,
      currentChapter: firstBook.currentChapter,
      onTap: (chapter) {
        Navigator.pushNamed(
          context,
          AppRoutes.readingRoute(firstBook.id),
        );
      },
    );
  }
}

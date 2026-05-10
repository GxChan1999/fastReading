import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/book_chapter.dart';
import '../../../../services/ebook_parser/ebook_parser.dart';

/// 目录抽屉 — 自定义动画侧面板
class ChapterDrawer extends StatefulWidget {
  final List<BookChapter> chapters;
  final String? currentChapterId;
  final ValueChanged<BookChapter> onChapterTap;

  const ChapterDrawer({
    super.key,
    required this.chapters,
    this.currentChapterId,
    required this.onChapterTap,
  });

  @override
  State<ChapterDrawer> createState() => _ChapterDrawerState();
}

class _ChapterDrawerState extends State<ChapterDrawer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _slideAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
    _slideAnim = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _fadeAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      reverseCurve: const Interval(0.3, 1.0, curve: Curves.easeIn),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void close() {
    _controller.reverse();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // 背景遮罩
          FadeTransition(
          opacity: _fadeAnim,
          child: GestureDetector(
            onTap: close,
            child: Container(
              color: Colors.black54,
            ),
          ),
        ),
        // 侧边面板
        SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(-0.35, 0),
            end: Offset.zero,
          ).animate(_slideAnim),
          child: Container(
            width: 300,
            decoration: const BoxDecoration(
              color: AppTheme.surfaceColor,
              border: Border(
                right: BorderSide(color: AppTheme.goldBorder, width: 0.5),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题栏
                Container(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 16,
                    left: 20,
                    right: 12,
                    bottom: 14,
                  ),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: AppTheme.dividerColor),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          '目录',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18,
                            color: AppTheme.textSecondary),
                        onPressed: close,
                      ),
                    ],
                  ),
                ),
                // 章节列表
                Expanded(
                  child: _ChapterList(
                    chapters: widget.chapters,
                    currentChapterId: widget.currentChapterId,
                    onChapterTap: (chapter) {
                      widget.onChapterTap(chapter);
                      close();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
    );
  }
}

/// 章节列表 — 无交错动画，使用固定高度优化滚动性能
class _ChapterList extends StatelessWidget {
  final List<BookChapter> chapters;
  final String? currentChapterId;
  final ValueChanged<BookChapter> onChapterTap;

  const _ChapterList({
    required this.chapters,
    this.currentChapterId,
    required this.onChapterTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: chapters.length,
      itemExtent: 48, // 固定高度，启用滚动优化
      itemBuilder: (context, index) {
        final chapter = chapters[index];
        final isCurrent = chapter.id == currentChapterId;
        final isContentChapter = ChapterFilter.isContentChapter(chapter.title);

        return ListTile(
          dense: true,
          selected: isCurrent,
          selectedTileColor: AppTheme.primaryColor.withOpacity(0.1),
          leading: SizedBox(
            width: 24,
            child: chapter.isRead
                ? const Icon(Icons.check_circle, size: 16,
                    color: AppTheme.successColor)
                : Text(
                    '${index + 1}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
          ),
          title: Text(
            chapter.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
              color: isCurrent
                  ? AppTheme.primaryColor
                  : isContentChapter
                      ? AppTheme.textPrimary
                      : AppTheme.textSecondary,
            ),
          ),
          onTap: () => onChapterTap(chapter),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/book_chapter.dart';

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
                    slideAnim: _slideAnim,
                    animationDuration: _controller.duration!,
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

/// 章节列表 — 交错入场动画
class _ChapterList extends StatefulWidget {
  final List<BookChapter> chapters;
  final String? currentChapterId;
  final ValueChanged<BookChapter> onChapterTap;
  final Animation<double> slideAnim;
  final Duration animationDuration;

  const _ChapterList({
    required this.chapters,
    this.currentChapterId,
    required this.onChapterTap,
    required this.slideAnim,
    required this.animationDuration,
  });

  @override
  State<_ChapterList> createState() => _ChapterListState();
}

class _ChapterListState extends State<_ChapterList> {
  final List<_ItemEntry> _entries = [];
  bool _built = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_built && widget.chapters.isNotEmpty) {
      _built = true;
      _buildEntries();
    }
  }

  void _buildEntries() {
    for (var i = 0; i < widget.chapters.length; i++) {
      final delay = (i * 30).clamp(0, 400);
      final anim = CurvedAnimation(
        parent: widget.slideAnim,
        curve: Interval(
          (delay / widget.animationDuration.inMilliseconds).clamp(0.0, 0.8),
          1.0,
          curve: Curves.easeOutCubic,
        ),
      );
      _entries.add(_ItemEntry(
        chapter: widget.chapters[i],
        opacityAnim: anim,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _entries.length,
      separatorBuilder: (_, __) =>
          const Divider(height: 1, indent: 20, endIndent: 20),
      itemBuilder: (context, index) {
        final entry = _entries[index];
        final chapter = entry.chapter;
        final isCurrent = chapter.id == widget.currentChapterId;
        final isRead = chapter.isRead;

        return AnimatedBuilder(
          animation: entry.opacityAnim,
          builder: (context, child) {
            return Opacity(
              opacity: entry.opacityAnim.value,
              child: Transform.translate(
                offset: Offset(12 * (1 - entry.opacityAnim.value), 0),
                child: child,
              ),
            );
          },
          child: ListTile(
            dense: true,
            selected: isCurrent,
            selectedTileColor: AppTheme.primaryColor.withOpacity(0.1),
            leading: SizedBox(
              width: 24,
              child: isRead
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
              style: TextStyle(
                fontSize: 14,
                fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                color:
                    isCurrent ? AppTheme.primaryColor : AppTheme.textPrimary,
              ),
            ),
            onTap: () => widget.onChapterTap(chapter),
          ),
        );
      },
    );
  }
}

class _ItemEntry {
  final BookChapter chapter;
  final Animation<double> opacityAnim;
  _ItemEntry({required this.chapter, required this.opacityAnim});
}

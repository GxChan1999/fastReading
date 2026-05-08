import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/book_chapter.dart';

/// 目录侧边栏
class ChapterDrawer extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              right: 16,
              bottom: 12,
            ),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppTheme.dividerColor),
              ),
            ),
            child: const Text(
              '目录',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: chapters.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16),
              itemBuilder: (context, index) {
                final chapter = chapters[index];
                final isCurrent = chapter.id == currentChapterId;
                final isRead = chapter.isRead;

                return ListTile(
                  dense: true,
                  selected: isCurrent,
                  selectedTileColor: AppTheme.primaryColor.withOpacity(0.08),
                  leading: SizedBox(
                    width: 24,
                    child: isRead
                        ? const Icon(Icons.check_circle, size: 16, color: AppTheme.successColor)
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
                      color: isCurrent ? AppTheme.primaryColor : null,
                    ),
                  ),
                  onTap: () {
                    onChapterTap(chapter);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

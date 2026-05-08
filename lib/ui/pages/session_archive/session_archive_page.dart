import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/reading_session.dart';
import '../../../data/repositories/book_repository.dart';
import '../../../providers/session_provider.dart';
import '../../../services/export_service.dart';
import 'session_edit_page.dart';

/// 费曼归档页 — 单本书的完整阅读归档时间线
class SessionArchivePage extends ConsumerStatefulWidget {
  final String bookId;

  const SessionArchivePage({super.key, required this.bookId});

  @override
  ConsumerState<SessionArchivePage> createState() => _SessionArchivePageState();
}

class _SessionArchivePageState extends ConsumerState<SessionArchivePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(sessionListProvider(widget.bookId).notifier).loadSessions();
    });
  }

  Future<void> _exportArchive(BuildContext context) async {
    try {
      final exportPath = await ExportService.instance.exportFeynmanArchive(widget.bookId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已导出到：$exportPath')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出失败：$e'), backgroundColor: AppTheme.errorColor),
        );
      }
    }
  }

  void _openEditor({ReadingSession? session}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SessionEditPage(
          bookId: widget.bookId,
          session: session,
        ),
      ),
    ).then((_) {
      ref.read(sessionListProvider(widget.bookId).notifier).loadSessions();
    });
  }

  void _confirmDelete(ReadingSession session) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除归档'),
        content: const Text('确定要删除这条归档记录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              ref.read(sessionListProvider(widget.bookId).notifier).deleteSession(session.id);
              Navigator.pop(ctx);
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
    final sessions = ref.watch(sessionListProvider(widget.bookId));
    final book = BookRepository().getBookById(widget.bookId);

    return Scaffold(
      appBar: AppBar(
        title: Text('费曼归档 · ${book?.name ?? ""}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: '导出费曼归档 MD',
            onPressed: () => _exportArchive(context),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '手动添加归档',
            onPressed: () => _openEditor(),
          ),
        ],
      ),
      body: sessions.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.archive_outlined, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    '暂无归档记录',
                    style: TextStyle(fontSize: 16, color: Colors.grey[400]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '每轮阅读对话后可归档留存',
                    style: TextStyle(fontSize: 13, color: Colors.grey[400]),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              itemCount: sessions.length,
              itemBuilder: (context, index) {
                return _SessionCard(
                  session: sessions[index],
                  onTap: () => _openEditor(session: sessions[index]),
                  onDelete: () => _confirmDelete(sessions[index]),
                );
              },
            ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final ReadingSession session;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _SessionCard({
    required this.session,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('yyyy-MM-dd HH:mm').format(session.createdAt);
    final hasContent = !session.isEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 头部：日期 + 章节
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 6),
                  Text(dateStr, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                  const Spacer(),
                  if (session.chapterTitle.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        session.chapterTitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.more_vert, size: 18),
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'delete', child: Text('删除')),
                    ],
                    onSelected: (v) {
                      if (v == 'delete') onDelete();
                    },
                  ),
                ],
              ),
              if (!hasContent) ...[
                const SizedBox(height: 12),
                Text(
                  '（空归档，点击编辑补充内容）',
                  style: TextStyle(fontSize: 13, color: Colors.grey[400]),
                ),
              ],
              if (session.contentSummary?.isNotEmpty == true) ...[
                const SizedBox(height: 12),
                _buildSection('📖 内容概述', session.contentSummary!),
              ],
              if (session.feynmanOutput?.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                _buildSection('🗣 费曼输出', session.feynmanOutput!),
              ],
              if (session.blindSpots?.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                _buildSection('❓ 知识盲区', session.blindSpots!),
              ],
              if (session.actionItems?.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                _buildSection('✅ 行动项', session.actionItems!),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String label, String text) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(
          text,
          style: const TextStyle(fontSize: 14, height: 1.5),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

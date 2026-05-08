import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/reading_session.dart';
import '../../../data/repositories/book_repository.dart';
import '../../../providers/session_provider.dart';

/// 归档编辑器 — 新增/编辑单条费曼归档
class SessionEditPage extends ConsumerStatefulWidget {
  final String bookId;
  final ReadingSession? session;
  final String prefillChapterTitle;
  final String prefillPageRange;

  const SessionEditPage({
    super.key,
    required this.bookId,
    this.session,
    this.prefillChapterTitle = '',
    this.prefillPageRange = '',
  });

  @override
  ConsumerState<SessionEditPage> createState() => _SessionEditPageState();
}

class _SessionEditPageState extends ConsumerState<SessionEditPage> {
  late final TextEditingController _summaryCtrl;
  late final TextEditingController _discussionCtrl;
  late final TextEditingController _feynmanCtrl;
  late final TextEditingController _blindSpotsCtrl;
  late final TextEditingController _actionsCtrl;
  late final TextEditingController _pageRangeCtrl;

  bool _isNew = true;

  @override
  void initState() {
    super.initState();
    _isNew = widget.session == null;
    _summaryCtrl = TextEditingController(text: widget.session?.contentSummary ?? '');
    _discussionCtrl = TextEditingController(text: widget.session?.discussionConclusions ?? '');
    _feynmanCtrl = TextEditingController(text: widget.session?.feynmanOutput ?? '');
    _blindSpotsCtrl = TextEditingController(text: widget.session?.blindSpots ?? '');
    _actionsCtrl = TextEditingController(text: widget.session?.actionItems ?? '');
    _pageRangeCtrl = TextEditingController(
      text: widget.session?.pageRange ?? widget.prefillPageRange,
    );
  }

  void _save() {
    final notifier = ref.read(sessionListProvider(widget.bookId).notifier);

    if (_isNew) {
      final book = BookRepository().getBookById(widget.bookId);
      notifier.createSession(
        chapterTitle: book?.name ?? '',
        pageRange: _pageRangeCtrl.text.trim(),
        contentSummary: _summaryCtrl.text.trim(),
        discussionConclusions: _discussionCtrl.text.trim(),
        feynmanOutput: _feynmanCtrl.text.trim(),
        blindSpots: _blindSpotsCtrl.text.trim(),
        actionItems: _actionsCtrl.text.trim(),
      );
    } else {
      notifier.updateSession(widget.session!.copyWith(
        pageRange: _pageRangeCtrl.text.trim(),
        contentSummary: _summaryCtrl.text.trim(),
        discussionConclusions: _discussionCtrl.text.trim(),
        feynmanOutput: _feynmanCtrl.text.trim(),
        blindSpots: _blindSpotsCtrl.text.trim(),
        actionItems: _actionsCtrl.text.trim(),
      ));
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _summaryCtrl.dispose();
    _discussionCtrl.dispose();
    _feynmanCtrl.dispose();
    _blindSpotsCtrl.dispose();
    _actionsCtrl.dispose();
    _pageRangeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? '新建归档' : '编辑归档'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('保存'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildField('页码范围', _pageRangeCtrl, hint: '如：第2章 P30-45', maxLines: 1),
            const SizedBox(height: 16),
            _buildField('📖 当次阅读核心内容概述', _summaryCtrl,
                hint: '这段内容讲了什么？核心观点是什么？', maxLines: 4),
            const SizedBox(height: 16),
            _buildField('💡 本次讨论核心结论', _discussionCtrl,
                hint: '和 AI 讨论后得出的核心结论', maxLines: 4),
            const SizedBox(height: 16),
            _buildField('🗣 用户费曼输出核心内容', _feynmanCtrl,
                hint: '用你自己的话讲出来，怎么给外行人解释？', maxLines: 6),
            const SizedBox(height: 16),
            _buildField('❓ 排查出的知识盲区', _blindSpotsCtrl,
                hint: '哪些概念没吃透？哪里理解有偏差？', maxLines: 4),
            const SizedBox(height: 16),
            _buildField('✅ 后续行动项', _actionsCtrl,
                hint: '接下来要做什么？落地到工作/生活中的具体行动', maxLines: 4),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, {
    String? hint,
    int maxLines = 4,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
          style: const TextStyle(fontSize: 14, height: 1.5),
        ),
      ],
    );
  }
}

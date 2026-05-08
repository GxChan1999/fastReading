import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/book.dart';
import '../../../data/models/book_chapter.dart';

import '../../../data/repositories/book_repository.dart';
import '../../../data/repositories/conversation_repository.dart';
import '../../../providers/chat_provider.dart';
import '../../../providers/session_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../services/ebook_service.dart';
import '../../../services/prompt_service.dart';
import '../../widgets/split_layout.dart';
import '../chat/widgets/chat_input_bar.dart';
import '../chat/widgets/message_bubble.dart';
import '../session_archive/session_edit_page.dart';
import 'widgets/chapter_drawer.dart';
import 'widgets/book_content_view.dart';

/// 阅读 + 对话双联动核心页
class ReadingPage extends ConsumerStatefulWidget {
  final String bookId;

  const ReadingPage({super.key, required this.bookId});

  @override
  _ReadingPageState createState() => _ReadingPageState();
}

class _ReadingPageState extends ConsumerState<ReadingPage> {
  final BookRepository _bookRepo = BookRepository();
  final EbookService _ebookService = EbookService();
  final ConversationRepository _conversationRepo = ConversationRepository();

  Book? _book;
  List<BookChapter> _chapters = [];
  BookChapter? _currentChapter;
  String _chapterContent = '';
  String _selectedText = '';
  String? _currentConversationId;
  final ScrollController _contentScrollController = ScrollController();
  final TextEditingController _chatInputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadBook();
  }

  void _loadBook() {
    final book = _bookRepo.getBookById(widget.bookId);
    if (book == null) return;
    setState(() {
      _book = book;
      _chapters = _bookRepo.getChapters(widget.bookId);
    });
    if (_chapters.isNotEmpty) {
      _loadChapter(_chapters[book.currentChapter.clamp(0, _chapters.length - 1)]);
    }
  }

  Future<void> _loadChapter(BookChapter chapter) async {
    try {
      final content = await _ebookService.readChapterText(chapter.textFilePath);
      setState(() {
        _currentChapter = chapter;
        _chapterContent = content;
      });
      // 更新进度
      if (_book != null) {
        final progress = (chapter.index + 1) / _chapters.length;
        _bookRepo.updateProgress(widget.bookId, chapter.index, progress);
      }
      // 自动创建或切换对话上下文
      _ensureConversation(chapter.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载章节失败: $e')),
        );
      }
    }
  }

  void _ensureConversation(String? chapterId) {
    final conversations = _conversationRepo.getConversations(widget.bookId);
    final existing = conversations.where((c) => c.chapterId == chapterId).toList();
    if (existing.isNotEmpty) {
      setState(() => _currentConversationId = existing.first.id);
    } else {
      final conv = _conversationRepo.createConversation(
        bookId: widget.bookId,
        chapterId: chapterId,
        title: _currentChapter?.title ?? '',
      );
      setState(() => _currentConversationId = conv.id);
    }
    if (_currentConversationId != null) {
      ref.read(messageListProvider(_currentConversationId!).notifier).loadMessages();
    }
  }

  void _onTextSelected(String text) {
    setState(() => _selectedText = text);
    _chatInputController.text = '关于这段内容：$text\n\n';
  }

  void _openChatPage() {
    Navigator.pushNamed(
      context,
      AppRoutes.chatRoute(widget.bookId, chapterId: _currentChapter?.id),
    );
  }

  void _openFlowPage() {
    Navigator.pushNamed(context, AppRoutes.flowRoute(widget.bookId));
  }

  void _openArchivePage() {
    Navigator.pushNamed(context, AppRoutes.archiveRoute(widget.bookId));
  }

  @override
  void dispose() {
    _contentScrollController.dispose();
    _chatInputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final readingPrefs = settings.readingPrefs;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _book?.name ?? '阅读',
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          // 精读流程入口
          IconButton(
            icon: const Icon(Icons.route),
            tooltip: '精读流程',
            onPressed: _openFlowPage,
          ),
          // 全屏对话
          IconButton(
            icon: const Icon(Icons.forum),
            tooltip: '对话',
            onPressed: _openChatPage,
          ),
          // 费曼归档
          IconButton(
            icon: const Icon(Icons.archive_outlined),
            tooltip: '费曼归档',
            onPressed: _openArchivePage,
          ),
        ],
      ),
      body: SplitLayout(
        ratio: 0.6,
        leftPanel: Scaffold(
          resizeToAvoidBottomInset: false,
          appBar: AppBar(
            title: Text(
              _currentChapter?.title ?? '选择章节',
              style: const TextStyle(fontSize: 14),
            ),
            automaticallyImplyLeading: false,
            leading: Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.list),
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              ),
            ),
          ),
          drawer: ChapterDrawer(
            chapters: _chapters,
            currentChapterId: _currentChapter?.id,
            onChapterTap: _loadChapter,
          ),
          body: BookContentView(
            content: _chapterContent,
            prefs: readingPrefs,
            title: _currentChapter?.title ?? '',
          ),
        ),
        rightPanel: _buildChatPanel(),
      ),
    );
  }

  Widget _buildChatPanel() {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(
          '对话 · ${_currentChapter?.title ?? "全书"}',
          style: const TextStyle(fontSize: 14),
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.archive_outlined, size: 18),
            tooltip: '归档本轮对话',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SessionEditPage(
                    bookId: widget.bookId,
                    prefillChapterTitle: _currentChapter?.title ?? '',
                    prefillPageRange: _currentChapter?.title ?? '',
                  ),
                ),
              ).then((_) {
                ref.read(sessionListProvider(widget.bookId).notifier).loadSessions();
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18),
            tooltip: '清空上下文',
            onPressed: () {
              if (_currentConversationId != null) {
                final newConv = _conversationRepo.createConversation(
                  bookId: widget.bookId,
                  chapterId: _currentChapter?.id,
                  title: _currentChapter?.title ?? '',
                );
                setState(() => _currentConversationId = newConv.id);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _currentConversationId == null
                ? Center(
                    child: Text(
                      '选择章节后开始对话',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                  )
                : Consumer(
                    builder: (context, ref, _) {
                      final messages = ref.watch(
                        messageListProvider(_currentConversationId!),
                      );
                      if (messages.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.chat_bubble_outline,
                                  size: 48, color: Colors.grey[300]),
                              const SizedBox(height: 12),
                              Text(
                                '选中文本或输入问题开始对话',
                                style: TextStyle(color: Colors.grey[400]),
                              ),
                            ],
                          ),
                        );
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          return MessageBubble(message: messages[index]);
                        },
                      );
                    },
                  ),
          ),
          // 选中文本提示
          if (_selectedText.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(8),
              color: AppTheme.accentColor.withOpacity(0.1),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: () => setState(() => _selectedText = ''),
                  ),
                ],
              ),
            ),
          // 输入栏
          ChatInputBar(
            controller: _chatInputController,
            hintText: '输入提问...',
            onSend: (text) => _sendChatMessage(text),
          ),
        ],
      ),
    );
  }

  void _sendChatMessage(String text) {
    if (_currentConversationId == null) return;

    final settings = ref.read(settingsProvider);
    if (!settings.isInitialized || settings.apiConfig.apiKey.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请先在设置页配置 API 密钥')),
        );
      }
      return;
    }

    final systemPrompt = PromptService.instance.getCurrentPromptContent() ?? '';
    final bookInfo = '《${_book?.name ?? ""}》 ${_book?.author ?? ""}';
    final readingContent = _chapterContent.isNotEmpty
        ? '章节：${_currentChapter?.title ?? ""}\n$_chapterContent'
        : '';

    try {
      ref.read(sendChatMessageProvider).call(
        conversationId: _currentConversationId!,
        userMessage: text,
        systemPrompt: systemPrompt,
        bookInfo: bookInfo,
        readingContent: readingContent,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('发送失败：$e'), backgroundColor: AppTheme.errorColor),
        );
      }
    }
  }
}

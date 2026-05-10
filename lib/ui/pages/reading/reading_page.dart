import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/platform_utils.dart';
import '../../../data/models/app_config.dart';
import '../../../data/models/book.dart';
import '../../../data/models/book_chapter.dart';
import '../../../data/models/conversation.dart' as conv;

import '../../../data/repositories/book_repository.dart';
import '../../../data/repositories/conversation_repository.dart';
import '../../../data/repositories/session_repository.dart';
import '../../../providers/chat_provider.dart';
import '../../../providers/session_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../services/ebook_parser/ebook_parser.dart';
import '../../../services/ebook_service.dart';
import '../../../services/prompt_service.dart';
import '../../widgets/split_layout.dart';
import '../session_archive/session_edit_page.dart';
import 'widgets/chat_panel.dart';
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
  bool _chatPrimary = true;
  final TextEditingController _chatInputController = TextEditingController();

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // 缓存的正文（非前/后置）章节，供 AI 上下文章节号与进度计算
  List<BookChapter> get _contentChapters => _chapters
      .where((c) => ChapterFilter.isContentChapter(c.title))
      .toList();

  int _getContentChapterIndex(BookChapter chapter) {
    return _contentChapters.indexWhere((c) => c.id == chapter.id);
  }

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
      final isChapterSwitch = _currentChapter != null && _currentChapter!.id != chapter.id;
      setState(() {
        _currentChapter = chapter;
        _chapterContent = content;
      });
      if (_book != null) {
        final contentChapters = _contentChapters;
        final contentIndex = _getContentChapterIndex(chapter);
        if (contentChapters.isNotEmpty && contentIndex >= 0) {
          final progress = (contentIndex + 1) / contentChapters.length;
          _bookRepo.updateProgress(widget.bookId, contentIndex, progress);
        }
      }
      _ensureConversation(chapter.id);
      if (isChapterSwitch && _currentConversationId != null) {
        _injectChapterSwitchMessage(chapter);
      }
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
    if (conversations.isNotEmpty) {
      setState(() => _currentConversationId = conversations.first.id);
    } else {
      final conv = _conversationRepo.createConversation(
        bookId: widget.bookId,
        chapterId: null,
        title: _book?.name ?? '阅读对话',
      );
      setState(() => _currentConversationId = conv.id);
    }
    if (_currentConversationId != null) {
      ref.read(messageListProvider(_currentConversationId!).notifier).loadMessages();
    }
  }

  void _injectChapterSwitchMessage(BookChapter chapter) {
    if (_currentConversationId == null) return;
    final contentIndex = _getContentChapterIndex(chapter);
    final isContent = contentIndex >= 0;
    final label = isContent
        ? '正文第${contentIndex + 1}章（共${_contentChapters.length}章）'
        : '辅文章节';
    _conversationRepo.addSystemMessage(
      _currentConversationId!,
      '[系统] 用户已切换到$label：${chapter.title}',
    );
    ref.read(messageListProvider(_currentConversationId!).notifier).loadMessages();
  }

  void _onTextSelected(String text) {
    setState(() => _selectedText = text);
    _chatInputController.text = '关于这段内容：$text\n\n';
  }

  void _openChapterDrawer() {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        transitionDuration: const Duration(milliseconds: 200),
        reverseTransitionDuration: const Duration(milliseconds: 150),
        pageBuilder: (context, animation, secondaryAnimation) {
          return ChapterDrawer(
            chapters: _chapters,
            currentChapterId: _currentChapter?.id,
            onChapterTap: _loadChapter,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
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

  void _handleArchive() {
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
  }

  void _handleClearContext() {
    if (_currentConversationId != null) {
      final newConv = _conversationRepo.createConversation(
        bookId: widget.bookId,
        chapterId: null,
        title: _book?.name ?? '阅读对话',
      );
      setState(() => _currentConversationId = newConv.id);
    }
  }

  void _handleSendMessage(String text) {
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

    // 计算真实章节号（仅正文）
    final contentChapters = _contentChapters;
    final contentIndex = _currentChapter != null
        ? _getContentChapterIndex(_currentChapter!)
        : -1;
    final totalContent = contentChapters.length;
    final chapterTitle = _currentChapter?.title ?? '';

    final chapterLabel = contentIndex >= 0
        ? '正文第${contentIndex + 1}章 / 共${totalContent}章'
        : '辅文章节（非正文）';
    final progressPercent = contentIndex >= 0 && totalContent > 0
        ? ((contentIndex + 1) / totalContent * 100).toStringAsFixed(0)
        : '0';
    final currentProgress = '$chapterLabel，进度 $progressPercent%';

    // 构建结构化章节内容（带元数据）
    final readingContent = _chapterContent.isNotEmpty
        ? '## 正在阅读\n'
          '**章节**：$chapterTitle\n'
          '**定位**：$currentProgress\n'
          '**书籍**：$bookInfo\n\n'
          '## 章节正文\n$_chapterContent'
        : '';

    final recentMessages =
        _conversationRepo.getRecentMessages(_currentConversationId!);
    final chatHistory = recentMessages.isNotEmpty
        ? recentMessages
            .where((m) => m.role != conv.MessageRole.system)
            .map((m) => '${m.role == conv.MessageRole.user ? '用户' : 'AI'}: ${m.content}')
            .join('\n')
        : null;

    final sessionRepo = SessionRepository();
    final sessions = sessionRepo.getSessions(widget.bookId);
    final feynmanContext = sessions.isNotEmpty
        ? sessions
            .map((s) => [
                  if ((s.contentSummary ?? '').isNotEmpty) '概述：${s.contentSummary}',
                  if ((s.discussionConclusions ?? '').isNotEmpty)
                    '结论：${s.discussionConclusions}',
                  if ((s.feynmanOutput ?? '').isNotEmpty) '费曼输出：${s.feynmanOutput}',
                  if ((s.blindSpots ?? '').isNotEmpty) '知识盲区：${s.blindSpots}',
                ].join(' | '))
            .where((s) => s.isNotEmpty)
            .join('\n')
        : null;

    try {
      ref.read(sendChatMessageProvider).call(
            conversationId: _currentConversationId!,
            userMessage: text,
            systemPrompt: systemPrompt,
            bookInfo: bookInfo,
            readingContent: readingContent,
            chatHistory: chatHistory,
            currentProgress: currentProgress,
            feynmanContext: feynmanContext,
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('发送失败：$e'), backgroundColor: AppTheme.errorColor),
        );
      }
    }
  }

  @override
  void dispose() {
    _chatInputController.dispose();
    super.dispose();
  }

  Widget _buildChatPanelWidget({required bool isEmbedded}) {
    return ChatPanel(
      key: const ValueKey('chat_panel'),
      bookId: widget.bookId,
      conversationId: _currentConversationId,
      chapterTitle: _currentChapter?.title,
      selectedText: _selectedText,
      inputController: _chatInputController,
      onClearSelectedText: () => setState(() => _selectedText = ''),
      onSend: _handleSendMessage,
      onArchive: _handleArchive,
      onClearContext: _handleClearContext,
      onClose: isEmbedded
          ? null
          : () {
              if (_scaffoldKey.currentState?.isEndDrawerOpen == true) {
                Navigator.of(context).pop();
              }
            },
      isEmbedded: isEmbedded,
    );
  }

  @override
  Widget build(BuildContext context) {
    final readingPrefs = ref.watch(settingsProvider).readingPrefs;
    final wideScreen = PlatformUtils.isWideScreen(context);

    if (wideScreen) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_book?.name ?? '阅读', overflow: TextOverflow.ellipsis),
          actions: [
            IconButton(
              icon: Icon(_chatPrimary ? Icons.view_sidebar : Icons.view_quilt),
              tooltip: _chatPrimary ? '切换为阅读为主' : '切换为对话为主',
              onPressed: () => setState(() => _chatPrimary = !_chatPrimary),
            ),
            IconButton(
              icon: const Icon(Icons.route),
              tooltip: '精读流程',
              onPressed: _openFlowPage,
            ),
            IconButton(
              icon: const Icon(Icons.forum),
              tooltip: '对话',
              onPressed: _openChatPage,
            ),
            IconButton(
              icon: const Icon(Icons.archive_outlined),
              tooltip: '费曼归档',
              onPressed: _openArchivePage,
            ),
          ],
        ),
        body: _chatPrimary
            ? SplitLayout(
                ratio: 0.65,
                leftPanel: _buildChatPanelWidget(isEmbedded: true),
                rightPanel: _buildReadingPanel(readingPrefs),
              )
            : SplitLayout(
                ratio: 0.6,
                leftPanel: _buildReadingPanel(readingPrefs),
                rightPanel: _buildChatPanelWidget(isEmbedded: true),
              ),
      );
    }

    // 直板手机
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(_book?.name ?? '阅读', overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: const Icon(Icons.route),
            tooltip: '精读流程',
            onPressed: _openFlowPage,
          ),
          IconButton(
            icon: const Icon(Icons.forum),
            tooltip: '全屏对话',
            onPressed: _openChatPage,
          ),
          IconButton(
            icon: const Icon(Icons.archive_outlined),
            tooltip: '费曼归档',
            onPressed: _openArchivePage,
          ),
          IconButton(
            icon: Icon(
              _scaffoldKey.currentState?.isEndDrawerOpen == true
                  ? Icons.chat_rounded
                  : Icons.chat_outlined,
            ),
            tooltip: '对话面板',
            onPressed: () {
              if (_scaffoldKey.currentState?.isEndDrawerOpen == true) {
                Navigator.of(context).pop();
              } else {
                _scaffoldKey.currentState?.openEndDrawer();
              }
            },
          ),
        ],
      ),
      endDrawer: _buildChatDrawer(),
      body: _buildReadingPanel(readingPrefs),
    );
  }

  Widget _buildChatDrawer() {
    final media = MediaQuery.of(context);
    final drawerWidth = (media.size.width * 0.85).clamp(280.0, 480.0);
    return Drawer(
      width: drawerWidth,
      child: Padding(
        padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
        child: _buildChatPanelWidget(isEmbedded: false),
      ),
    );
  }

  Widget _buildReadingPanel(ReadingPreferences readingPrefs) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(
          _currentChapter?.title ?? '选择章节',
          style: const TextStyle(fontSize: 14),
        ),
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.list),
          onPressed: _openChapterDrawer,
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: BookContentView(
              content: _chapterContent,
              prefs: readingPrefs,
              title: _currentChapter?.title ?? '',
            ),
          ),
          _buildChapterNavBar(),
        ],
      ),
    );
  }

  Widget _buildChapterNavBar() {
    final currentIndex = _currentChapter?.index ?? 0;
    final hasPrev = currentIndex > 0;
    final hasNext = currentIndex < _chapters.length - 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppTheme.dividerColor)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 20),
            tooltip: '上一章',
            onPressed:
                hasPrev ? () => _loadChapter(_chapters[currentIndex - 1]) : null,
          ),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: currentIndex,
                isExpanded: true,
                style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary),
                items: _chapters.asMap().entries.map((e) {
                  return DropdownMenuItem<int>(
                    value: e.key,
                    child: Text(e.value.title, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (index) {
                  if (index != null && index != currentIndex) {
                    _loadChapter(_chapters[index]);
                  }
                },
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, size: 20),
            tooltip: '下一章',
            onPressed:
                hasNext ? () => _loadChapter(_chapters[currentIndex + 1]) : null,
          ),
        ],
      ),
    );
  }
}

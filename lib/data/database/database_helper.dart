import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';
import '../../core/constants/app_constants.dart';
import '../models/book.dart';
import '../models/book_chapter.dart';
import '../models/prompt_rule.dart';
import '../models/conversation.dart' as conv;
import '../models/reading_snapshot.dart';
import '../models/book_note.dart';
import '../models/difficulty_item.dart';
import '../models/reading_session.dart';

/// SQLite 数据库助手 — 封装所有数据库操作
class DatabaseHelper {
  static DatabaseHelper? _instance;
  late Database _db;
  bool _initialized = false;

  DatabaseHelper._();

  static DatabaseHelper get instance {
    _instance ??= DatabaseHelper._();
    return _instance!;
  }

  /// 初始化数据库
  Future<void> initialize() async {
    if (_initialized) return;

    final dir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dir.path, AppConstants.databaseName);
    _db = sqlite3.open(dbPath);

    // 启用 WAL 模式
    _db.execute('PRAGMA journal_mode=WAL;');
    _db.execute('PRAGMA foreign_keys=ON;');

    await _createTables();
    _initialized = true;
  }

  /// 创建所有核心表
  Future<void> _createTables() async {
    _db.execute('''
      CREATE TABLE IF NOT EXISTS books (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        author TEXT DEFAULT '',
        format TEXT NOT NULL,
        file_path TEXT NOT NULL,
        chapter_texts_dir TEXT NOT NULL,
        cover_path TEXT,
        total_chapters INTEGER DEFAULT 0,
        current_chapter INTEGER DEFAULT 0,
        progress REAL DEFAULT 0.0,
        status TEXT DEFAULT 'idle',
        current_flow_state TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      );
    ''');

    _db.execute('''
      CREATE TABLE IF NOT EXISTS book_chapters (
        id TEXT PRIMARY KEY,
        book_id TEXT NOT NULL,
        idx INTEGER NOT NULL,
        title TEXT NOT NULL,
        text_file_path TEXT NOT NULL,
        page_count INTEGER DEFAULT 0,
        is_read INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY (book_id) REFERENCES books(id) ON DELETE CASCADE
      );
    ''');

    _db.execute('''
      CREATE TABLE IF NOT EXISTS prompt_rules (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        file_path TEXT NOT NULL,
        content TEXT NOT NULL,
        content_hash TEXT NOT NULL,
        is_default INTEGER DEFAULT 0,
        is_builtin INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      );
    ''');

    _db.execute('''
      CREATE TABLE IF NOT EXISTS conversations (
        id TEXT PRIMARY KEY,
        book_id TEXT NOT NULL,
        chapter_id TEXT,
        flow_state TEXT,
        title TEXT DEFAULT '',
        message_count INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (book_id) REFERENCES books(id) ON DELETE CASCADE
      );
    ''');

    _db.execute('''
      CREATE TABLE IF NOT EXISTS conversation_messages (
        id TEXT PRIMARY KEY,
        conversation_id TEXT NOT NULL,
        role TEXT NOT NULL,
        content TEXT NOT NULL,
        is_streaming INTEGER DEFAULT 0,
        is_starred INTEGER DEFAULT 0,
        is_difficulty INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE
      );
    ''');

    _db.execute('''
      CREATE TABLE IF NOT EXISTS book_notes (
        id TEXT PRIMARY KEY,
        book_id TEXT NOT NULL,
        chapter_id TEXT,
        content TEXT NOT NULL,
        selected_text TEXT,
        note_type TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (book_id) REFERENCES books(id) ON DELETE CASCADE
      );
    ''');

    _db.execute('''
      CREATE TABLE IF NOT EXISTS reading_snapshots (
        id TEXT PRIMARY KEY,
        book_id TEXT NOT NULL,
        chapter_id TEXT,
        page_index INTEGER DEFAULT 0,
        scroll_position REAL DEFAULT 0.0,
        current_flow_state TEXT,
        conversation_context TEXT,
        notes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (book_id) REFERENCES books(id) ON DELETE CASCADE
      );
    ''');

    _db.execute('''
      CREATE TABLE IF NOT EXISTS reading_sessions (
        id TEXT PRIMARY KEY,
        book_id TEXT NOT NULL,
        chapter_id TEXT,
        chapter_title TEXT DEFAULT '',
        page_range TEXT,
        content_summary TEXT,
        discussion_conclusions TEXT,
        feynman_output TEXT,
        blind_spots TEXT,
        action_items TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (book_id) REFERENCES books(id) ON DELETE CASCADE
      );
    ''');

    _db.execute('''
      CREATE TABLE IF NOT EXISTS difficulty_list (
        id TEXT PRIMARY KEY,
        book_id TEXT NOT NULL,
        chapter_id TEXT,
        content TEXT NOT NULL,
        selected_text TEXT,
        ai_explanation TEXT,
        is_resolved INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (book_id) REFERENCES books(id) ON DELETE CASCADE
      );
    ''');

    _db.execute('''
      CREATE TABLE IF NOT EXISTS app_config (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      );
    ''');

    // 创建索引
    _db.execute('CREATE INDEX IF NOT EXISTS idx_chapters_book ON book_chapters(book_id, idx);');
    _db.execute(
        'CREATE INDEX IF NOT EXISTS idx_conversations_book ON conversations(book_id, created_at);');
    _db.execute(
        'CREATE INDEX IF NOT EXISTS idx_messages_conversation ON conversation_messages(conversation_id, created_at);');
    _db.execute(
        'CREATE INDEX IF NOT EXISTS idx_snapshots_book ON reading_snapshots(book_id, created_at);');
    _db.execute(
        'CREATE INDEX IF NOT EXISTS idx_difficulty_book ON difficulty_list(book_id, created_at);');
  }

  // ==================== 书籍操作 ====================

  /// 插入书籍
  void insertBook(Book book) {
    _db.execute('''
      INSERT INTO books (id, name, author, format, file_path, chapter_texts_dir,
        cover_path, total_chapters, current_chapter, progress, status, current_flow_state, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''', [
      book.id,
      book.name,
      book.author,
      book.format.name,
      book.filePath,
      book.chapterTextsDir,
      book.coverPath,
      book.totalChapters,
      book.currentChapter,
      book.progress,
      book.status.name,
      book.currentFlowState,
      book.createdAt.toIso8601String(),
      book.updatedAt.toIso8601String(),
    ]);
  }

  /// 查询所有书籍
  List<Book> getAllBooks() {
    final result = _db.select('SELECT * FROM books ORDER BY updated_at DESC');
    return result.map(_bookFromRow).toList();
  }

  /// 根据 ID 查询书籍
  Book? getBookById(String id) {
    final result = _db.select('SELECT * FROM books WHERE id = ?', [id]);
    if (result.isEmpty) return null;
    return _bookFromRow(result.first);
  }

  /// 更新书籍
  void updateBook(Book book) {
    _db.execute('''
      UPDATE books SET name=?, author=?, format=?, file_path=?, chapter_texts_dir=?,
        cover_path=?, total_chapters=?, current_chapter=?, progress=?, status=?,
        current_flow_state=?, updated_at=?
      WHERE id=?
    ''', [
      book.name,
      book.author,
      book.format.name,
      book.filePath,
      book.chapterTextsDir,
      book.coverPath,
      book.totalChapters,
      book.currentChapter,
      book.progress,
      book.status.name,
      book.currentFlowState,
      book.updatedAt.toIso8601String(),
      book.id,
    ]);
  }

  /// 删除书籍
  void deleteBook(String id) {
    _db.execute('DELETE FROM books WHERE id = ?', [id]);
  }

  /// 更新阅读进度
  void updateReadingProgress(String bookId, int currentChapter, double progress) {
    _db.execute('''
      UPDATE books SET current_chapter=?, progress=?, updated_at=? WHERE id=?
    ''', [
      currentChapter,
      progress,
      DateTime.now().toIso8601String(),
      bookId,
    ]);
  }

  Book _bookFromRow(Row row) {
    return Book(
      id: row['id'] as String,
      name: row['name'] as String,
      author: (row['author'] as String?) ?? '',
      format: BookFormat.values.firstWhere((f) => f.name == row['format']),
      filePath: row['file_path'] as String,
      chapterTextsDir: row['chapter_texts_dir'] as String,
      coverPath: row['cover_path'] as String?,
      totalChapters: (row['total_chapters'] as int?) ?? 0,
      currentChapter: (row['current_chapter'] as int?) ?? 0,
      progress: (row['progress'] as num?)?.toDouble() ?? 0.0,
      status: ReadingStatus.values.firstWhere((s) => s.name == ((row['status'] as String?) ?? 'idle')),
      currentFlowState: row['current_flow_state'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }

  // ==================== 章节操作 ====================

  /// 批量插入章节
  void insertChapters(List<BookChapter> chapters) {
    for (final chapter in chapters) {
      _db.execute('''
        INSERT INTO book_chapters (id, book_id, idx, title, text_file_path, page_count, is_read, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
      ''', [
        chapter.id,
        chapter.bookId,
        chapter.index,
        chapter.title,
        chapter.textFilePath,
        chapter.pageCount,
        chapter.isRead ? 1 : 0,
        chapter.createdAt.toIso8601String(),
      ]);
    }
  }

  /// 查询书籍的所有章节
  List<BookChapter> getChaptersByBookId(String bookId) {
    final result =
        _db.select('SELECT * FROM book_chapters WHERE book_id = ? ORDER BY idx ASC', [bookId]);
    return result.map(_chapterFromRow).toList();
  }

  /// 查询单个章节
  BookChapter? getChapterById(String id) {
    final result = _db.select('SELECT * FROM book_chapters WHERE id = ?', [id]);
    if (result.isEmpty) return null;
    return _chapterFromRow(result.first);
  }

  /// 标记章节已读
  void markChapterRead(String chapterId) {
    _db.execute('UPDATE book_chapters SET is_read = 1 WHERE id = ?', [chapterId]);
  }

  BookChapter _chapterFromRow(Row row) {
    return BookChapter(
      id: row['id'] as String,
      bookId: row['book_id'] as String,
      index: row['idx'] as int,
      title: row['title'] as String,
      textFilePath: row['text_file_path'] as String,
      pageCount: (row['page_count'] as int?) ?? 0,
      isRead: (row['is_read'] as int?) == 1,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }

  // ==================== Prompt 规则操作 ====================

  /// 插入 Prompt 规则
  void insertPromptRule(PromptRule rule) {
    // 如果设为默认，先清除其他默认
    if (rule.isDefault) {
      _db.execute('UPDATE prompt_rules SET is_default = 0');
    }
    _db.execute('''
      INSERT INTO prompt_rules (id, name, file_path, content, content_hash, is_default, is_builtin, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''', [
      rule.id,
      rule.name,
      rule.filePath,
      rule.content,
      rule.contentHash,
      rule.isDefault ? 1 : 0,
      rule.isBuiltin ? 1 : 0,
      rule.createdAt.toIso8601String(),
      rule.updatedAt.toIso8601String(),
    ]);
  }

  /// 更新 Prompt 规则
  void updatePromptRule(PromptRule rule) {
    if (rule.isDefault) {
      _db.execute('UPDATE prompt_rules SET is_default = 0');
    }
    _db.execute('''
      UPDATE prompt_rules SET name=?, content=?, content_hash=?, is_default=?, updated_at=?
      WHERE id=?
    ''', [
      rule.name,
      rule.content,
      rule.contentHash,
      rule.isDefault ? 1 : 0,
      rule.updatedAt.toIso8601String(),
      rule.id,
    ]);
  }

  /// 查询所有 Prompt 规则
  List<PromptRule> getAllPromptRules() {
    final result = _db.select('SELECT * FROM prompt_rules ORDER BY is_default DESC, updated_at DESC');
    return result.map(_promptRuleFromRow).toList();
  }

  /// 获取默认 Prompt 规则
  PromptRule? getDefaultPromptRule() {
    final result = _db.select('SELECT * FROM prompt_rules WHERE is_default = 1 LIMIT 1');
    if (result.isEmpty) return null;
    return _promptRuleFromRow(result.first);
  }

  /// 删除 Prompt 规则
  void deletePromptRule(String id) {
    _db.execute('DELETE FROM prompt_rules WHERE id = ?', [id]);
  }

  PromptRule _promptRuleFromRow(Row row) {
    return PromptRule(
      id: row['id'] as String,
      name: row['name'] as String,
      filePath: row['file_path'] as String,
      content: row['content'] as String,
      contentHash: row['content_hash'] as String,
      isDefault: (row['is_default'] as int?) == 1,
      isBuiltin: (row['is_builtin'] as int?) == 1,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }

  // ==================== 对话操作 ====================

  /// 创建对话会话
  void insertConversation(conv.Conversation conversation) {
    _db.execute('''
      INSERT INTO conversations (id, book_id, chapter_id, flow_state, title, message_count, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ''', [
      conversation.id,
      conversation.bookId,
      conversation.chapterId,
      conversation.flowState,
      conversation.title,
      conversation.messageCount,
      conversation.createdAt.toIso8601String(),
      conversation.updatedAt.toIso8601String(),
    ]);
  }

  /// 查询书籍的对话列表
  List<conv.Conversation> getConversationsByBookId(String bookId) {
    final result = _db.select(
      'SELECT * FROM conversations WHERE book_id = ? ORDER BY updated_at DESC',
      [bookId],
    );
    return result.map(_conversationFromRow).toList();
  }

  conv.Conversation _conversationFromRow(Row row) {
    return conv.Conversation(
      id: row['id'] as String,
      bookId: row['book_id'] as String,
      chapterId: row['chapter_id'] as String?,
      flowState: row['flow_state'] as String?,
      title: (row['title'] as String?) ?? '',
      messageCount: (row['message_count'] as int?) ?? 0,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }

  // ==================== 消息操作 ====================

  /// 插入消息
  void insertMessage(conv.ConversationMessage message) {
    _db.execute('''
      INSERT INTO conversation_messages (id, conversation_id, role, content, is_streaming, is_starred, is_difficulty, created_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ''', [
      message.id,
      message.conversationId,
      message.role.name,
      message.content,
      message.isStreaming ? 1 : 0,
      message.isStarred ? 1 : 0,
      message.isDifficulty ? 1 : 0,
      message.createdAt.toIso8601String(),
    ]);
    // 更新消息计数
    _db.execute('''
      UPDATE conversations SET message_count = message_count + 1, updated_at = ? WHERE id = ?
    ''', [DateTime.now().toIso8601String(), message.conversationId]);
  }

  /// 更新消息内容（流式更新）
  void updateMessageContent(String messageId, String content) {
    _db.execute('UPDATE conversation_messages SET content = ? WHERE id = ?', [content, messageId]);
  }

  /// 更新消息流式状态
  void updateMessageStreaming(String messageId, bool isStreaming) {
    _db.execute('UPDATE conversation_messages SET is_streaming = ? WHERE id = ?',
        [isStreaming ? 1 : 0, messageId]);
  }

  /// 获取对话的所有消息
  List<conv.ConversationMessage> getMessagesByConversationId(String conversationId) {
    final result = _db.select(
      'SELECT * FROM conversation_messages WHERE conversation_id = ? ORDER BY created_at ASC',
      [conversationId],
    );
    return result.map(_messageFromRow).toList();
  }

  /// 获取最近 N 轮对话消息
  List<conv.ConversationMessage> getRecentMessages(String conversationId, {int limit = 10}) {
    final result = _db.select(
      'SELECT * FROM conversation_messages WHERE conversation_id = ? ORDER BY created_at DESC LIMIT ?',
      [conversationId, limit * 2], // role pairs
    );
    return result.reversed.map(_messageFromRow).toList();
  }

  conv.ConversationMessage _messageFromRow(Row row) {
    return conv.ConversationMessage(
      id: row['id'] as String,
      conversationId: row['conversation_id'] as String,
      role: conv.MessageRole.values.firstWhere((r) => r.name == row['role']),
      content: row['content'] as String,
      isStreaming: (row['is_streaming'] as int?) == 1,
      isStarred: (row['is_starred'] as int?) == 1,
      isDifficulty: (row['is_difficulty'] as int?) == 1,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }

  // ==================== 笔记操作 ====================

  /// 插入笔记
  void insertNote(BookNote note) {
    _db.execute('''
      INSERT INTO book_notes (id, book_id, chapter_id, content, selected_text, note_type, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ''', [
      note.id,
      note.bookId,
      note.chapterId,
      note.content,
      note.selectedText,
      note.noteType,
      note.createdAt.toIso8601String(),
      note.updatedAt.toIso8601String(),
    ]);
  }

  /// 查询书籍的所有笔记
  List<BookNote> getNotesByBookId(String bookId) {
    final result =
        _db.select('SELECT * FROM book_notes WHERE book_id = ? ORDER BY created_at DESC', [bookId]);
    return result.map(_noteFromRow).toList();
  }

  BookNote _noteFromRow(Row row) {
    return BookNote(
      id: row['id'] as String,
      bookId: row['book_id'] as String,
      chapterId: row['chapter_id'] as String?,
      content: row['content'] as String,
      selectedText: row['selected_text'] as String?,
      noteType: row['note_type'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }

  // ==================== 快照操作 ====================

  /// 插入快照
  void insertSnapshot(ReadingSnapshot snapshot) {
    _db.execute('''
      INSERT INTO reading_snapshots (id, book_id, chapter_id, page_index, scroll_position, current_flow_state, conversation_context, notes, created_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''', [
      snapshot.id,
      snapshot.bookId,
      snapshot.chapterId,
      snapshot.pageIndex,
      snapshot.scrollPosition,
      snapshot.currentFlowState,
      snapshot.conversationContext,
      snapshot.notes,
      snapshot.createdAt.toIso8601String(),
    ]);
  }

  /// 获取书籍的最新快照
  ReadingSnapshot? getLatestSnapshot(String bookId) {
    final result = _db.select(
      'SELECT * FROM reading_snapshots WHERE book_id = ? ORDER BY created_at DESC LIMIT 1',
      [bookId],
    );
    if (result.isEmpty) return null;
    return _snapshotFromRow(result.first);
  }

  /// 获取书籍的所有快照
  List<ReadingSnapshot> getSnapshotsByBookId(String bookId) {
    final result = _db.select(
      'SELECT * FROM reading_snapshots WHERE book_id = ? ORDER BY created_at DESC',
      [bookId],
    );
    return result.map(_snapshotFromRow).toList();
  }

  ReadingSnapshot _snapshotFromRow(Row row) {
    return ReadingSnapshot(
      id: row['id'] as String,
      bookId: row['book_id'] as String,
      chapterId: row['chapter_id'] as String?,
      pageIndex: (row['page_index'] as int?) ?? 0,
      scrollPosition: (row['scroll_position'] as num?)?.toDouble() ?? 0.0,
      currentFlowState: row['current_flow_state'] as String?,
      conversationContext: row['conversation_context'] as String?,
      notes: row['notes'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }

  // ==================== 疑难清单操作 ====================

  /// 插入疑难项
  void insertDifficultyItem(DifficultyItem item) {
    _db.execute('''
      INSERT INTO difficulty_list (id, book_id, chapter_id, content, selected_text, ai_explanation, is_resolved, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''', [
      item.id,
      item.bookId,
      item.chapterId,
      item.content,
      item.selectedText,
      item.aiExplanation,
      item.isResolved ? 1 : 0,
      item.createdAt.toIso8601String(),
      item.updatedAt.toIso8601String(),
    ]);
  }

  /// 查询书籍的疑难清单
  List<DifficultyItem> getDifficultyItemsByBookId(String bookId) {
    final result = _db.select(
      'SELECT * FROM difficulty_list WHERE book_id = ? ORDER BY created_at DESC',
      [bookId],
    );
    return result.map(_difficultyFromRow).toList();
  }

  /// 更新疑难项
  void updateDifficultyItem(DifficultyItem item) {
    _db.execute('''
      UPDATE difficulty_list SET content=?, ai_explanation=?, is_resolved=?, updated_at=?
      WHERE id=?
    ''', [
      item.content,
      item.aiExplanation,
      item.isResolved ? 1 : 0,
      item.updatedAt.toIso8601String(),
      item.id,
    ]);
  }

  DifficultyItem _difficultyFromRow(Row row) {
    return DifficultyItem(
      id: row['id'] as String,
      bookId: row['book_id'] as String,
      chapterId: row['chapter_id'] as String?,
      content: row['content'] as String,
      selectedText: row['selected_text'] as String?,
      aiExplanation: row['ai_explanation'] as String?,
      isResolved: (row['is_resolved'] as int?) == 1,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }

  // ==================== 配置操作 ====================

  /// 保存配置项
  void saveConfig(String key, String value) {
    _db.execute('''
      INSERT OR REPLACE INTO app_config (key, value) VALUES (?, ?)
    ''', [key, value]);
  }

  /// 读取配置项
  String? getConfig(String key) {
    final result = _db.select('SELECT value FROM app_config WHERE key = ?', [key]);
    if (result.isEmpty) return null;
    return result.first['value'] as String;
  }

  /// 删除配置项
  void deleteConfig(String key) {
    _db.execute('DELETE FROM app_config WHERE key = ?', [key]);
  }

  // ==================== 费曼归档操作 ====================

  /// 插入阅读会话归档
  void insertReadingSession(ReadingSession session) {
    _db.execute('''
      INSERT INTO reading_sessions (id, book_id, chapter_id, chapter_title, page_range,
        content_summary, discussion_conclusions, feynman_output, blind_spots, action_items,
        created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''', [
      session.id,
      session.bookId,
      session.chapterId,
      session.chapterTitle,
      session.pageRange,
      session.contentSummary,
      session.discussionConclusions,
      session.feynmanOutput,
      session.blindSpots,
      session.actionItems,
      session.createdAt.toIso8601String(),
      session.updatedAt.toIso8601String(),
    ]);
  }

  /// 更新阅读会话归档
  void updateReadingSession(ReadingSession session) {
    _db.execute('''
      UPDATE reading_sessions SET chapter_title=?, page_range=?,
        content_summary=?, discussion_conclusions=?, feynman_output=?,
        blind_spots=?, action_items=?, updated_at=?
      WHERE id=?
    ''', [
      session.chapterTitle,
      session.pageRange,
      session.contentSummary,
      session.discussionConclusions,
      session.feynmanOutput,
      session.blindSpots,
      session.actionItems,
      session.updatedAt.toIso8601String(),
      session.id,
    ]);
  }

  /// 获取某本书的所有归档（按时间倒序）
  List<ReadingSession> getSessionsByBookId(String bookId) {
    final result = _db.select(
      'SELECT * FROM reading_sessions WHERE book_id = ? ORDER BY created_at DESC',
      [bookId],
    );
    return result.map(_sessionFromRow).toList();
  }

  /// 获取单条归档
  ReadingSession? getSessionById(String id) {
    final result = _db.select(
      'SELECT * FROM reading_sessions WHERE id = ?', [id],
    );
    if (result.isEmpty) return null;
    return _sessionFromRow(result.first);
  }

  /// 删除归档
  void deleteSession(String id) {
    _db.execute('DELETE FROM reading_sessions WHERE id = ?', [id]);
  }

  ReadingSession _sessionFromRow(Row row) {
    return ReadingSession(
      id: row['id'] as String,
      bookId: row['book_id'] as String,
      chapterId: row['chapter_id'] as String?,
      chapterTitle: (row['chapter_title'] as String?) ?? '',
      pageRange: row['page_range'] as String?,
      contentSummary: row['content_summary'] as String?,
      discussionConclusions: row['discussion_conclusions'] as String?,
      feynmanOutput: row['feynman_output'] as String?,
      blindSpots: row['blind_spots'] as String?,
      actionItems: row['action_items'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }

  // ==================== 事务支持 ====================

  /// 执行事务
  void transaction(void Function() action) {
    _db.execute('BEGIN TRANSACTION');
    try {
      action();
      _db.execute('COMMIT');
    } catch (e) {
      _db.execute('ROLLBACK');
      rethrow;
    }
  }

  // ==================== 数据导出 ====================

  /// 导出全量数据为 JSON 格式
  Map<String, dynamic> exportAllData() {
    return {
      'books': getAllBooks().map((b) => {
            'id': b.id,
            'name': b.name,
            'author': b.author,
            'format': b.format.name,
            'filePath': b.filePath,
            'totalChapters': b.totalChapters,
            'currentChapter': b.currentChapter,
            'progress': b.progress,
            'status': b.status.name,
            'currentFlowState': b.currentFlowState,
            'createdAt': b.createdAt.toIso8601String(),
            'updatedAt': b.updatedAt.toIso8601String(),
          }).toList(),
      'configs': _db.select('SELECT * FROM app_config').map((r) => {
            'key': r['key'] as String,
            'value': r['value'] as String,
          }).toList(),
    };
  }

  /// 关闭数据库
  void close() {
    _db.dispose();
    _initialized = false;
  }
}

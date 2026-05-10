import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import '../core/constants/app_constants.dart';
import '../core/utils/file_utils.dart';
import '../data/database/database_helper.dart';
import '../data/models/book.dart';
import '../data/models/book_chapter.dart';
import '../data/models/conversation.dart' show MessageRole, Conversation, ConversationMessage;
import '../data/models/difficulty_item.dart';
import '../data/models/reading_session.dart';
import '../data/repositories/book_repository.dart';
import '../data/repositories/conversation_repository.dart';
import '../data/repositories/settings_repository.dart';
import 'file_system_service.dart';

/// 导出服务 — 阅读笔记、数据备份、文件导出、数据迁移
class ExportService {
  static final ExportService _instance = ExportService._();
  factory ExportService() => _instance;
  static ExportService get instance => _instance;
  ExportService._();

  final DatabaseHelper _db = DatabaseHelper.instance;
  final BookRepository _bookRepo = BookRepository();
  final ConversationRepository _conversationRepo = ConversationRepository();
  final SettingsRepository _settingsRepo = SettingsRepository();
  final FileSystemService _fileSystem = FileSystemService();

  /// 生成阅读笔记 MD 文件
  Future<String> generateReadingNotes(String bookId) async {
    final book = _bookRepo.getBookById(bookId);
    if (book == null) throw Exception('书籍不存在');

    final buffer = StringBuffer();

    // 标题
    buffer.writeln('# 《${book.name}》阅读笔记');
    buffer.writeln();
    buffer.writeln('**作者**：${book.author}');
    buffer.writeln('**阅读进度**：${(book.progress * 100).toStringAsFixed(0)}%');
    buffer.writeln('**生成时间**：${DateTime.now().toIso8601String()}');
    buffer.writeln();
    buffer.writeln('---');
    buffer.writeln();

    // 全书框架
    buffer.writeln('## 全书框架');
    buffer.writeln('> 待补充');
    buffer.writeln();

    // 问答记录
    buffer.writeln('## 问答记录');
    final conversations = _conversationRepo.getConversations(bookId);
    for (final conv in conversations) {
      buffer.writeln('### ${conv.title}');
      final messages = _conversationRepo.getMessages(conv.id);
      for (final msg in messages) {
        final prefix = msg.role == MessageRole.user ? '**Q**' : '**A**';
        buffer.writeln('$prefix：${msg.content}');
        buffer.writeln();
      }
    }

    // 疑难清单
    buffer.writeln('## 疑难清单');
    final difficulties = _db.getDifficultyItemsByBookId(bookId);
    if (difficulties.isEmpty) {
      buffer.writeln('暂无疑难记录。');
    } else {
      for (final item in difficulties) {
        buffer.writeln('- [${item.isResolved ? "x" : " "}] ${item.content}');
        if (item.aiExplanation != null) {
          buffer.writeln('  - AI 解释：${item.aiExplanation}');
        }
      }
    }

    // 保存到文件
    final content = buffer.toString();
    await _fileSystem.saveReadingNotes(bookId, content);

    return content;
  }

  /// 导出阅读笔记到指定目录
  Future<String> exportNotesToFile(String bookId) async {
    final content = await generateReadingNotes(bookId);
    final book = _bookRepo.getBookById(bookId);

    final fileName = '${book?.name ?? 'reading'}_notes.md';
    final exportPath = p.join(
      AppConstants.rootDir,
      AppConstants.exportDir,
      fileName,
    );

    await FileUtils.writeTextFile(exportPath, content);
    return exportPath;
  }

  /// 全量数据备份
  Future<String> backupAllData() async {
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final fileName = 'reading_app_backup_$timestamp.json';
    final backupPath = p.join(AppConstants.rootDir, AppConstants.backupDir, fileName);

    // 导出全量数据
    final data = _db.exportAllData();
    final json = jsonEncode(data);
    await FileUtils.writeTextFile(backupPath, json);

    return backupPath;
  }

  /// 导出费曼归档 MD — 对标费曼学习提效工具格式
  Future<String> exportFeynmanArchive(String bookId) async {
    final book = _bookRepo.getBookById(bookId);
    final sessions = _db.getSessionsByBookId(bookId);
    final difficulties = _db.getDifficultyItemsByBookId(bookId);

    final buffer = StringBuffer();
    buffer.writeln('# ${book?.name ?? "未知书籍"} · 费曼阅读归档');
    buffer.writeln();
    buffer.writeln('**作者**：${book?.author ?? ""}');
    buffer.writeln('**阅读进度**：${((book?.progress ?? 0) * 100).toStringAsFixed(0)}%');
    buffer.writeln('**导出时间**：${DateTime.now().toString().substring(0, 19)}');
    buffer.writeln();
    buffer.writeln('---');
    buffer.writeln();

    // 阅读总览
    buffer.writeln('## 一、阅读总览');
    buffer.writeln('- 累计完成阅读轮次：${sessions.length} 轮');
    buffer.writeln('- 累计排查知识盲区：${difficulties.length} 个');
    buffer.writeln('- 已解决疑难：${difficulties.where((d) => d.isResolved).length} 个');
    buffer.writeln();
    buffer.writeln('---');
    buffer.writeln();

    // 单次归档区
    buffer.writeln('## 二、单次阅读归档区');
    buffer.writeln();
    for (final s in sessions) {
      final dateStr = s.createdAt.toString().substring(0, 10);
      final chapterLabel = s.chapterTitle.isNotEmpty ? ' | ${s.chapterTitle}' : '';
      final pageLabel = (s.pageRange?.isNotEmpty == true) ? ' | ${s.pageRange}' : '';

      buffer.writeln('### 【$dateStr | ${book?.name ?? ""}$chapterLabel$pageLabel】');
      buffer.writeln('1. 当次阅读核心内容概述：');
      if ((s.contentSummary ?? '').isNotEmpty) {
        buffer.writeln('   ${s.contentSummary!.replaceAll('\n', '\n   ')}');
      }
      buffer.writeln('2. 本次讨论核心结论：');
      if ((s.discussionConclusions ?? '').isNotEmpty) {
        buffer.writeln('   ${s.discussionConclusions!.replaceAll('\n', '\n   ')}');
      }
      buffer.writeln('3. 用户费曼输出核心内容：');
      if ((s.feynmanOutput ?? '').isNotEmpty) {
        buffer.writeln('   ${s.feynmanOutput!.replaceAll('\n', '\n   ')}');
      }
      buffer.writeln('4. 本次排查出的知识盲区/未吃透知识点：');
      if ((s.blindSpots ?? '').isNotEmpty) {
        buffer.writeln('   ${s.blindSpots!.replaceAll('\n', '\n   ')}');
      }
      buffer.writeln('5. 后续行动项/下一轮阅读计划：');
      if ((s.actionItems ?? '').isNotEmpty) {
        buffer.writeln('   ${s.actionItems!.replaceAll('\n', '\n   ')}');
      }
      buffer.writeln();
      buffer.writeln('---');
      buffer.writeln();
    }

    // 盲区汇总
    buffer.writeln('## 三、知识盲区与复盘汇总');
    buffer.writeln();
    if (difficulties.isEmpty) {
      buffer.writeln('暂无疑难记录。');
    } else {
      buffer.writeln('| 序号 | 盲区/知识点 | 发现日期 | 状态 |');
      buffer.writeln('|------|------------|----------|------|');
      for (var i = 0; i < difficulties.length; i++) {
        final d = difficulties[i];
        buffer.writeln('| ${i + 1} | ${d.content} | ${d.createdAt.toString().substring(0, 10)} | ${d.isResolved ? "已巩固" : "待解决"} |');
      }
    }
    buffer.writeln();

    final fileName = '${book?.name ?? "reading"}_费曼归档.md';
    final exportPath = p.join(AppConstants.rootDir, AppConstants.exportDir, fileName);
    final content = buffer.toString();
    await FileUtils.writeTextFile(exportPath, content);

    return exportPath;
  }

  /// 全量书籍数据导出（含归档、对话、进度、疑难清单）
  Future<String> exportFullBookData(String bookId) async {
    final book = _bookRepo.getBookById(bookId);
    if (book == null) throw Exception('书籍不存在');

    final buffer = StringBuffer();
    final dateStr = DateTime.now().toString().substring(0, 19);

    buffer.writeln('# 《${book.name}》· 全量阅读数据导出');
    buffer.writeln();
    buffer.writeln('**导出时间**：$dateStr');
    buffer.writeln('**作者**：${book.author}');
    buffer.writeln('**格式**：${book.format.name}');
    buffer.writeln('**阅读进度**：${(book.progress * 100).toStringAsFixed(0)}%');
    buffer.writeln('**总章节数**：${book.totalChapters}');
    buffer.writeln('**当前章节**：第${book.currentChapter + 1}章');
    buffer.writeln();
    buffer.writeln('---');
    buffer.writeln();

    // 费曼归档
    final sessions = _db.getSessionsByBookId(bookId);
    buffer.writeln('## 一、费曼学习归档（${sessions.length} 条）');
    buffer.writeln();
    for (final s in sessions) {
      final d = s.createdAt.toString().substring(0, 16);
      buffer.writeln('### [$d] ${s.chapterTitle}');
      if ((s.contentSummary ?? '').isNotEmpty) {
        buffer.writeln('**内容概述**：${s.contentSummary}');
      }
      if ((s.feynmanOutput ?? '').isNotEmpty) {
        buffer.writeln('**费曼输出**：${s.feynmanOutput}');
      }
      if ((s.blindSpots ?? '').isNotEmpty) {
        buffer.writeln('**知识盲区**：${s.blindSpots}');
      }
      if ((s.actionItems ?? '').isNotEmpty) {
        buffer.writeln('**行动项**：${s.actionItems}');
      }
      buffer.writeln();
    }

    // 对话记录
    final conversations = _conversationRepo.getConversations(bookId);
    buffer.writeln('## 二、AI 对话记录（${conversations.length} 轮）');
    buffer.writeln();
    for (final conv in conversations) {
      buffer.writeln('### ${conv.title}');
      final messages = _conversationRepo.getMessages(conv.id);
      for (final msg in messages) {
        final prefix = msg.role == MessageRole.user ? '🧑 **我**' : '🤖 **AI**';
        buffer.writeln('$prefix：${msg.content}');
        buffer.writeln();
      }
      buffer.writeln('---');
      buffer.writeln();
    }

    // 疑难清单
    final difficulties = _db.getDifficultyItemsByBookId(bookId);
    buffer.writeln('## 三、疑难清单（${difficulties.length} 条）');
    buffer.writeln();
    for (final d in difficulties) {
      final status = d.isResolved ? '✅ 已解决' : '❌ 待解决';
      buffer.writeln('- $status | ${d.content}');
    }
    buffer.writeln();

    final fileName = '${book.name}_全量数据_$dateStr.md'.replaceAll(':', '-');
    final exportPath = p.join(AppConstants.rootDir, AppConstants.exportDir, fileName);
    final content = buffer.toString();
    await FileUtils.writeTextFile(exportPath, content);

    return exportPath;
  }

  /// 从备份 JSON 恢复数据（跨版本迁移）
  Future<Map<String, int>> restoreFromBackup(String backupFilePath) async {
    final file = File(backupFilePath);
    if (!await file.exists()) throw Exception('备份文件不存在: $backupFilePath');

    final jsonStr = await file.readAsString();
    final data = jsonDecode(jsonStr) as Map<String, dynamic>;

    var importedBooks = 0;
    var importedChapters = 0;
    var importedConversations = 0;
    var importedMessages = 0;
    var importedSessions = 0;
    var importedDifficulties = 0;
    var importedConfigs = 0;

    // 先重建章节文本文件（在事务外，因为是文件 I/O）
    final chapterTextMap = <String, String>{};
    if (data['chapter_texts'] is List) {
      for (final ct in (data['chapter_texts'] as List)) {
        if (ct is! Map<String, dynamic>) continue;
        final chId = ct['chapter_id'] as String?;
        final text = ct['text'] as String?;
        if (chId != null && text != null) {
          chapterTextMap[chId] = text;
        }
      }
    }

    // 从已导出的章节记录中匹配 text_file_path 并写入文件
    if (data['chapters'] is List) {
      for (final ch in (data['chapters'] as List)) {
        if (ch is! Map<String, dynamic>) continue;
        final chId = ch['id'] as String?;
        final textPath = ch['text_file_path'] as String?;
        final text = chapterTextMap[chId];
        if (chId != null && textPath != null && text != null) {
          try {
            final textFile = File(textPath);
            // 确保父目录存在
            final parent = textFile.parent;
            if (!await parent.exists()) {
              await parent.create(recursive: true);
            }
            await textFile.writeAsString(text);
          } catch (_) {}
        }
      }
    }

    _db.transaction(() {
      // 恢复配置
      if (data['configs'] is List) {
        for (final cfg in (data['configs'] as List)) {
          if (cfg is Map<String, dynamic>) {
            _db.saveConfig(cfg['key'] as String, cfg['value'] as String);
            importedConfigs++;
          }
        }
      }

      // 恢复书籍
      if (data['books'] is List) {
        for (final bookJson in (data['books'] as List)) {
          if (bookJson is! Map<String, dynamic>) continue;
          try {
            final book = Book(
              id: bookJson['id'] as String,
              name: bookJson['name'] as String,
              author: (bookJson['author'] as String?) ?? '',
              format: BookFormat.values.firstWhere(
                (f) => f.name == (bookJson['format'] as String?)),
              filePath: (bookJson['filePath'] as String?) ?? '',
              chapterTextsDir: (bookJson['chapterTextsDir'] as String?) ?? '',
              coverPath: bookJson['coverPath'] as String?,
              totalChapters: (bookJson['totalChapters'] as int?) ?? 0,
              currentChapter: (bookJson['currentChapter'] as int?) ?? 0,
              progress: (bookJson['progress'] as num?)?.toDouble() ?? 0.0,
              status: ReadingStatus.values.firstWhere(
                (s) => s.name == ((bookJson['status'] as String?) ?? 'idle')),
              currentFlowState: bookJson['currentFlowState'] as String?,
              createdAt: DateTime.tryParse(bookJson['createdAt'] as String? ?? '') ?? DateTime.now(),
              updatedAt: DateTime.tryParse(bookJson['updatedAt'] as String? ?? '') ?? DateTime.now(),
            );
            _db.insertBook(book);
            importedBooks++;
          } catch (_) {}
        }
      }

      // 恢复章节
      if (data['chapters'] is List) {
        for (final ch in (data['chapters'] as List)) {
          if (ch is! Map<String, dynamic>) continue;
          try {
            final chapter = BookChapter(
              id: ch['id'] as String,
              bookId: ch['book_id'] as String,
              index: ch['idx'] as int,
              title: ch['title'] as String,
              textFilePath: ch['text_file_path'] as String,
              pageCount: (ch['page_count'] as int?) ?? 0,
              isRead: (ch['is_read'] as int?) == 1,
              createdAt: DateTime.tryParse(ch['created_at'] as String? ?? '') ?? DateTime.now(),
            );
            _db.insertChapters([chapter]);
            importedChapters++;
          } catch (_) {}
        }
      }

      // 恢复对话
      if (data['conversations'] is List) {
        for (final cv in (data['conversations'] as List)) {
          if (cv is! Map<String, dynamic>) continue;
          try {
            final conversation = Conversation(
              id: cv['id'] as String,
              bookId: cv['book_id'] as String,
              chapterId: cv['chapter_id'] as String?,
              flowState: cv['flow_state'] as String?,
              title: (cv['title'] as String?) ?? '',
              messageCount: (cv['message_count'] as int?) ?? 0,
              createdAt: DateTime.tryParse(cv['created_at'] as String? ?? '') ?? DateTime.now(),
              updatedAt: DateTime.tryParse(cv['updated_at'] as String? ?? '') ?? DateTime.now(),
            );
            _db.insertConversation(conversation);
            importedConversations++;
          } catch (_) {}
        }
      }

      // 恢复消息
      if (data['messages'] is List) {
        for (final msg in (data['messages'] as List)) {
          if (msg is! Map<String, dynamic>) continue;
          try {
            final message = ConversationMessage(
              id: msg['id'] as String,
              conversationId: msg['conversation_id'] as String,
              role: MessageRole.values.firstWhere((r) => r.name == msg['role']),
              content: msg['content'] as String,
              isStreaming: (msg['is_streaming'] as int?) == 1,
              isStarred: (msg['is_starred'] as int?) == 1,
              isDifficulty: (msg['is_difficulty'] as int?) == 1,
              createdAt: DateTime.tryParse(msg['created_at'] as String? ?? '') ?? DateTime.now(),
            );
            _db.insertMessageRaw(message);
            importedMessages++;
          } catch (_) {}
        }
      }

      // 恢复费曼归档
      if (data['sessions'] is List) {
        for (final sJson in (data['sessions'] as List)) {
          if (sJson is! Map<String, dynamic>) continue;
          try {
            final session = ReadingSession(
              id: sJson['id'] as String,
              bookId: sJson['bookId'] as String,
              chapterId: sJson['chapterId'] as String?,
              chapterTitle: (sJson['chapterTitle'] as String?) ?? '',
              pageRange: sJson['pageRange'] as String?,
              contentSummary: sJson['contentSummary'] as String?,
              discussionConclusions: sJson['discussionConclusions'] as String?,
              feynmanOutput: sJson['feynmanOutput'] as String?,
              blindSpots: sJson['blindSpots'] as String?,
              actionItems: sJson['actionItems'] as String?,
              createdAt: DateTime.tryParse(sJson['createdAt'] as String? ?? '') ?? DateTime.now(),
              updatedAt: DateTime.tryParse(sJson['updatedAt'] as String? ?? '') ?? DateTime.now(),
            );
            _db.insertReadingSession(session);
            importedSessions++;
          } catch (_) {}
        }
      }

      // 恢复疑难清单
      if (data['difficulties'] is List) {
        for (final d in (data['difficulties'] as List)) {
          if (d is! Map<String, dynamic>) continue;
          try {
            final item = DifficultyItem(
              id: d['id'] as String,
              bookId: d['book_id'] as String,
              chapterId: d['chapter_id'] as String?,
              content: d['content'] as String,
              selectedText: d['selected_text'] as String?,
              aiExplanation: d['ai_explanation'] as String?,
              isResolved: (d['is_resolved'] as int?) == 1,
              createdAt: DateTime.tryParse(d['created_at'] as String? ?? '') ?? DateTime.now(),
              updatedAt: DateTime.tryParse(d['updated_at'] as String? ?? '') ?? DateTime.now(),
            );
            _db.insertDifficultyItem(item);
            importedDifficulties++;
          } catch (_) {}
        }
      }
    });

    return {
      'books': importedBooks,
      'chapters': importedChapters,
      'conversations': importedConversations,
      'messages': importedMessages,
      'sessions': importedSessions,
      'difficulties': importedDifficulties,
      'configs': importedConfigs,
    };
  }

  /// 增强备份（包含归档数据 + 章节文本内容）
  Future<String> backupFullData() async {
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final fileName = 'reading_app_full_backup_$timestamp.json';
    final backupPath = p.join(AppConstants.rootDir, AppConstants.backupDir, fileName);

    final data = _db.exportAllData();

    // 补充导出归档数据
    final allBooks = _bookRepo.getAllBooks();
    final allSessions = <Map<String, dynamic>>[];
    for (final book in allBooks) {
      final sessions = _db.getSessionsByBookId(book.id);
      for (final s in sessions) {
        allSessions.add({
          'id': s.id,
          'bookId': s.bookId,
          'chapterId': s.chapterId,
          'chapterTitle': s.chapterTitle,
          'pageRange': s.pageRange,
          'contentSummary': s.contentSummary,
          'discussionConclusions': s.discussionConclusions,
          'feynmanOutput': s.feynmanOutput,
          'blindSpots': s.blindSpots,
          'actionItems': s.actionItems,
          'createdAt': s.createdAt.toIso8601String(),
          'updatedAt': s.updatedAt.toIso8601String(),
        });
      }
    }
    data['sessions'] = allSessions;

    // 嵌入章节文本内容（用于跨设备迁移时重建文件）
    final chapterTexts = <Map<String, dynamic>>[];
    if (data['chapters'] is List) {
      for (final ch in (data['chapters'] as List)) {
        if (ch is! Map<String, dynamic>) continue;
        final textPath = ch['text_file_path'] as String?;
        if (textPath != null && textPath.isNotEmpty) {
          try {
            final file = File(textPath);
            if (await file.exists()) {
              chapterTexts.add({
                'chapter_id': ch['id'],
                'text': await file.readAsString(),
              });
            }
          } catch (_) {}
        }
      }
    }
    data['chapter_texts'] = chapterTexts;

    final json = const JsonEncoder.withIndent('  ').convert(data);
    await FileUtils.writeTextFile(backupPath, json);

    return backupPath;
  }

  /// 导出疑难清单
  Future<String> exportDifficultyList(String bookId) async {
    final book = _bookRepo.getBookById(bookId);
    final items = _db.getDifficultyItemsByBookId(bookId);

    final buffer = StringBuffer();
    buffer.writeln('# 《${book?.name ?? ""}》疑难清单');
    buffer.writeln('导出时间：${DateTime.now().toIso8601String()}');
    buffer.writeln();

    for (final item in items) {
      buffer.writeln('## ${item.content}');
      buffer.writeln('- 状态：${item.isResolved ? "已解决" : "待解决"}');
      if (item.selectedText != null) {
        buffer.writeln('- 原文：${item.selectedText}');
      }
      if (item.aiExplanation != null) {
        buffer.writeln('- AI 解释：${item.aiExplanation}');
      }
      buffer.writeln();
    }

    final fileName = '${book?.name ?? "reading"}_difficulties.md';
    final exportPath = p.join(AppConstants.rootDir, AppConstants.exportDir, fileName);
    await FileUtils.writeTextFile(exportPath, buffer.toString());

    return exportPath;
  }
}

// 导入 MessageRole 用于导出

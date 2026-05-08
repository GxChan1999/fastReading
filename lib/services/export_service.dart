import 'dart:convert';
import 'package:path/path.dart' as p;
import '../core/constants/app_constants.dart';
import '../core/utils/file_utils.dart';
import '../data/database/database_helper.dart';
import '../data/models/book.dart';
import '../data/models/conversation.dart' show MessageRole;
import '../data/models/difficulty_item.dart';
import '../data/models/reading_session.dart';
import '../data/repositories/book_repository.dart';
import '../data/repositories/conversation_repository.dart';
import '../data/repositories/settings_repository.dart';
import 'file_system_service.dart';

/// 导出服务 — 阅读笔记、数据备份、文件导出
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

import 'dart:io';
import 'package:path/path.dart' as p;
import 'ebook_parser.dart';
import '../../data/models/book.dart';

/// TXT 格式解析器 — 支持自动章节识别
class TxtParserImpl implements EbookParser {
  // 常见章节标题正则
  static final RegExp _chapterPattern = RegExp(
    r'^(第[一二三四五六七八九十百千万\d]+[章节部篇课]|前言|序言|引言|后记|附录|参考|第一章|第二章|第三章|Chapter\s+\d+|CHAPTER\s+\d+)',
    multiLine: true,
  );

  @override
  bool supportsFormat(String filePath) {
    return p.extension(filePath).toLowerCase() == '.txt';
  }

  @override
  Future<EbookParseResult> parse(String filePath) async {
    final content = await File(filePath).readAsString();
    final chapters = _splitChapters(content);

    return EbookParseResult(
      title: p.basenameWithoutExtension(filePath),
      author: '',
      format: BookFormat.txt,
      chapters: chapters,
    );
  }

  /// 智能章节拆分
  List<EbookChapter> _splitChapters(String content) {
    final chapters = <EbookChapter>[];
    final matches = _chapterPattern.allMatches(content).toList();

    if (matches.isEmpty) {
      // 无法识别章节，整本作为一个章节
      return [EbookChapter(title: '全文', content: content, chapterType: ChapterType.body)];
    }

    for (int i = 0; i < matches.length; i++) {
      final start = matches[i].start;
      final end = (i + 1 < matches.length) ? matches[i + 1].start : content.length;
      final title = matches[i].group(0)?.trim() ?? '第${i + 1}章';
      final chapterContent = content.substring(start, end).trim();
      chapters.add(EbookChapter(
        title: title,
        content: chapterContent,
        chapterType: ChapterFilter.getChapterType(title, content: chapterContent),
      ));
    }

    return chapters;
  }

  @override
  Future<String> getChapterContent(String filePath, String chapterId) async {
    // 直接传入章节索引，从解析结果获取
    final content = await File(filePath).readAsString();
    final chapters = _splitChapters(content);
    final index = int.tryParse(chapterId);
    if (index != null && index >= 0 && index < chapters.length) {
      return chapters[index].content;
    }
    return '';
  }

  @override
  Future<String> extractText(String filePath) async {
    return File(filePath).readAsString();
  }
}

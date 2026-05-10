import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:epub_pro/epub_pro.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:image/image.dart' as img;
import 'ebook_parser.dart';
import '../../data/models/book.dart';

/// EPUB 格式解析器 — 基于 epub_pro 实现
class EpubParserImpl implements EbookParser {
  @override
  bool supportsFormat(String filePath) {
    return p.extension(filePath).toLowerCase() == '.epub';
  }

  @override
  Future<EbookParseResult> parse(String filePath) async {
    final bytes = await File(filePath).readAsBytes();
    final bookRef = await EpubReader.openBook(bytes);

    final chapters = <EbookChapter>[];
    final chapterRefs = bookRef.getChapters();

    for (final chapterRef in chapterRefs) {
      final htmlContent = await chapterRef.readHtmlContent();
      final document = html_parser.parse(htmlContent);
      final text = (document.body?.text ?? '').trim();
      final title = chapterRef.title ?? '';

      chapters.add(EbookChapter(
        title: title,
        content: text,
        chapterType: ChapterFilter.getChapterType(title, content: text),
      ));
    }

    // 提取封面
    List<int>? coverBytes;
    try {
      final coverImage = await bookRef.readCover();
      if (coverImage != null) {
        coverBytes = img.encodePng(coverImage);
      }
    } catch (_) {
      // 封面提取失败不阻塞导入
    }

    return EbookParseResult(
      title: bookRef.title ?? p.basenameWithoutExtension(filePath),
      author: bookRef.author ?? '',
      format: BookFormat.epub,
      chapters: chapters,
      coverBytes: coverBytes,
    );
  }

  @override
  Future<String> getChapterContent(String filePath, String chapterId) async {
    final parseResult = await parse(filePath);
    final index = int.tryParse(chapterId);
    if (index != null && index >= 0 && index < parseResult.chapters.length) {
      return parseResult.chapters[index].content;
    }
    return '';
  }

  @override
  Future<String> extractText(String filePath) async {
    final parseResult = await parse(filePath);
    return parseResult.chapters.map((c) => c.content).join('\n\n');
  }
}

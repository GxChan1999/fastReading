import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:epub_pro/epub_pro.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:image/image.dart' as img;
import 'ebook_parser.dart';
import '../../data/models/book.dart';

/// EPUB 格式解析器 — 基于 epub_pro 实现，三层章节分类
class EpubParserImpl implements EbookParser {
  @override
  bool supportsFormat(String filePath) {
    return p.extension(filePath).toLowerCase() == '.epub';
  }

  @override
  Future<EbookParseResult> parse(String filePath) async {
    final bytes = await File(filePath).readAsBytes();
    final bookRef = await EpubReader.openBook(bytes);

    // 提取 EPUB 结构元数据
    final schema = bookRef.schema;
    final spineItems = schema?.package?.spine?.items;
    final guideItems = schema?.package?.guide?.items;
    final manifestItems = schema?.package?.manifest?.items;

    // 构建 manifest id → href 映射
    final idToHref = <String, String>{};
    if (manifestItems != null) {
      for (final m in manifestItems) {
        if (m.id != null && m.href != null) {
          idToHref[m.id!] = m.href!;
        }
      }
    }

    // 构建 spine 顺序映射：href → (isLinear, position)
    final spineMap = <String, ({bool isLinear, int position})>{};
    if (spineItems != null) {
      for (var i = 0; i < spineItems.length; i++) {
        final item = spineItems[i];
        final href = idToHref[item.idRef];
        if (href != null) {
          spineMap[href] = (isLinear: item.isLinear, position: i);
        }
      }
    }

    // 构建 guide 映射：href → guideType
    final guideMap = <String, String>{};
    if (guideItems != null) {
      for (final g in guideItems) {
        if (g.href != null && g.type != null) {
          guideMap[g.href!] = g.type!;
        }
      }
    }

    // 解析所有章节
    final chapterRefs = bookRef.getChapters();
    final titles = <String>[];
    final contents = <String>[];
    final guideTypes = <String?>[];
    final spineLinears = <bool>[];
    final fileNames = <String>[];

    for (final chapterRef in chapterRefs) {
      final htmlContent = await chapterRef.readHtmlContent();
      final document = html_parser.parse(htmlContent);
      final text = (document.body?.text ?? '').trim();
      final title = chapterRef.title ?? '';
      final fileName = chapterRef.contentFileName ?? '';

      titles.add(title);
      contents.add(text);
      fileNames.add(fileName);

      // 查找 guide 类型
      String? guideType;
      for (final entry in guideMap.entries) {
        if (fileName.endsWith(entry.key) || entry.key.endsWith(fileName) || fileName == entry.key) {
          guideType = entry.value;
          break;
        }
      }
      guideTypes.add(guideType);

      // 查找 spine linear 属性
      bool isLinear = true;
      for (final entry in spineMap.entries) {
        if (fileName.endsWith(entry.key) || entry.key.endsWith(fileName) || fileName == entry.key) {
          isLinear = entry.value.isLinear;
          break;
        }
      }
      spineLinears.add(isLinear);
    }

    // 三层分类
    final chapterTypes = ChapterFilter.classifyAll(
      titles: titles,
      contents: contents,
      guideTypes: guideTypes,
      spineLinears: spineLinears,
    );

    final chapters = <EbookChapter>[];
    for (var i = 0; i < chapterRefs.length; i++) {
      chapters.add(EbookChapter(
        title: titles[i],
        content: contents[i],
        chapterType: chapterTypes[i],
      ));
    }

    // 提取封面
    List<int>? coverBytes;
    try {
      final coverImage = await bookRef.readCover();
      if (coverImage != null) {
        coverBytes = img.encodePng(coverImage);
      }
    } catch (_) {}

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

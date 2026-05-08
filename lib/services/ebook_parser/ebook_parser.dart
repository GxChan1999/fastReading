import '../../data/models/book.dart';

/// 电子书解析结果
class EbookParseResult {
  final String title;
  final String author;
  final BookFormat format;
  final List<EbookChapter> chapters;
  final List<int>? coverBytes;

  const EbookParseResult({
    required this.title,
    this.author = '',
    required this.format,
    required this.chapters,
    this.coverBytes,
  });
}

/// 解析后的章节信息
class EbookChapter {
  final String title;
  final String content;
  final int? pageCount;

  const EbookChapter({
    required this.title,
    required this.content,
    this.pageCount,
  });
}

/// 电子书解析器抽象接口
abstract class EbookParser {
  /// 是否支持该格式
  bool supportsFormat(String filePath);

  /// 解析电子书
  Future<EbookParseResult> parse(String filePath);

  /// 获取章节内容
  Future<String> getChapterContent(String filePath, String chapterId);

  /// 提取纯文本内容
  Future<String> extractText(String filePath);
}

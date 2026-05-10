import '../../data/models/book.dart';

/// 章节类型
enum ChapterType {
  frontMatter, // 前置内容（前言、序言、目录等）
  body, // 正文内容
  backMatter, // 后置内容（附录、后记、参考文献等）
}

/// 章节过滤工具
class ChapterFilter {
  ChapterFilter._();

  // 前置内容关键词
  static final _frontMatterPatterns = <Pattern>[
    // 中文
    '前言', '序言', '序', '引言', '导言', '导读',
    '编者的话', '致谢', '版权', '目录', '插图目录', '表格目录',
    '凡例', '卷首', '出版说明', '作者简介', '内容简介', '内容提要',
    '推荐语', '推荐序', '代序', '自序', '译者序', '译序', '原序',
    '再版序', '修订版序', '写在前面', '关于本书',
    // 英文
    'preface', 'foreword', 'introduction', 'prologue', 'acknowledgments',
    'acknowledgements', 'table of contents', 'toc',
  ];

  // 后置内容关键词
  static final _backMatterPatterns = <Pattern>[
    // 中文
    '附录', '后记', '跋', '参考文献', '参考书目', '索引',
    '术语表', '词汇表', '注释', '尾声', '结语', '后序',
    '译后记', '编后记', '出版后记', '尾注',
    // 英文
    'appendix', 'epilogue', 'afterword', 'postscript', 'references',
    'bibliography', 'index', 'glossary', 'notes', 'colophon',
  ];

  /// 判断是否为正文内容章节（非前/后置）
  static bool isContentChapter(String title) {
    return !_isFrontMatter(title) && !_isBackMatter(title) && !_isEmptyChapter(title);
  }

  /// 判断是否为前置内容
  static bool _isFrontMatter(String title) {
    final lower = title.trim().toLowerCase();
    if (lower.isEmpty) return true;
    return _frontMatterPatterns.any((p) {
      if (p is String) return lower.contains(p);
      return false;
    });
  }

  /// 判断是否为后置内容
  static bool _isBackMatter(String title) {
    final lower = title.trim().toLowerCase();
    if (lower.isEmpty) return true;
    return _backMatterPatterns.any((p) {
      if (p is String) return lower.contains(p);
      return false;
    });
  }

  /// 判断是否为空白/无意义章节
  static bool _isEmptyChapter(String title) {
    final trimmed = title.trim();
    return trimmed.isEmpty || trimmed == '未知章节' || trimmed == 'Unknown';
  }

  /// 获取章节类型
  static ChapterType getChapterType(String title, {String content = ''}) {
    if (_isEmptyChapter(title) || (content.trim().length < 50 && title.trim().isEmpty)) {
      return ChapterType.frontMatter;
    }
    if (_isFrontMatter(title)) return ChapterType.frontMatter;
    if (_isBackMatter(title)) return ChapterType.backMatter;
    return ChapterType.body;
  }
}

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
  final ChapterType chapterType;

  const EbookChapter({
    required this.title,
    required this.content,
    this.pageCount,
    this.chapterType = ChapterType.body,
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

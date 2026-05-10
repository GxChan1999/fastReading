import '../../data/models/book.dart';

/// 章节类型
enum ChapterType {
  frontMatter, // 前置内容（前言、序言、目录等）
  body, // 正文内容
  backMatter, // 后置内容（附录、后记、参考文献等）
}

/// 章节过滤工具 — 三层检测：EPUB 结构元数据 → 内容统计 → 标题模式
class ChapterFilter {
  ChapterFilter._();

  // ── Layer 1: EPUB guide type → ChapterType 映射 ──

  static const _guideToFrontMatter = {
    'cover', 'title-page', 'toc', 'foreword', 'preface', 'introduction',
    'prologue', 'acknowledgments', 'acknowledgements', 'dedication',
    'copyright-page', 'copyright', 'other.frontmatter',
  };

  static const _guideToBackMatter = {
    'afterword', 'epilogue', 'appendix', 'bibliography', 'index',
    'glossary', 'colophon', 'other.backmatter', 'notes',
  };

  static const _guideToBody = {
    'text', 'bodymatter', 'start', 'other.bodymatter',
  };

  // ── Layer 3: 标题关键词（大幅扩展） ──

  static final _frontMatterPatterns = <String>[
    // 中文 — 出版与说明
    '出版说明', '再版说明', '修订说明', '凡例', '卷首',
    '作者简介', '内容简介', '内容提要', '内容摘要',
    '版权', '版权信息', '版权页',
    '插图目录', '表格目录', '图表目录', '彩插',
    // 中文 — 推荐与赞誉
    '献词', '赞誉', '推荐语', '推荐序', '名家推荐',
    '媒体推荐', '好评', '推荐', '本书赞誉',
    // 中文 — 序跋类
    '代序', '自序', '译者序', '译序', '原序', '再版序', '修订版序',
    '他序', '前言', '序言', '序', '引言', '导言', '导读', '导语',
    '写在前面', '关于本书', '关于这个版本', '阅读指南',
    '使用说明', '读者须知', '致读者', '致谢', '谢词', '鸣谢',
    // 中文 — 楔子/引子
    '楔子', '引子', '题记', '开篇', '缘起', '前情提要',
    '编者的话', '编者按', '编辑手记', '译后记', '编后记', '出版后记',
    // 英文
    'preface', 'foreword', 'introduction', 'prologue',
    'acknowledgments', 'acknowledgements', 'dedication',
    'table of contents', 'toc', 'epigraph',
    'prelude', 'frontispiece', 'half title',
  ];

  static final _backMatterPatterns = <String>[
    // 中文
    '附录', '后记', '跋', '尾声', '结语', '后序', '结尾',
    '参考文献', '参考书目', '引用文献', '引用书目',
    '索引', '术语表', '词汇表', '名词解释',
    '注释', '尾注', '脚注',
    '译后记', '编后记', '出版后记', '作者后记',
    '延伸阅读', '推荐阅读', '扩展阅读', '相关阅读',
    '致谢', '鸣谢',
    '作者简介', '关于作者', '译作者简介',
    // 英文
    'appendix', 'epilogue', 'afterword', 'postscript',
    'references', 'bibliography', 'works cited',
    'index', 'glossary', 'notes', 'colophon',
    'about the author', 'acknowledgments',
    'further reading', 'endnotes',
  ];

  /// 正文特征模式 — 如果内容中出现这些，大概率是正文
  static final _bodyContentPatterns = <RegExp>[
    RegExp(r'第[一二三四五六七八九十百千\d]+章'),
    RegExp(r'第[一二三四五六七八九十百千\d]+节'),
    RegExp(r'Chapter\s+\d+', caseSensitive: false),
    RegExp(r'CHAPTER\s+\d+'),
    RegExp(r'Part\s+\d+', caseSensitive: false),
    RegExp(r'第[一二三四五六七八九十百千\d]+卷'),
    RegExp(r'第[一二三四五六七八九十百千\d]+部'),
    RegExp(r'第[一二三四五六七八九十百千\d]+回'),
  ];

  // ── Layer 1: 用 EPUB guide 类型判定 ──

  static ChapterType? classifyByGuideType(String? guideType) {
    if (guideType == null) return null;
    final lower = guideType.toLowerCase().trim();
    if (_guideToFrontMatter.contains(lower)) return ChapterType.frontMatter;
    if (_guideToBackMatter.contains(lower)) return ChapterType.backMatter;
    if (_guideToBody.contains(lower)) return ChapterType.body;
    return null;
  }

  // ── Layer 2: 内容统计判定 ──

  /// 对全部章节做两遍分类：先收集长度分布，再逐章判定
  static List<ChapterType> classifyAll({
    required List<String> titles,
    required List<String> contents,
    List<String?>? guideTypes,   // 与章节一一对应，来自 EPUB <guide>
    List<bool>? spineLinears,    // 与章节一一对应，spine linear 属性
  }) {
    final n = titles.length;
    if (n == 0) return [];
    final types = <ChapterType>[];

    // 计算中位长度（仅用于长度启发式）
    final lengths = contents.map((c) => c.length).toList();
    final sorted = List<int>.from(lengths)..sort();
    final median = sorted[sorted.length ~/ 2];

    for (var i = 0; i < n; i++) {
      final title = (i < titles.length) ? titles[i] : '';
      final content = (i < contents.length) ? contents[i] : '';
      final guideType = (guideTypes != null && i < guideTypes.length) ? guideTypes[i] : null;
      final isLinear = (spineLinears != null && i < spineLinears.length) ? spineLinears[i] : true;

      types.add(_classifyOne(
        title: title,
        content: content,
        guideType: guideType,
        isLinear: isLinear,
        medianLength: median,
        position: i,
        totalChapters: n,
      ));
    }

    return types;
  }

  static ChapterType _classifyOne({
    required String title,
    required String content,
    String? guideType,
    bool isLinear = true,
    int medianLength = 0,
    int position = 0,
    int totalChapters = 0,
  }) {
    // 1. EPUB spine linear="no" → 直接判为非正文
    if (!isLinear) return ChapterType.frontMatter;

    // 2. EPUB guide 类型 → 权威判定
    final guideResult = classifyByGuideType(guideType);
    if (guideResult != null) return guideResult;

    final textLen = content.trim().length;
    final titleLower = title.trim().toLowerCase();

    // 3. 空标题 + 极短内容 → 前置
    if (titleLower.isEmpty && textLen < 200) return ChapterType.frontMatter;

    // 4. 正文内容特征 — 标题或内容包含章节号则一定是正文
    if (_hasBodyMarker(title) || _hasBodyMarker(content.substring(0, (content.length < 500) ? content.length : 500))) {
      return ChapterType.body;
    }

    // 5. 标题模式匹配
    if (_matchesFrontMatter(titleLower)) return ChapterType.frontMatter;
    if (_matchesBackMatter(titleLower)) return ChapterType.backMatter;

    // 6. 长度启发式（仅在前 20% 或后 15% 位置生效）
    if (medianLength > 500) {
      final positionRatio = totalChapters > 0 ? position / totalChapters : 0.0;
      final isVeryShort = textLen < medianLength * 0.2;
      if (isVeryShort && positionRatio < 0.20) return ChapterType.frontMatter;
      if (isVeryShort && positionRatio > 0.85) return ChapterType.backMatter;
    }

    // 7. 默认正文
    return ChapterType.body;
  }

  // ── 正文特征检测 ──

  static bool _hasBodyMarker(String text) {
    return _bodyContentPatterns.any((re) => re.hasMatch(text));
  }

  // ── 标题模式匹配 ──

  static bool _matchesFrontMatter(String lowerTitle) {
    return _frontMatterPatterns.any((kw) => lowerTitle.contains(kw));
  }

  static bool _matchesBackMatter(String lowerTitle) {
    return _backMatterPatterns.any((kw) => lowerTitle.contains(kw));
  }

  // ── 便捷方法 ──

  /// 判断是否为正文章节
  static bool isContentChapter(String title) {
    final lower = title.trim().toLowerCase();
    if (lower.isEmpty) return false;
    if (_matchesFrontMatter(lower)) return false;
    if (_matchesBackMatter(lower)) return false;
    return true;
  }

  /// 单章快速分类（无统计信息时的降级方案）
  static ChapterType getChapterType(String title, {String content = ''}) {
    return _classifyOne(title: title, content: content);
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

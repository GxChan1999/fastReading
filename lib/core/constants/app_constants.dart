import 'package:path/path.dart' as p;

class AppConstants {
  AppConstants._();

  // 应用名称
  static const String appName = '阅读提效对话';

  // 数据库
  static const String databaseName = 'reading_efficiency.db';
  static const int databaseVersion = 1;

  // 核心目录结构
  static String _rootDir = '';
  static String get rootDir => _rootDir;

  static const String bookLibraryDir = 'book_library';
  static const String promptRulesDir = 'prompt_rules';
  static const String backupDir = 'backup';
  static const String exportDir = 'export';
  static const String cacheDir = 'cache';

  // 书籍子目录
  static const String chapterTextsDir = 'chapter_texts';
  static const String snapshotsDir = 'snapshots';
  static const String readingNotesFile = 'reading_notes.md';
  static const String sourceFileName = 'source';
  static const String metaFileName = 'meta.json';

  // Prompt
  static const String defaultPromptFileName = 'default_super_teacher.md';

  // AI 配置
  static const int maxContextWindowRatio = 70; // 使用模型窗口的 70%
  static const int maxHistoryRounds = 10; // 保留最近 10 轮对话
  static const int requestTimeoutMs = 60000; // 请求超时时间
  static const int maxRetries = 3; // 最大重试次数

  // 阅读流程状态
  static const List<String> readingFlowSteps = [
    'framework', // 全书框架梳理
    'preliminary_quiz', // 摸底提问
    'chapter_intensive', // 分章精读
    'chapter_discussion', // 章节讨论
    'correction', // 理解纠偏
    'gap_mining', // 缺漏挖掘
    'archive', // 沉淀归档
  ];

  /// 初始化根目录
  static Future<void> ensureDirectoryStructure() async {
    // 由 FileSystemService 在启动时初始化
    // 此处仅定义目录结构规范
  }

  /// 获取书籍专属文件夹路径
  static String getBookDirPath(String bookId) {
    return p.join(_rootDir, bookLibraryDir, bookId);
  }

  /// 获取书籍章节文本目录
  static String getChapterTextsDir(String bookId) {
    return p.join(getBookDirPath(bookId), chapterTextsDir);
  }

  /// 获取书籍快照目录
  static String getSnapshotsDir(String bookId) {
    return p.join(getBookDirPath(bookId), snapshotsDir);
  }

  /// 获取书籍阅读笔记文件
  static String getReadingNotesPath(String bookId) {
    return p.join(getBookDirPath(bookId), readingNotesFile);
  }

  /// 获取书籍源文件路径
  static String getBookSourcePath(String bookId, String extension) {
    return p.join(getBookDirPath(bookId), '$sourceFileName$extension');
  }

  /// 获取 Prompt 规则目录
  static String getPromptRulesDir() {
    return p.join(_rootDir, promptRulesDir);
  }

  /// 设置根目录
  static void setRootDir(String dir) {
    _rootDir = dir;
  }
}

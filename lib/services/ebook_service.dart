import 'dart:io';
import 'package:path/path.dart' as p;
import '../core/constants/app_constants.dart';
import '../core/utils/file_utils.dart';
import '../core/utils/encryption_utils.dart';
import '../data/models/book.dart';
import 'ebook_parser/ebook_parser.dart';
import 'ebook_parser/epub_parser.dart';
import 'ebook_parser/pdf_parser.dart';
import 'ebook_parser/txt_parser.dart';
import 'file_system_service.dart';

/// 导入结果
class ImportResult {
  final Book book;
  final List<MapEntry<String, String>> chapterEntries;

  const ImportResult({required this.book, required this.chapterEntries});
}

/// 电子书服务 — 统一入口，管理导入、解析、文本提取
class EbookService {
  static final EbookService _instance = EbookService._();
  factory EbookService() => _instance;
  EbookService._();

  final FileSystemService _fileSystem = FileSystemService();
  final List<EbookParser> _parsers = [
    EpubParserImpl(),
    PdfParserImpl(),
    TxtParserImpl(),
  ];

  /// 导入电子书，返回解析后的书籍元数据和章节条目
  Future<ImportResult> importBook(String filePath) async {
    final parser = _findParser(filePath);
    if (parser == null) {
      throw UnsupportedError('不支持的书籍格式: $filePath');
    }

    // 1. 解析元数据和章节
    final parseResult = await parser.parse(filePath);

    // 2. 计算文件 MD5 作为唯一标识
    final fileBytes = await File(filePath).readAsBytes();
    final md5Hash = await EncryptionUtils.calculateMd5(fileBytes);

    // 3. 创建书籍目录
    final bookDirName = FileUtils.generateBookDirName(
      parseResult.title,
      parseResult.author,
      md5Hash,
    );
    final bookDir = await _fileSystem.createBookDirectory(bookDirName);

    // 4. 复制源文件
    final sourcePath = await _fileSystem.copySourceFile(filePath, bookDirName);

    // 5. 写入章节文本文件
    final chapterTextsDir = p.join(bookDir, AppConstants.chapterTextsDir);
    final chapterEntries = <MapEntry<String, String>>[];
    for (int i = 0; i < parseResult.chapters.length; i++) {
      final chapter = parseResult.chapters[i];
      final chapterFileName = 'chapter_${i + 1}.txt';
      final chapterFilePath = p.join(chapterTextsDir, chapterFileName);
      await FileUtils.writeTextFile(chapterFilePath, chapter.content);
      chapterEntries.add(MapEntry(chapter.title, chapterFilePath));
    }

    // 6. 写入封面图片
    String? coverPath;
    if (parseResult.coverBytes != null && parseResult.coverBytes!.isNotEmpty) {
      coverPath = p.join(bookDir, 'cover.png');
      await File(coverPath!).writeAsBytes(parseResult.coverBytes!);
    }

    // 7. 构造书籍元数据
    final now = DateTime.now();
    final bodyChapters = parseResult.chapters
        .where((c) => c.chapterType == ChapterType.body)
        .length;
    final book = Book(
      id: '', // 由 Repository 生成
      name: parseResult.title,
      author: parseResult.author,
      format: parseResult.format,
      filePath: sourcePath,
      chapterTextsDir: chapterTextsDir,
      coverPath: coverPath,
      totalChapters: bodyChapters, // 只统计正文章节数
      createdAt: now,
      updatedAt: now,
    );

    return ImportResult(book: book, chapterEntries: chapterEntries);
  }

  /// 读取章节文本
  Future<String> readChapterText(String filePath) async {
    return _fileSystem.readChapterText(filePath);
  }

  /// 获取支持的格式列表
  List<String> getSupportedExtensions() {
    return ['.epub', '.pdf', '.txt'];
  }

  /// 查找匹配的解析器
  EbookParser? _findParser(String filePath) {
    for (final parser in _parsers) {
      if (parser.supportsFormat(filePath)) return parser;
    }
    return null;
  }

  /// 校验文件是否为支持的格式
  bool isSupported(String filePath) {
    final ext = p.extension(filePath).toLowerCase();
    return getSupportedExtensions().contains(ext);
  }
}

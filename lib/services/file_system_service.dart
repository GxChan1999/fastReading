import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/file_utils.dart';

/// 文件系统服务 — 管理应用目录结构与文件生命周期
class FileSystemService {
  static final FileSystemService _instance = FileSystemService._();
  factory FileSystemService() => _instance;
  FileSystemService._();

  bool _initialized = false;

  /// 初始化目录结构
  Future<void> initialize() async {
    if (_initialized) return;

    final dir = await getApplicationDocumentsDirectory();
    AppConstants.setRootDir(dir.path);

    // 创建核心目录
    await Future.wait([
      FileUtils.ensureDirectory(AppConstants.getPromptRulesDir()),
      FileUtils.ensureDirectory(p.join(dir.path, AppConstants.backupDir)),
      FileUtils.ensureDirectory(p.join(dir.path, AppConstants.exportDir)),
      FileUtils.ensureDirectory(p.join(dir.path, AppConstants.cacheDir)),
    ]);

    _initialized = true;
  }

  /// 创建书籍专属目录
  Future<String> createBookDirectory(String bookDirName) async {
    final bookDir = p.join(AppConstants.bookLibraryDir, bookDirName);
    final path = p.join(AppConstants.rootDir, bookDir);

    await Future.wait([
      FileUtils.ensureDirectory(p.join(path, AppConstants.chapterTextsDir)),
      FileUtils.ensureDirectory(p.join(path, AppConstants.snapshotsDir)),
    ]);

    return path;
  }

  /// 复制源文件到书籍目录
  Future<String> copySourceFile(String sourcePath, String bookDirName) async {
    final ext = p.extension(sourcePath);
    final destPath = p.join(
      AppConstants.rootDir,
      AppConstants.bookLibraryDir,
      bookDirName,
      '${AppConstants.sourceFileName}$ext',
    );
    await FileUtils.copyFile(sourcePath, destPath);
    return destPath;
  }

  /// 读取章节文本文件
  Future<String> readChapterText(String filePath) async {
    return FileUtils.readTextFile(filePath);
  }

  /// 写入章节文本文件
  Future<void> writeChapterText(String filePath, String content) async {
    await FileUtils.writeTextFile(filePath, content);
  }

  /// 保存阅读笔记 MD 文件
  Future<void> saveReadingNotes(String bookId, String content) async {
    final path = AppConstants.getReadingNotesPath(bookId);
    await FileUtils.writeTextFile(path, content);
  }

  /// 读取阅读笔记 MD 文件
  Future<String> loadReadingNotes(String bookId) async {
    final path = AppConstants.getReadingNotesPath(bookId);
    if (await FileUtils.fileExists(path)) {
      return FileUtils.readTextFile(path);
    }
    return '';
  }

  /// 导出文件到导出目录
  Future<String> exportFile(String sourcePath, String fileName) async {
    final exportPath = p.join(AppConstants.rootDir, AppConstants.exportDir, fileName);
    await FileUtils.copyFile(sourcePath, exportPath);
    return exportPath;
  }

  /// 创建备份
  Future<String> createBackup(String fileName) async {
    final backupPath = p.join(AppConstants.rootDir, AppConstants.backupDir, fileName);
    // 备份由 ExportService 调用具体的数据库导出逻辑
    return backupPath;
  }

  /// 删除书籍所有文件
  Future<void> deleteBookFiles(String bookId) async {
    final bookDir = AppConstants.getBookDirPath(bookId);
    await FileUtils.deleteDirectory(bookDir);
  }

  /// 获取书籍库大小
  Future<int> getLibrarySize() async {
    final libDir = p.join(AppConstants.rootDir, AppConstants.bookLibraryDir);
    return _getDirectorySize(libDir);
  }

  Future<int> _getDirectorySize(String path) async {
    final dir = Directory(path);
    if (!await dir.exists()) return 0;
    int total = 0;
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File) {
        total += await entity.length();
      }
    }
    return total;
  }

  /// 列出 Prompt 规则目录下的所有 MD 文件
  Future<List<String>> listPromptFiles() async {
    final dir = AppConstants.getPromptRulesDir();
    final files = await FileUtils.listFilesByExtension(dir, '.md');
    return files.map((f) => f.path).toList();
  }
}

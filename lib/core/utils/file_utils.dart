import 'dart:io';
import 'package:path/path.dart' as p;

/// 跨端文件操作工具类，屏蔽平台差异
class FileUtils {
  FileUtils._();

  /// 确保目录存在
  static Future<Directory> ensureDirectory(String path) async {
    final dir = Directory(path);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// 写入文本文件
  static Future<File> writeTextFile(String path, String content) async {
    await ensureDirectory(p.dirname(path));
    return File(path).writeAsString(content, flush: true);
  }

  /// 读取文本文件
  static Future<String> readTextFile(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      throw FileSystemException('文件不存在', path);
    }
    return file.readAsString();
  }

  /// 写入二进制文件
  static Future<File> writeBinaryFile(String path, List<int> bytes) async {
    await ensureDirectory(p.dirname(path));
    return File(path).writeAsBytes(bytes, flush: true);
  }

  /// 读取二进制文件
  static Future<List<int>> readBinaryFile(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      throw FileSystemException('文件不存在', path);
    }
    return file.readAsBytes();
  }

  /// 复制文件
  static Future<File> copyFile(String source, String destination) async {
    await ensureDirectory(p.dirname(destination));
    return File(source).copy(destination);
  }

  /// 删除文件
  static Future<void> deleteFile(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// 删除目录（递归）
  static Future<void> deleteDirectory(String path) async {
    final dir = Directory(path);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }

  /// 列出目录下所有文件
  static Future<List<FileSystemEntity>> listFiles(String path) async {
    final dir = Directory(path);
    if (!await dir.exists()) {
      return [];
    }
    return dir.list().toList();
  }

  /// 列出目录下所有文件（按扩展名过滤）
  static Future<List<File>> listFilesByExtension(
    String path,
    String extension,
  ) async {
    final dir = Directory(path);
    if (!await dir.exists()) {
      return [];
    }
    final files = <File>[];
    await for (final entity in dir.list()) {
      if (entity is File && p.extension(entity.path).toLowerCase() == extension) {
        files.add(entity);
      }
    }
    return files;
  }

  /// 获取文件大小（字节）
  static Future<int> getFileSize(String path) async {
    final file = File(path);
    if (!await file.exists()) return 0;
    return file.length();
  }

  /// 检查文件是否存在
  static Future<bool> fileExists(String path) async {
    return File(path).exists();
  }

  /// 检查目录是否存在
  static Future<bool> directoryExists(String path) async {
    return Directory(path).exists();
  }

  /// 获取安全文件名（移除非法字符）
  static String sanitizeFileName(String name) {
    return name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  }

  /// 生成书籍文件夹名称
  static String generateBookDirName(String bookName, String author, String md5) {
    final safeName = sanitizeFileName(bookName);
    final safeAuthor = sanitizeFileName(author);
    return '$safeName-$safeAuthor-$md5';
  }
}

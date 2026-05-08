import 'dart:convert';
import '../database/database_helper.dart';
import '../models/app_config.dart';
import '../../core/utils/encryption_utils.dart';

/// 设置仓库 — 管理应用配置
class SettingsRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;

  // 配置键
  static const String keyApiConfig = 'api_config';
  static const String keyReadingPrefs = 'reading_preferences';
  static const String keyThemeMode = 'theme_mode';
  static const String keyLastBookId = 'last_book_id';

  // ==================== API 配置 ====================

  /// 保存 API 配置（密钥加密存储）
  Future<void> saveApiConfig(ApiConfig config) async {
    final encryptedKey = await EncryptionUtils.encryptText(config.apiKey);
    final encrypted = config.copyWith(apiKey: encryptedKey);
    _db.saveConfig(keyApiConfig, jsonEncode(encrypted.toJson()));
  }

  /// 读取 API 配置（密钥解密）
  Future<ApiConfig> loadApiConfig() async {
    final json = _db.getConfig(keyApiConfig);
    if (json == null) return const ApiConfig();

    final config = ApiConfig.fromJson(jsonDecode(json));
    if (config.apiKey.isNotEmpty) {
      try {
        final decrypted = await EncryptionUtils.decryptText(config.apiKey);
        return config.copyWith(apiKey: decrypted);
      } catch (_) {
        return config;
      }
    }
    return config;
  }

  // ==================== 阅读排版配置 ====================

  /// 保存阅读排版配置
  void saveReadingPreferences(ReadingPreferences prefs) {
    _db.saveConfig(keyReadingPrefs, jsonEncode(prefs.toJson()));
  }

  /// 读取阅读排版配置
  ReadingPreferences loadReadingPreferences() {
    final json = _db.getConfig(keyReadingPrefs);
    if (json == null) return const ReadingPreferences();
    return ReadingPreferences.fromJson(jsonDecode(json));
  }

  // ==================== 通用配置 ====================

  /// 保存通用配置
  void saveConfig(String key, String value) => _db.saveConfig(key, value);

  /// 读取通用配置
  String? getConfig(String key) => _db.getConfig(key);

  /// 保存最后阅读的书籍 ID
  void saveLastBookId(String bookId) => _db.saveConfig(keyLastBookId, bookId);

  /// 获取最后阅读的书籍 ID
  String? getLastBookId() => _db.getConfig(keyLastBookId);

  /// 导出所有设置
  Map<String, String?> exportAllSettings() {
    return {
      keyApiConfig: _db.getConfig(keyApiConfig),
      keyReadingPrefs: _db.getConfig(keyReadingPrefs),
      keyThemeMode: _db.getConfig(keyThemeMode),
      keyLastBookId: _db.getConfig(keyLastBookId),
    };
  }

  /// 导入设置
  void importSettings(Map<String, String> settings) {
    settings.forEach((key, value) {
      _db.saveConfig(key, value);
    });
  }
}

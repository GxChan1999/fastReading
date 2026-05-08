import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

/// 加密工具类 — 用于 API 密钥等敏感数据加密存储
class EncryptionUtils {
  EncryptionUtils._();

  static final Random _random = Random.secure();

  /// 生成设备唯一标识哈希（用于派生加密密钥）
  static Future<String> _getDeviceId() async {
    // MVP 阶段使用固定种子 + 运行时标识组合
    // 生产环境应使用 device_info_plus 获取设备真实唯一标识
    final info = <String>[
      'reading_efficiency_app_v1',
      // 可在此添加设备指纹信息
    ];
    return sha256.convert(utf8.encode(info.join('|'))).toString();
  }

  /// 从设备 ID 派生 AES 密钥（32 字节）
  static Future<encrypt.Key> _deriveKey() async {
    final deviceId = await _getDeviceId();
    final hash = sha256.convert(utf8.encode(deviceId));
    return encrypt.Key.fromUtf8(hash.toString().substring(0, 32));
  }

  /// AES 加密
  static Future<String> encryptText(String plainText) async {
    if (plainText.isEmpty) return '';

    final key = await _deriveKey();
    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));

    final encrypted = encrypter.encrypt(plainText, iv: iv);
    // 返回格式: base64(iv):base64(encryptedData)
    return '${base64Encode(iv.bytes)}:${encrypted.base64}';
  }

  /// AES 解密
  static Future<String> decryptText(String encryptedText) async {
    if (encryptedText.isEmpty) return '';

    final parts = encryptedText.split(':');
    if (parts.length != 2) {
      throw ArgumentError('加密数据格式无效');
    }

    final key = await _deriveKey();
    final iv = encrypt.IV(base64Decode(parts[0]));
    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));

    return encrypter.decrypt64(parts[1], iv: iv);
  }

  /// 计算文件 MD5 哈希
  static Future<String> calculateMd5(List<int> bytes) async {
    return md5.convert(bytes).toString();
  }

  /// 计算字符串 SHA256 哈希
  static String sha256Hash(String input) {
    return sha256.convert(utf8.encode(input)).toString();
  }
}

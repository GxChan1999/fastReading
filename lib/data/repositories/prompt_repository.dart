import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:crypto/crypto.dart';
import '../database/database_helper.dart';
import '../models/prompt_rule.dart';

/// Prompt 规则仓库
class PromptRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final Uuid _uuid = const Uuid();

  /// 创建 Prompt 规则
  PromptRule createRule({
    required String name,
    required String filePath,
    required String content,
    bool isDefault = false,
    bool isBuiltin = false,
  }) {
    final now = DateTime.now();
    final hash = _calculateHash(content);
    final rule = PromptRule(
      id: _uuid.v4(),
      name: name,
      filePath: filePath,
      content: content,
      contentHash: hash,
      isDefault: isDefault,
      isBuiltin: isBuiltin,
      createdAt: now,
      updatedAt: now,
    );
    _db.insertPromptRule(rule);
    return rule;
  }

  /// 获取所有规则
  List<PromptRule> getAllRules() => _db.getAllPromptRules();

  /// 获取默认规则
  PromptRule? getDefaultRule() => _db.getDefaultPromptRule();

  /// 更新规则内容
  PromptRule updateRule(PromptRule rule, String newContent) {
    final updated = rule.copyWith(
      content: newContent,
      contentHash: _calculateHash(newContent),
      updatedAt: DateTime.now(),
    );
    _db.updatePromptRule(updated);
    return updated;
  }

  /// 设为默认
  void setAsDefault(String ruleId) {
    final rules = _db.getAllPromptRules();
    for (final rule in rules) {
      final updated = rule.copyWith(
        isDefault: rule.id == ruleId,
        updatedAt: DateTime.now(),
      );
      _db.updatePromptRule(updated);
    }
  }

  /// 删除规则
  void deleteRule(String id) => _db.deletePromptRule(id);

  /// 计算内容哈希
  String _calculateHash(String content) {
    return sha256.convert(utf8.encode(content)).toString();
  }

  /// 检查内容是否变更
  bool hasChanged(String content, String hash) {
    return _calculateHash(content) != hash;
  }
}

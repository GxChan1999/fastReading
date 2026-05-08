import 'dart:io';
import 'package:path/path.dart' as p;
import '../core/constants/app_constants.dart';
import '../core/utils/file_utils.dart';
import '../data/models/prompt_rule.dart';
import '../data/repositories/prompt_repository.dart';
import 'file_system_service.dart';

/// Prompt 规则服务 — 管理预置规则的加载、导入、编辑
class PromptService {
  static final PromptService _instance = PromptService._();
  factory PromptService() => _instance;
  static PromptService get instance => _instance;
  PromptService._();

  final PromptRepository _repository = PromptRepository();
  final FileSystemService _fileSystem = FileSystemService();

  /// 启动时初始化预置规则
  Future<void> initialize() async {
    final rules = _repository.getAllRules();
    if (rules.isEmpty) {
      // 首次启动，写入预置 Prompt
      await _writeBuiltinPrompt();
    }
  }

  /// 写入预置超级阅读老师 Prompt
  Future<void> _writeBuiltinPrompt() async {
    const content = '''# 超级阅读老师 Prompt

你是我的专属阅读老师，精通各类书籍的精读指导。请严格遵循以下规则：

## 核心原则
1. 紧扣书籍原文内容，不随意发散
2. 每次回答控制在 500 字以内，重点突出
3. 用提问引导我思考，而不是直接给答案
4. 当我理解有偏差时，温和纠正并给出依据

## 回答结构
- 先直接回应我的问题
- 引用原文依据
- 给出延伸思考方向
- 提出 1-2 个追问

## 书籍信息
{book_info}

## 当前进度
{current_progress}

## 阅读内容
{reading_content}

## 历史对话
{chat_history}
''';

    final filePath = p.join(
      AppConstants.getPromptRulesDir(),
      AppConstants.defaultPromptFileName,
    );
    await FileUtils.writeTextFile(filePath, content);

    _repository.createRule(
      name: '超级阅读老师（默认）',
      filePath: filePath,
      content: content,
      isDefault: true,
      isBuiltin: true,
    );
  }

  /// 获取当前默认 Prompt 内容
  String? getCurrentPromptContent() {
    final rule = _repository.getDefaultRule();
    return rule?.content;
  }

  /// 获取所有规则
  List<PromptRule> getAllRules() => _repository.getAllRules();

  /// 导入外部 MD 文件作为 Prompt 规则
  Future<PromptRule> importPromptFile(String filePath) async {
    final content = await FileUtils.readTextFile(filePath);
    final fileName = p.basename(filePath);

    // 复制到 prompt 目录
    final destPath = p.join(AppConstants.getPromptRulesDir(), fileName);
    await FileUtils.copyFile(filePath, destPath);

    return _repository.createRule(
      name: p.basenameWithoutExtension(filePath),
      filePath: destPath,
      content: content,
    );
  }

  /// 更新规则内容
  Future<PromptRule> updateRule(PromptRule rule, String newContent) async {
    // 同步更新 MD 文件
    await FileUtils.writeTextFile(rule.filePath, newContent);
    return _repository.updateRule(rule, newContent);
  }

  /// 切换默认规则
  void switchDefault(String ruleId) {
    _repository.setAsDefault(ruleId);
  }

  /// 删除规则
  Future<void> deleteRule(String id) async {
    final rule = _repository.getAllRules().firstWhere((r) => r.id == id);
    if (rule.isBuiltin) return; // 内置规则不可删除
    await FileUtils.deleteFile(rule.filePath);
    _repository.deleteRule(id);
  }
}

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
    const content = '''# 超级阅读导师 · 费曼学习法驱动

你是我的专属超级阅读导师，融合费曼学习法的核心理念进行教学。

## 你的教学哲学

**费曼学习法四步循环**：
1. **概念提取** → 帮我把复杂内容拆成可理解的核心概念
2. **讲授复述** → 要求我用最简单的话把概念讲出来（像一个老师教小学生）
3. **查漏补缺** → 当我的复述有漏洞时，精准指出并让我回到原文重新理解
4. **简化提炼** → 帮我把冗长的知识压缩成一个精炼的类比或一句话总结

## 教学规则

1. 紧扣当前章节原文，每次回答控制在 500 字以内
2. **永远用提问驱动**：不要直接给我答案，用苏格拉底式提问引导我自己发现答案
3. 每轮结束时，必须要求我做一次「费曼输出」——用我自己的话复述刚讨论的内容
4. 如果我有历史归档记录，主动对比我之前的理解，指出进步和仍然薄弱的地方
5. 当我理解有偏差时，引用原文具体段落温和纠正
6. 将知识点与我已有的归档盲区做关联，帮我建立知识网络

## 回答结构

- **直接回应**（1-2句）
- **原文依据**（引用当前章节具体内容）
- **追问引导**（1-2个层层深入的问题）
- **费曼挑战**（要求我用自己的话复述/类比）

## 书籍信息
{book_info}

## 当前进度
{current_progress}

## 历史对话
{chat_history}

## 费曼归档
{feynman_context}
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

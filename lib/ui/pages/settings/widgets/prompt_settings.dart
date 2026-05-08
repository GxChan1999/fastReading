import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/prompt_rule.dart';
import '../../../../services/prompt_service.dart';

/// Prompt 规则管理组件
class PromptSettings extends StatefulWidget {
  const PromptSettings({super.key});

  @override
  _PromptSettingsState createState() => _PromptSettingsState();
}

class _PromptSettingsState extends State<PromptSettings> {
  final PromptService _promptService = PromptService();
  List<PromptRule> _rules = [];

  @override
  void initState() {
    super.initState();
    _loadRules();
  }

  void _loadRules() {
    setState(() {
      _rules = _promptService.getAllRules();
    });
  }

  Future<void> _importPromptFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['md'],
      );
      if (result == null || result.files.isEmpty) return;

      await _promptService.importPromptFile(result.files.single.path!);
      _loadRules();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Prompt 规则导入成功')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('导入失败: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _editRule(PromptRule rule) {
    final controller = TextEditingController(text: rule.content);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('编辑: ${rule.name}'),
        content: SizedBox(
          width: 600,
          height: 400,
          child: TextField(
            controller: controller,
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _promptService.updateRule(rule, controller.text);
              _loadRules();
              Navigator.pop(ctx);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Prompt 规则管理',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 20),
                  tooltip: '导入 MD 文件',
                  onPressed: _importPromptFile,
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              '管理 AI 对话的系统 Prompt 规则',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            if (_rules.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: Text('暂无自定义规则')),
              )
            else
              ..._rules.map((rule) => ListTile(
                    dense: true,
                    title: Text(rule.name, style: const TextStyle(fontSize: 14)),
                    subtitle: Text(
                      rule.isDefault ? '默认规则' : (rule.isBuiltin ? '内置规则' : ''),
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!rule.isDefault)
                          TextButton(
                            onPressed: () {
                              _promptService.switchDefault(rule.id);
                              _loadRules();
                            },
                            child: const Text('设为默认', style: TextStyle(fontSize: 12)),
                          ),
                        IconButton(
                          icon: const Icon(Icons.edit, size: 18),
                          onPressed: () => _editRule(rule),
                        ),
                        if (!rule.isBuiltin)
                          IconButton(
                            icon: const Icon(Icons.delete, size: 18, color: AppTheme.errorColor),
                            onPressed: () {
                              _promptService.deleteRule(rule.id);
                              _loadRules();
                            },
                          ),
                      ],
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/app_config.dart';
import '../../../providers/settings_provider.dart';
import '../../../services/export_service.dart';
import '../../../services/file_system_service.dart';
import 'widgets/api_key_settings.dart';
import 'widgets/prompt_settings.dart';
import 'widgets/reading_preferences.dart';

/// 全局设置页
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsState = ref.watch(settingsProvider);

    if (!settingsState.isInitialized) {
      return Scaffold(
        appBar: AppBar(title: const Text('设置')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // API 配置
          ApiKeySettings(
            config: settingsState.apiConfig,
            onSave: (config) {
              ref.read(settingsProvider.notifier).saveApiConfig(config);
            },
          ),
          const SizedBox(height: 16),

          // Prompt 规则管理
          const PromptSettings(),
          const SizedBox(height: 16),

          // 阅读排版
          ReadingPreferencesSettings(
            prefs: settingsState.readingPrefs,
            onChanged: (prefs) {
              ref.read(settingsProvider.notifier).saveReadingPrefs(prefs);
            },
          ),
          const SizedBox(height: 16),

          // 数据管理
          _buildDataManagementSection(context),
          const SizedBox(height: 16),

          // 关于
          _buildAboutSection(context),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildDataManagementSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '数据管理 · 迁移',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            const Text(
              '备份后可迁移到新版本或另一台设备',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.backup, color: AppTheme.primaryColor),
              title: const Text('完整备份（含归档）'),
              subtitle: const Text('导出 JSON 备份文件，含书籍、对话、费曼归档'),
              onTap: () async {
                try {
                  final path = await ExportService.instance.backupFullData();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('备份成功: $path')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('备份失败: $e'),
                        backgroundColor: AppTheme.errorColor,
                      ),
                    );
                  }
                }
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.restore, color: AppTheme.successColor),
              title: const Text('从备份恢复'),
              subtitle: const Text('选择 JSON 备份文件，恢复所有数据'),
              onTap: () async {
                try {
                  final result = await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['json'],
                  );
                  if (result == null || result.files.isEmpty) return;

                  final stats = await ExportService.instance
                      .restoreFromBackup(result.files.single.path!);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '恢复完成：${stats['books']}本书、${stats['chapters']}章、'
                          '${stats['conversations']}轮对话、${stats['messages']}条消息、'
                          '${stats['sessions']}条归档、${stats['difficulties']}条疑难、'
                          '${stats['configs']}项配置',
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('恢复失败: $e'),
                        backgroundColor: AppTheme.errorColor,
                      ),
                    );
                  }
                }
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.file_download, color: AppTheme.primaryColor),
              title: const Text('导出阅读笔记'),
              subtitle: const Text('生成 MD 格式笔记文件'),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('请在书籍页面中使用导出功能')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '关于',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            const ListTile(
              leading: Icon(Icons.info_outline, color: AppTheme.textSecondary),
              title: Text('阅读提效对话 APP'),
              subtitle: Text('版本 1.0.0 · 纯本地离线运行'),
            ),
          ],
        ),
      ),
    );
  }
}

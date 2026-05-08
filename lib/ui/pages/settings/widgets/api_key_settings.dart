import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/app_config.dart';

/// API 密钥配置组件
class ApiKeySettings extends StatefulWidget {
  final ApiConfig config;
  final ValueChanged<ApiConfig> onSave;

  const ApiKeySettings({
    super.key,
    required this.config,
    required this.onSave,
  });

  @override
  _ApiKeySettingsState createState() => _ApiKeySettingsState();
}

class _ApiKeySettingsState extends State<ApiKeySettings> {
  late TextEditingController _apiKeyController;
  late TextEditingController _baseUrlController;
  late TextEditingController _modelController;
  late String _provider;
  bool _showKey = false;
  bool _thinkingEnabled = false;

  @override
  void initState() {
    super.initState();
    _apiKeyController = TextEditingController(text: widget.config.apiKey);
    _baseUrlController = TextEditingController(text: widget.config.baseUrl);
    _modelController = TextEditingController(text: widget.config.model);
    _provider = widget.config.provider;
    _thinkingEnabled = widget.config.thinkingEnabled;
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _baseUrlController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  void _save() {
    widget.onSave(ApiConfig(
      provider: _provider,
      apiKey: _apiKeyController.text.trim(),
      baseUrl: _baseUrlController.text.trim(),
      model: _modelController.text.trim(),
      thinkingEnabled: _thinkingEnabled,
    ));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('API 配置已保存')),
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
            const Text(
              'API 配置',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            const Text(
              '直连大模型 API，密钥加密存储',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),

            // 提供商选择
            DropdownButtonFormField<String>(
              value: _provider,
              decoration: const InputDecoration(
                labelText: 'API 提供商',
                isDense: true,
              ),
              items: const [
                DropdownMenuItem(value: 'openai', child: Text('OpenAI')),
                DropdownMenuItem(value: 'doubao', child: Text('豆包')),
                DropdownMenuItem(value: 'claude', child: Text('Claude')),
                DropdownMenuItem(value: 'zhipu', child: Text('智谱 GLM')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _provider = value;
                    if (value == 'zhipu') {
                      _baseUrlController.text = 'https://open.bigmodel.cn/api/paas/v4';
                      _modelController.text = 'glm-4.7-flash';
                    }
                  });
                }
              },
            ),
            const SizedBox(height: 12),

            // API Key
            TextField(
              controller: _apiKeyController,
              obscureText: !_showKey,
              decoration: InputDecoration(
                labelText: 'API Key',
                isDense: true,
                suffixIcon: IconButton(
                  icon: Icon(_showKey ? Icons.visibility_off : Icons.visibility, size: 18),
                  onPressed: () => setState(() => _showKey = !_showKey),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Base URL
            TextField(
              controller: _baseUrlController,
              decoration: const InputDecoration(
                labelText: 'Base URL',
                isDense: true,
                hintText: 'https://api.openai.com/v1',
              ),
            ),
            const SizedBox(height: 12),

            // 模型
            TextField(
              controller: _modelController,
              decoration: const InputDecoration(
                labelText: '模型名称',
                isDense: true,
                hintText: 'gpt-4o',
              ),
            ),
            const SizedBox(height: 12),

            // Thinking 深度推理（仅智谱 GLM 有效）
            if (_provider == 'zhipu')
              Column(
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('深度推理模式', style: TextStyle(fontSize: 14)),
                    subtitle: const Text(
                      '启用 thinking，模型在回答前进行深度思考',
                      style: TextStyle(fontSize: 12),
                    ),
                    value: _thinkingEnabled,
                    onChanged: (v) => setState(() => _thinkingEnabled = v),
                    dense: true,
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                child: const Text('保存配置'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

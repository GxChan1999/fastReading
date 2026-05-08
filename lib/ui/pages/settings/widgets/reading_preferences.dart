import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/app_config.dart';

/// 阅读排版设置组件
class ReadingPreferencesSettings extends StatefulWidget {
  final ReadingPreferences prefs;
  final ValueChanged<ReadingPreferences> onChanged;

  const ReadingPreferencesSettings({
    super.key,
    required this.prefs,
    required this.onChanged,
  });

  @override
  _ReadingPreferencesSettingsState createState() =>
      _ReadingPreferencesSettingsState();
}

class _ReadingPreferencesSettingsState extends State<ReadingPreferencesSettings> {
  late double _fontSize;
  late double _lineHeight;

  @override
  void initState() {
    super.initState();
    _fontSize = widget.prefs.fontSize;
    _lineHeight = widget.prefs.lineHeight;
  }

  void _update() {
    widget.onChanged(ReadingPreferences(
      fontSize: _fontSize,
      lineHeight: _lineHeight,
    ));
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
              '阅读排版',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),

            // 字号
            Row(
              children: [
                const Text('字号', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 12),
                Expanded(
                  child: Slider(
                    value: _fontSize,
                    min: 12,
                    max: 32,
                    divisions: 10,
                    label: '${_fontSize.toInt()}',
                    onChanged: (v) {
                      setState(() => _fontSize = v);
                      _update();
                    },
                  ),
                ),
                SizedBox(
                  width: 40,
                  child: Text(
                    '${_fontSize.toInt()}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),

            // 行高
            Row(
              children: [
                const Text('行距', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 12),
                Expanded(
                  child: Slider(
                    value: _lineHeight,
                    min: 1.2,
                    max: 2.5,
                    divisions: 6,
                    label: _lineHeight.toStringAsFixed(1),
                    onChanged: (v) {
                      setState(() => _lineHeight = v);
                      _update();
                    },
                  ),
                ),
                SizedBox(
                  width: 40,
                  child: Text(
                    _lineHeight.toStringAsFixed(1),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            // 预览
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.dividerColor),
              ),
              child: Text(
                '预览：这是阅读内容的显示效果。调整字号和行距以获得最佳阅读体验。',
                style: TextStyle(
                  fontSize: _fontSize,
                  height: _lineHeight,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

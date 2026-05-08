import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/app_config.dart';

/// 书籍内容渲染区
class BookContentView extends StatelessWidget {
  final String content;
  final ReadingPreferences prefs;
  final String title;
  final double scrollPosition;
  final Function(String selectedText, {GlobalKey? key})? onTextSelected;

  const BookContentView({
    super.key,
    required this.content,
    required this.prefs,
    this.title = '',
    this.scrollPosition = 0.0,
    this.onTextSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (content.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.menu_book, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              title.isEmpty ? '选择章节开始阅读' : '内容加载中...',
              style: TextStyle(fontSize: 16, color: Colors.grey[400]),
            ),
          ],
        ),
      );
    }

    return Container(
      color: prefs.backgroundColor,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(
          MediaQuery.of(context).size.width > 600 ? 32 : 16,
        ),
        child: SelectableText.rich(
          TextSpan(
            text: content,
            style: TextStyle(
              fontSize: prefs.fontSize,
              height: prefs.lineHeight,
              color: prefs.textColor,
              fontFamily: prefs.useSystemFont ? null : 'serif',
            ),
          ),
        ),
      ),
    );
  }
}

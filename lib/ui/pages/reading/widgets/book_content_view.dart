import 'package:flutter/material.dart';
import '../../../../data/models/app_config.dart';

/// 书籍内容渲染区 — PageView 翻页模式
class BookContentView extends StatefulWidget {
  final String content;
  final ReadingPreferences prefs;
  final String title;
  final PageController? pageController;
  final ValueChanged<int>? onPageChanged;

  const BookContentView({
    super.key,
    required this.content,
    required this.prefs,
    this.title = '',
    this.pageController,
    this.onPageChanged,
  });

  @override
  State<BookContentView> createState() => _BookContentViewState();
}

class _BookContentViewState extends State<BookContentView> {
  final List<String> _pages = [];
  int _currentPage = 0;
  double? _lastWidth;
  double? _lastHeight;
  PageController? _internalController;

  PageController get _controller =>
      widget.pageController ?? (_internalController ??= PageController());

  @override
  void didUpdateWidget(BookContentView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.content != widget.content ||
        oldWidget.prefs.fontSize != widget.prefs.fontSize ||
        oldWidget.prefs.lineHeight != widget.prefs.lineHeight) {
      _pages.clear();
      _lastWidth = null;
      _lastHeight = null;
    }
  }

  @override
  void dispose() {
    _internalController?.dispose();
    super.dispose();
  }

  void _paginate(double width, double height, String text) {
    if (text.isEmpty) {
      _pages.clear();
      return;
    }

    final textStyle = TextStyle(
      fontSize: widget.prefs.fontSize,
      height: widget.prefs.lineHeight,
      color: widget.prefs.textColor,
      fontFamily: widget.prefs.useSystemFont ? null : 'serif',
    );

    final padding = width > 600 ? 64.0 : 32.0;
    final pageWidth = width - padding;
    final pageHeight = height - padding;

    if (pageWidth <= 0 || pageHeight <= 0) {
      _pages.clear();
      _pages.add(text);
      return;
    }

    // 估算每页字符数：用行高和字体大小推算
    final lineHeightEst = widget.prefs.fontSize * widget.prefs.lineHeight;
    final linesPerPage = (pageHeight / lineHeightEst).floor();
    // 中文字符宽度约等于字体大小
    final charsPerLine = (pageWidth / widget.prefs.fontSize).floor();
    var charsPerPage = (linesPerPage * charsPerLine).clamp(100, 10000);

    final newPages = <String>[];
    var offset = 0;

    final painter = TextPainter(textDirection: TextDirection.ltr);

    while (offset < text.length) {
      // 取估计长度的文本，用 TextPainter 精确测量
      var end = (offset + charsPerPage).clamp(0, text.length);
      var candidate = text.substring(offset, end);

      painter.text = TextSpan(text: candidate, style: textStyle);
      painter.layout(maxWidth: pageWidth);

      // 如果超出页面高度，减少字符
      if (painter.height > pageHeight) {
        var lo = offset;
        var hi = end;
        while (lo < hi - 1) {
          final mid = (lo + hi) ~/ 2;
          painter.text =
              TextSpan(text: text.substring(offset, mid), style: textStyle);
          painter.layout(maxWidth: pageWidth);
          if (painter.height <= pageHeight) {
            lo = mid;
          } else {
            hi = mid;
          }
        }
        end = lo;
        // 回退到最近的自然断点（段落末尾）
        final chunk = text.substring(offset, end);
        final lastParaBreak = chunk.lastIndexOf('\n\n');
        if (lastParaBreak > chunk.length ~/ 3) {
          end = offset + lastParaBreak;
        }
      } else if (painter.height < pageHeight * 0.3 && end < text.length) {
        // 内容太少，尝试多取一些
        painter.text = TextSpan(
            text: text.substring(offset, (offset + charsPerPage * 2).clamp(0, text.length)),
            style: textStyle);
        painter.layout(maxWidth: pageWidth);
        if (painter.height <= pageHeight) {
          charsPerPage = (charsPerPage * 1.5).round();
        }
      }

      final pageText = text.substring(offset, end).trimRight();
      if (pageText.isNotEmpty) {
        newPages.add(pageText);
      }
      offset = end;
    }

    _pages
      ..clear()
      ..addAll(newPages.isEmpty ? [text] : newPages);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.content.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.menu_book, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              widget.title.isEmpty ? '选择章节开始阅读' : '内容加载中...',
              style: TextStyle(fontSize: 16, color: Colors.grey[400]),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        if (_pages.isEmpty || _lastWidth != w || _lastHeight != h) {
          _lastWidth = w;
          _lastHeight = h;
          _paginate(w, h, widget.content);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_controller.hasClients) {
              _controller.jumpToPage(0);
            }
          });
        }

        if (_pages.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return Stack(
          children: [
            Container(
              color: widget.prefs.backgroundColor,
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (page) {
                  setState(() => _currentPage = page);
                  widget.onPageChanged?.call(page);
                },
                itemBuilder: (context, index) {
                  return Container(
                    padding: EdgeInsets.all(w > 600 ? 32 : 16),
                    child: SelectableText(
                      _pages[index],
                      style: TextStyle(
                        fontSize: widget.prefs.fontSize,
                        height: widget.prefs.lineHeight,
                        color: widget.prefs.textColor,
                        fontFamily: widget.prefs.useSystemFont ? null : 'serif',
                      ),
                    ),
                  );
                },
              ),
            ),
            // 页数指示器
            Positioned(
              bottom: 8,
              right: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_currentPage + 1} / ${_pages.length}',
                  style: const TextStyle(fontSize: 12, color: Colors.white),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

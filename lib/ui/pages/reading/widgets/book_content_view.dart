import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../../../../core/theme/app_theme.dart';
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
  bool _isHovering = false;
  bool _isPaginating = false;

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

  void _schedulePaginate(double width, double height, String text) {
    if (_isPaginating) return;
    _isPaginating = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        _isPaginating = false;
        return;
      }
      _paginate(width, height, text);
      _isPaginating = false;
      if (mounted) {
        setState(() {});
        if (_controller.hasClients && _pages.isNotEmpty) {
          _controller.jumpToPage(0);
        }
      }
    });
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

    final lineHeight = widget.prefs.fontSize * widget.prefs.lineHeight;
    final linesPerPage = (pageHeight / lineHeight).floor().clamp(5, 500);

    final painter = TextPainter(textDirection: TextDirection.ltr);
    painter.text = TextSpan(text: text, style: textStyle);
    painter.layout(maxWidth: pageWidth);

    // 获取所有行的边界
    final lineMetrics = painter.computeLineMetrics();
    final newPages = <String>[];

    for (var i = 0; i < lineMetrics.length; i += linesPerPage) {
      final startLine = lineMetrics[i];
      final endLineIdx = (i + linesPerPage - 1).clamp(0, lineMetrics.length - 1);
      final endLine = lineMetrics[endLineIdx];

      // 获取这段文本的字符范围
      final startChar = _findCharOffsetForLine(
          painter, text, i, startLine, searchForward: true);
      var endChar = _findCharOffsetForLine(
          painter, text, endLineIdx, endLine, searchForward: false);

      // 回退到自然段落断点
      if (endChar < text.length) {
        final searchStart = (endChar - text.length ~/ 20).clamp(startChar, endChar);
        final lastBreak = text.lastIndexOf('\n\n', endChar);
        if (lastBreak > searchStart && lastBreak > startChar) {
          endChar = lastBreak;
        } else {
          final lastSingle = text.lastIndexOf('\n', endChar);
          if (lastSingle > searchStart && lastSingle > startChar + 10) {
            endChar = lastSingle;
          }
        }
      }

      endChar = endChar.clamp(startChar + 1, text.length);
      final pageText = text.substring(startChar, endChar).trimRight();
      if (pageText.isNotEmpty) {
        newPages.add(pageText);
      }
    }

    _pages
      ..clear()
      ..addAll(newPages.isEmpty ? [text] : newPages);
  }

  /// 根据行号查找对应的字符偏移量
  int _findCharOffsetForLine(
    TextPainter painter,
    String text,
    int lineIndex,
    LineMetrics lineMetric, {
    required bool searchForward,
  }) {
    // 用 getPositionForOffset 定位
    final y = lineMetric.baseline - lineMetric.height / 2;
    final position =
        painter.getPositionForOffset(Offset(lineMetric.left + 1, y));
    return position.offset;
  }

  Widget _buildPageArrow({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppTheme.cardColor.withOpacity(0.85),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppTheme.textPrimary, size: 22),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.content.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.menu_book, size: 48, color: AppTheme.textHint),
            const SizedBox(height: 16),
            Text(
              widget.title.isEmpty ? '选择章节开始阅读' : '内容加载中...',
              style: const TextStyle(fontSize: 16, color: AppTheme.textSecondary),
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
          _schedulePaginate(w, h, widget.content);
        }

        if (_pages.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return MouseRegion(
          onEnter: (_) => setState(() => _isHovering = true),
          onExit: (_) => setState(() => _isHovering = false),
          child: Listener(
            onPointerSignal: (event) {
              if (event is PointerScrollEvent) {
                final dy = event.scrollDelta.dy;
                if (dy > 0 && _currentPage < _pages.length - 1) {
                  _controller.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                } else if (dy < 0 && _currentPage > 0) {
                  _controller.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
              }
            },
            child: Stack(
              children: [
                Container(
                  color: widget.prefs.backgroundColor,
                  child: SelectionArea(
                    child: RepaintBoundary(
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
                            child: Text(
                              _pages[index],
                              style: TextStyle(
                                fontSize: widget.prefs.fontSize,
                                height: widget.prefs.lineHeight,
                                color: widget.prefs.textColor,
                                fontFamily:
                                    widget.prefs.useSystemFont ? null : 'serif',
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                // 鼠标悬停时的翻页箭头
                if (_isHovering && _pages.length > 1) ...[
                  if (_currentPage > 0)
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      child: _buildPageArrow(
                        icon: Icons.chevron_left,
                        onTap: () => _controller.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        ),
                      ),
                    ),
                  if (_currentPage < _pages.length - 1)
                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      child: _buildPageArrow(
                        icon: Icons.chevron_right,
                        onTap: () => _controller.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        ),
                      ),
                    ),
                ],
                // 页数指示器
                Positioned(
                  bottom: 8,
                  right: 16,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.cardColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_currentPage + 1} / ${_pages.length}',
                      style:
                          const TextStyle(fontSize: 12, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

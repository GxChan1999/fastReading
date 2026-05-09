import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/platform_utils.dart';
import '../../../../data/models/book.dart';

/// 书籍卡片组件
class BookCard extends StatefulWidget {
  final Book book;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const BookCard({
    super.key,
    required this.book,
    required this.onTap,
    this.onDelete,
  });

  @override
  State<BookCard> createState() => _BookCardState();
}

class _BookCardState extends State<BookCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            InkWell(
              onTap: widget.onTap,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildCoverArea()),
                    const SizedBox(height: 12),
                    Text(
                      widget.book.name,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (widget.book.author.isNotEmpty)
                      Text(
                        widget.book.author,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildFormatChip(context),
                        const Spacer(),
                        _buildProgressText(),
                      ],
                    ),
                    if (widget.book.progress > 0) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: widget.book.progress,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            widget.book.status == ReadingStatus.finished
                                ? AppTheme.successColor
                                : AppTheme.primaryColor,
                          ),
                          minHeight: 3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (widget.onDelete != null)
              Positioned(
                top: 4,
                right: 4,
                child: AnimatedOpacity(
                  opacity: _isHovered ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 150),
                  child: Material(
                    color: Colors.transparent,
                    child: IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black54,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _isHovered ? widget.onDelete : null,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverArea() {
    final coverPath = widget.book.coverPath;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: coverPath != null
          ? Image.file(
              File(coverPath),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildPlaceholderIcon(),
            )
          : _buildPlaceholderIcon(),
    );
  }

  Widget _buildPlaceholderIcon() {
    return const Center(
      child: Icon(
        Icons.menu_book,
        size: 48,
        color: Colors.black26,
      ),
    );
    // Simplify: use same icon for all formats since it's just a placeholder
  }

  Widget _buildFormatChip(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        widget.book.format.name.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildProgressText() {
    if (widget.book.status == ReadingStatus.finished) {
      return const Text(
        '已读完',
        style: TextStyle(fontSize: 12, color: AppTheme.successColor),
      );
    }
    if (widget.book.progress > 0) {
      return Text(
        '${(widget.book.progress * 100).toStringAsFixed(0)}%',
        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
      );
    }
    return const Text(
      '未开始',
      style: TextStyle(fontSize: 12, color: AppTheme.textHint),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/platform_utils.dart';

/// 导入书籍按钮
class ImportButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isDragActive;

  const ImportButton({
    super.key,
    required this.onTap,
    this.isDragActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        decoration: BoxDecoration(
          color: isDragActive
              ? AppTheme.primaryColor.withOpacity(0.08)
              : Colors.grey.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDragActive
                ? AppTheme.primaryColor
                : Colors.grey.withOpacity(0.3),
            width: isDragActive ? 2 : 1,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add_circle_outline,
              size: 48,
              color: isDragActive
                  ? AppTheme.primaryColor
                  : Colors.grey[400],
            ),
            const SizedBox(height: 12),
            Text(
              '导入电子书',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDragActive
                    ? AppTheme.primaryColor
                    : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              PlatformUtils.filePickerHint,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '支持 EPUB / PDF / TXT 格式',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

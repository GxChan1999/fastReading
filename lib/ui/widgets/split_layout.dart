import 'package:flutter/material.dart';
import '../../core/utils/platform_utils.dart';

/// 分屏布局组件 — PC 端左右分屏，移动端上下分屏
class SplitLayout extends StatelessWidget {
  final Widget leftPanel;
  final Widget rightPanel;
  final double ratio; // 左/上 面板占比
  final double? minLeftWidth;
  final double? minRightWidth;

  const SplitLayout({
    super.key,
    required this.leftPanel,
    required this.rightPanel,
    this.ratio = 0.5,
    this.minLeftWidth,
    this.minRightWidth,
  });

  @override
  Widget build(BuildContext context) {
    if (PlatformUtils.isWideScreen(context)) {
      return _buildHorizontalSplit(context);
    }
    return _buildVerticalSplit(context);
  }

  Widget _buildHorizontalSplit(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final leftWidth = ((totalWidth * ratio).clamp(
          minLeftWidth ?? 300,
          totalWidth - (minRightWidth ?? 300),
        )).toDouble();

        return Row(
          children: [
            SizedBox(width: leftWidth, child: leftPanel),
            _buildDivider(vertical: true),
            Expanded(child: rightPanel),
          ],
        );
      },
    );
  }

  Widget _buildVerticalSplit(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalHeight = constraints.maxHeight;
        final topHeight = totalHeight * ratio;

        return Column(
          children: [
            SizedBox(height: topHeight, child: leftPanel),
            _buildDivider(vertical: false),
            Expanded(child: rightPanel),
          ],
        );
      },
    );
  }

  Widget _buildDivider({required bool vertical}) {
    return MouseRegion(
      cursor: vertical ? SystemMouseCursors.resizeColumn : SystemMouseCursors.resizeRow,
      child: Container(
        width: vertical ? 4 : double.infinity,
        height: vertical ? double.infinity : 4,
        color: Colors.transparent,
        child: Center(
          child: Container(
            width: vertical ? 1 : 40,
            height: vertical ? 40 : 1,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/reading_snapshot.dart';

/// 时间线视图
class TimelineView extends StatelessWidget {
  final List<ReadingSnapshot> snapshots;
  final ValueChanged<ReadingSnapshot> onTap;

  const TimelineView({
    super.key,
    required this.snapshots,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (snapshots.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text('暂无阅读记录', style: TextStyle(color: Colors.grey[400])),
          ],
        ),
      );
    }

    // 按日期分组
    final grouped = <String, List<ReadingSnapshot>>{};
    for (final snapshot in snapshots) {
      final dateKey = DateFormat('yyyy-MM-dd').format(snapshot.createdAt);
      grouped.putIfAbsent(dateKey, () => []).add(snapshot);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: grouped.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 16, bottom: 8),
              child: Text(
                entry.key,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[500],
                ),
              ),
            ),
            ...entry.value.map((snapshot) => _buildTimelineItem(context, snapshot)),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildTimelineItem(BuildContext context, ReadingSnapshot snapshot) {
    final time = DateFormat('HH:mm').format(snapshot.createdAt);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: () => onTap(snapshot),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.menu_book, size: 18, color: AppTheme.primaryColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      snapshot.currentFlowState ?? '阅读位置',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    if (snapshot.notes != null)
                      Text(
                        snapshot.notes!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                  ],
                ),
              ),
              Text(
                time,
                style: const TextStyle(fontSize: 12, color: AppTheme.textHint),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, size: 18, color: AppTheme.textHint),
            ],
          ),
        ),
      ),
    );
  }
}

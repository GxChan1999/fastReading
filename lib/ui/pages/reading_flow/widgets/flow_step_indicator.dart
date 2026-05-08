import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/reading_flow_service.dart';

/// 精读流程步骤指示器
class FlowStepIndicator extends StatelessWidget {
  final List<ReadingFlowState> steps;
  final ReadingFlowState currentStep;

  const FlowStepIndicator({
    super.key,
    required this.steps,
    required this.currentStep,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (index) {
          if (index.isOdd) return _buildConnector(index ~/ 2);
          final stepIndex = index ~/ 2;
          final step = steps[stepIndex];
          final isCurrent = step == currentStep;
          final isCompleted = step.index < currentStep.index;

          return _buildStepItem(step, isCurrent, isCompleted);
        }),
      ),
    );
  }

  Widget _buildStepItem(ReadingFlowState step, bool isCurrent, bool isCompleted) {
    final color = isCurrent
        ? AppTheme.primaryColor
        : isCompleted
            ? AppTheme.successColor
            : Colors.grey[300]!;

    return GestureDetector(
      onTap: () {
        // 由父组件处理跳转
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isCurrent
                    ? color
                    : isCompleted
                        ? color
                        : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : Text(
                        '${step.index + 1}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isCurrent ? Colors.white : color,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              step.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                color: isCurrent ? AppTheme.primaryColor : Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnector(int index) {
    final isCompleted = index < currentStep.index;
    return Container(
      width: 24,
      height: 2,
      margin: const EdgeInsets.only(bottom: 20),
      color: isCompleted ? AppTheme.successColor : Colors.grey[300],
    );
  }
}

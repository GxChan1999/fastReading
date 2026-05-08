import 'package:equatable/equatable.dart';

/// Prompt 规则模型
class PromptRule extends Equatable {
  final String id; // UUID
  final String name;
  final String filePath; // MD 文件路径
  final String content; // MD 完整内容
  final String contentHash; // 内容哈希，用于检测变更
  final bool isDefault;
  final bool isBuiltin; // 是否内置预置规则
  final DateTime createdAt;
  final DateTime updatedAt;

  const PromptRule({
    required this.id,
    required this.name,
    required this.filePath,
    required this.content,
    required this.contentHash,
    this.isDefault = false,
    this.isBuiltin = false,
    required this.createdAt,
    required this.updatedAt,
  });

  PromptRule copyWith({
    String? id,
    String? name,
    String? filePath,
    String? content,
    String? contentHash,
    bool? isDefault,
    bool? isBuiltin,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PromptRule(
      id: id ?? this.id,
      name: name ?? this.name,
      filePath: filePath ?? this.filePath,
      content: content ?? this.content,
      contentHash: contentHash ?? this.contentHash,
      isDefault: isDefault ?? this.isDefault,
      isBuiltin: isBuiltin ?? this.isBuiltin,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        filePath,
        content,
        contentHash,
        isDefault,
        isBuiltin,
        createdAt,
        updatedAt,
      ];
}

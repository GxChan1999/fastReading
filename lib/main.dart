import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'data/database/database_helper.dart';
import 'services/file_system_service.dart';
import 'services/prompt_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. 初始化文件系统目录结构
  await FileSystemService().initialize();

  // 2. 初始化数据库
  await DatabaseHelper.instance.initialize();

  // 3. 初始化预置 Prompt 规则
  await PromptService.instance.initialize();

  runApp(
    const ProviderScope(
      child: ReadingEfficiencyApp(),
    ),
  );
}

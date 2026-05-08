---
name: reading-app-mvp
description: 阅读提效对话APP MVP项目，Flutter跨端架构，全本地离线运行
type: project
---

**项目路径**: `d:\Desktop\readingHub\reading_efficiency_app`
**启动日期**: 2026-05-07
**基于文档**: 《阅读提效对话 APP MVP 本地开发执行手册（V1.0）》.md

**架构概览**:
- Flutter 3.22+ / Dart 3.4+, 跨端 (Windows/macOS/Android/iOS)
- 状态管理: Riverpod
- 数据库: SQLite (raw sqlite3, 8张核心表)
- AI: 直连大模型API (OpenAI/豆包/Claude), 流式响应, 密钥AES加密存储
- 核心流程: 7阶段精读状态机 (框架梳理→摸底提问→分章精读→章节讨论→理解纠偏→缺漏挖掘→沉淀归档)
- 分屏布局: PC端左右, 移动端上下

**目录结构**:
- `lib/core/` — 主题/路由/常量/工具
- `lib/data/` — 模型/数据库/仓库
- `lib/services/` — 文件系统/电子书解析/AI引擎/精读流程/导出
- `lib/providers/` — Riverpod状态管理
- `lib/ui/` — 6个页面 + 公共组件

**待完成集成**: flutter_epub/pdf解析真实实现、AI引擎全链路流式测试、具体drift代码生成可替换raw sqlite3

**注意事项**: Flutter SDK未安装在当前机器，需用户自行安装后执行 `flutter pub get && flutter run`

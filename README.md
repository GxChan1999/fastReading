# 光速读书

基于**费曼学习法**的 AI 驱动阅读提效工具。本地离线运行，支持 EPUB/TXT 电子书解析，多 AI 模型对话，阅读归档与数据迁移。

## 核心功能

### 阅读 + AI 对话双联动
- 宽屏设备（平板/折叠屏）左右分栏：一侧阅读、一侧对话
- 手机端抽屉式对话面板，不打断阅读流
- AI 实时感知当前章节、阅读进度、历史归档

### 超级阅读老师 Prompt
- 费曼学习法四步循环：概念提取 → 讲授复述 → 查漏补缺 → 简化提炼
- 苏格拉底式提问引导，不直接给答案
- 每轮对话要求用户做费曼输出
- 关联历史归档中的知识盲区，建立知识网络

### 多 AI Provider 支持
- OpenAI / DeepSeek / 豆包 / Claude / Zhipu（智谱）
- 支持自定义 API 端点与模型名
- 所有 API Key 本地加密存储

### 章节智能过滤
- 自动识别前言、序言、目录、附录、参考文献等非正文章节
- AI 上下文仅包含正文内容，确保章节定位准确
- 支持中英文 40+ 关键词模式匹配

### 费曼归档系统
- 每次阅读可归档：内容概述、费曼输出、知识盲区、行动项
- 疑难清单追踪：标记知识点状态，AI 辅助解释
- 导出为结构化 Markdown 文件

### 数据导出与迁移
- 完整 JSON 备份：书籍、章节文本、对话记录、费曼归档、疑难清单、配置
- 跨版本/跨设备恢复，支持增量导入
- 阅读笔记导出为 MD 格式

## 技术栈

| 层 | 技术 |
|---|---|
| 框架 | Flutter 3.x + Dart |
| 状态管理 | Riverpod |
| 数据库 | SQLite (sqlite3 + WAL 模式) |
| 电子书解析 | epub_pro + 自研 TXT 解析器 |
| AI 通信 | dio (OpenAI-compatible API) |
| Markdown 渲染 | flutter_markdown |
| 加密 | encrypt + crypto |

## 项目结构

```
lib/
├── core/           # 主题、路由、工具常量
├── data/           # 数据模型、数据库、仓库
├── providers/      # Riverpod providers
├── services/       # AI引擎、电子书解析、导出、Prompt管理
└── ui/             # 页面与组件
    ├── pages/
    │   ├── book_library/   # 书库首页
    │   ├── reading/        # 阅读+对话核心页
    │   ├── chat/           # 全屏对话页
    │   ├── settings/       # 设置页
    │   └── session_archive/ # 费曼归档
    └── widgets/     # 通用组件
```

## 构建与分发

```bash
# 安装依赖
flutter pub get

# 构建 Android APK
flutter build apk --release

# 输出：build/app/outputs/flutter-apk/app-release.apk
```

分发给他人：直接发送 APK，安装后通过「设置 → 数据管理 → 从备份恢复」迁移数据。

## 迭代记录

| 版本 | 内容 |
|---|---|
| 0.0.1 | 初始发布：费曼学习法 Prompt、多 AI Provider、章节过滤、费曼归档、数据迁移、宽屏适配、性能优化、暗色学院主题 |

import 'package:flutter/material.dart';

/// 应用路由定义
class AppRoutes {
  AppRoutes._();

  static const String bookLibrary = '/';
  static const String reading = '/books/:bookId/reading';
  static const String chat = '/books/:bookId/chat';
  static const String readingFlow = '/books/:bookId/flow';
  static const String sessionArchive = '/books/:bookId/archive';
  static const String history = '/history';
  static const String settings = '/settings';

  /// 构建阅读页路由
  static String readingRoute(String bookId) => '/books/$bookId/reading';

  /// 构建聊天页路由
  static String chatRoute(String bookId, {String? chapterId}) {
    final base = '/books/$bookId/chat';
    if (chapterId != null) return '$base?chapterId=$chapterId';
    return base;
  }

  /// 构建精读流程页路由
  static String flowRoute(String bookId) => '/books/$bookId/flow';

  /// 构建费曼归档页路由
  static String archiveRoute(String bookId) => '/books/$bookId/archive';
}

/// 全局导航 key，用于在非 widget 上下文中导航
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'ui/pages/book_library/book_library_page.dart';
import 'ui/pages/reading/reading_page.dart';
import 'ui/pages/chat/chat_page.dart';
import 'ui/pages/reading_flow/reading_flow_page.dart';
import 'ui/pages/session_archive/session_archive_page.dart';
import 'ui/pages/history/history_page.dart';
import 'ui/pages/settings/settings_page.dart';

class ReadingEfficiencyApp extends ConsumerWidget {
  const ReadingEfficiencyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: '阅读提效对话',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      navigatorKey: navigatorKey,
      home: const BookLibraryPage(),
      onGenerateRoute: (settings) {
        final uri = Uri.parse(settings.name ?? settings.name ?? '/');
        final path = uri.pathSegments;

        // /books/:bookId/reading
        if (path.length == 3 && path[0] == 'books' && path[2] == 'reading') {
          return MaterialPageRoute(
            builder: (_) => ReadingPage(bookId: path[1]),
            settings: settings,
          );
        }

        // /books/:bookId/chat
        if (path.length == 3 && path[0] == 'books' && path[2] == 'chat') {
          final chapterId = uri.queryParameters['chapterId'];
          return MaterialPageRoute(
            builder: (_) => ChatPage(bookId: path[1], chapterId: chapterId),
            settings: settings,
          );
        }

        // /books/:bookId/flow
        if (path.length == 3 && path[0] == 'books' && path[2] == 'flow') {
          return MaterialPageRoute(
            builder: (_) => ReadingFlowPage(bookId: path[1]),
            settings: settings,
          );
        }

        // /books/:bookId/archive
        if (path.length == 3 && path[0] == 'books' && path[2] == 'archive') {
          return MaterialPageRoute(
            builder: (_) => SessionArchivePage(bookId: path[1]),
            settings: settings,
          );
        }

        // /history
        if (path.length == 1 && path[0] == 'history') {
          return MaterialPageRoute(
            builder: (_) => const HistoryPage(),
            settings: settings,
          );
        }

        // /settings
        if (path.length == 1 && path[0] == 'settings') {
          return MaterialPageRoute(
            builder: (_) => const SettingsPage(),
            settings: settings,
          );
        }

        // 默认
        return MaterialPageRoute(
          builder: (_) => const BookLibraryPage(),
          settings: settings,
        );
      },
    );
  }
}

final themeModeProvider = StateProvider<ThemeMode>((ref) {
  return ThemeMode.light;
});

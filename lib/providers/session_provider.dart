import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/reading_session.dart';
import '../data/repositories/session_repository.dart';

/// 某本书的费曼归档列表
final sessionListProvider =
    StateNotifierProvider.family<SessionListNotifier, List<ReadingSession>, String>(
  (ref, bookId) => SessionListNotifier(bookId),
);

class SessionListNotifier extends StateNotifier<List<ReadingSession>> {
  final String bookId;
  final SessionRepository _repository = SessionRepository();

  SessionListNotifier(this.bookId) : super([]);

  void loadSessions() {
    state = _repository.getSessions(bookId);
  }

  /// 创建归档（从阅读页触发）
  ReadingSession createSession({
    String? chapterId,
    String chapterTitle = '',
    String? pageRange,
    String? contentSummary,
    String? discussionConclusions,
    String? feynmanOutput,
    String? blindSpots,
    String? actionItems,
  }) {
    final session = _repository.createSession(
      bookId: bookId,
      chapterId: chapterId,
      chapterTitle: chapterTitle,
      pageRange: pageRange,
      contentSummary: contentSummary,
      discussionConclusions: discussionConclusions,
      feynmanOutput: feynmanOutput,
      blindSpots: blindSpots,
      actionItems: actionItems,
    );
    loadSessions();
    return session;
  }

  void updateSession(ReadingSession session) {
    _repository.updateSession(session);
    loadSessions();
  }

  void deleteSession(String id) {
    _repository.deleteSession(id);
    state = state.where((s) => s.id != id).toList();
  }
}

/// 当前编辑的归档
final editingSessionProvider = StateProvider<ReadingSession?>((ref) => null);

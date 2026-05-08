import 'package:uuid/uuid.dart';
import '../database/database_helper.dart';
import '../models/reading_session.dart';

/// 费曼归档仓库
class SessionRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final Uuid _uuid = const Uuid();

  /// 创建新的阅读会话归档
  ReadingSession createSession({
    required String bookId,
    String? chapterId,
    String chapterTitle = '',
    String? pageRange,
    String? contentSummary,
    String? discussionConclusions,
    String? feynmanOutput,
    String? blindSpots,
    String? actionItems,
  }) {
    final now = DateTime.now();
    final session = ReadingSession(
      id: _uuid.v4(),
      bookId: bookId,
      chapterId: chapterId,
      chapterTitle: chapterTitle,
      pageRange: pageRange,
      contentSummary: contentSummary,
      discussionConclusions: discussionConclusions,
      feynmanOutput: feynmanOutput,
      blindSpots: blindSpots,
      actionItems: actionItems,
      createdAt: now,
      updatedAt: now,
    );
    _db.insertReadingSession(session);
    return session;
  }

  /// 更新归档
  void updateSession(ReadingSession session) {
    _db.updateReadingSession(session.copyWith(updatedAt: DateTime.now()));
  }

  /// 获取某本书的所有归档
  List<ReadingSession> getSessions(String bookId) {
    return _db.getSessionsByBookId(bookId);
  }

  /// 获取单条归档
  ReadingSession? getSession(String id) {
    return _db.getSessionById(id);
  }

  /// 删除归档
  void deleteSession(String id) {
    _db.deleteSession(id);
  }
}

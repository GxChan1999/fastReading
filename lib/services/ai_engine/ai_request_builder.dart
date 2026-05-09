/// AI 请求拼接工具 — 严格按照规范拼接请求内容
class AIRequestBuilder {
  String? _systemPrompt;
  String? _bookInfo;
  String? _currentProgress;
  String? _readingContent;
  String? _chatHistory;
  String? _feynmanContext;
  String? _userInstruction;

  AIRequestBuilder();

  /// 设置系统 Prompt
  AIRequestBuilder withSystemPrompt(String prompt) {
    _systemPrompt = prompt;
    return this;
  }

  /// 设置书籍基础信息
  AIRequestBuilder withBookInfo(String info) {
    _bookInfo = info;
    return this;
  }

  /// 设置当前进度
  AIRequestBuilder withCurrentProgress(String progress) {
    _currentProgress = progress;
    return this;
  }

  /// 设置阅读内容（当前章节或选中文本）
  AIRequestBuilder withReadingContent(String content) {
    _readingContent = content;
    return this;
  }

  /// 设置历史对话上下文（最近 N 轮）
  AIRequestBuilder withChatHistory(String history) {
    _chatHistory = history;
    return this;
  }

  /// 设置费曼归档上下文
  AIRequestBuilder withFeynmanContext(String context) {
    _feynmanContext = context;
    return this;
  }

  /// 设置用户指令
  AIRequestBuilder withUserInstruction(String instruction) {
    _userInstruction = instruction;
    return this;
  }

  /// 构建系统 Prompt
  String buildSystemPrompt() {
    if (_systemPrompt == null) return '';
    var prompt = _systemPrompt!;
    prompt = prompt.replaceAll('{book_info}', _bookInfo ?? '');
    prompt = prompt.replaceAll('{current_progress}', _currentProgress ?? '');
    prompt = prompt.replaceAll('{reading_content}', _readingContent ?? '');
    prompt = prompt.replaceAll('{chat_history}', _chatHistory ?? '');
    prompt = prompt.replaceAll('{feynman_context}', _feynmanContext ?? '');
    return prompt;
  }

  /// 构建完整的消息列表（用于 API 请求）
  List<Map<String, String>> buildMessages() {
    final messages = <Map<String, String>>[];

    // 1. 系统 Prompt
    final systemPrompt = buildSystemPrompt();
    if (systemPrompt.isNotEmpty) {
      messages.add({'role': 'system', 'content': systemPrompt});
    }

    // 2. 历史对话
    if (_chatHistory != null && _chatHistory!.isNotEmpty) {
      messages.add({'role': 'system', 'content': '历史对话上下文：\n$_chatHistory'});
    }

    // 3. 书籍信息
    if (_bookInfo != null && _bookInfo!.isNotEmpty) {
      messages.add({'role': 'system', 'content': '当前书籍：$_bookInfo'});
    }

    // 4. 阅读内容
    if (_readingContent != null && _readingContent!.isNotEmpty) {
      messages.add({'role': 'system', 'content': '当前阅读内容：\n$_readingContent'});
    }

    // 5. 费曼归档上下文
    if (_feynmanContext != null && _feynmanContext!.isNotEmpty) {
      messages.add({'role': 'system', 'content': '用户已有的费曼学习归档记录：\n$_feynmanContext'});
    }

    // 6. 用户指令
    if (_userInstruction != null && _userInstruction!.isNotEmpty) {
      messages.add({'role': 'user', 'content': _userInstruction!});
    }

    return messages;
  }

  /// 估算 token 数量（粗略，用于窗口控制）
  int estimateTokenCount() {
    int count = 0;
    for (final msg in buildMessages()) {
      count += (msg['content']?.length ?? 0) ~/ 2; // 中文约 2 字符/token
    }
    return count;
  }

  /// 清空
  void reset() {
    _systemPrompt = null;
    _bookInfo = null;
    _currentProgress = null;
    _readingContent = null;
    _chatHistory = null;
    _feynmanContext = null;
    _userInstruction = null;
  }
}

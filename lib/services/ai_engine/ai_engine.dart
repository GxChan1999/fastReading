import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/app_config.dart';

/// AI 响应流回调
typedef OnStreamChunk = void Function(String chunk);
typedef OnStreamComplete = void Function(String fullContent);
typedef OnStreamError = void Function(String error);

/// AI 引擎 — 直连大模型 API，支持流式响应、自动重试、请求节流
class AIEngine {
  static final AIEngine _instance = AIEngine._();
  factory AIEngine() => _instance;
  static AIEngine get instance => _instance;
  AIEngine._();

  Dio? _dio;
  ApiConfig _config = const ApiConfig();
  bool _initialized = false;

  /// 上次请求时间戳，用于强制最小间隔
  DateTime _lastRequestTime = DateTime(2000);

  /// 各 provider 的最小请求间隔（防 429）
  static const _minIntervals = {
    'zhipu': Duration(seconds: 3),
    'doubao': Duration(seconds: 2),
  };

  Duration get _minInterval =>
      _minIntervals[_config.provider] ?? const Duration(milliseconds: 600);

  /// 使用 API 配置初始化
  void initialize(ApiConfig config) {
    _config = config;
    _dio = Dio(
      BaseOptions(
        baseUrl: config.baseUrl,
        connectTimeout: const Duration(milliseconds: AppConstants.requestTimeoutMs),
        receiveTimeout: const Duration(milliseconds: AppConstants.requestTimeoutMs),
        headers: {
          'Authorization': 'Bearer ${config.apiKey}',
          'Content-Type': 'application/json',
        },
      ),
    );
    _initialized = true;
  }

  /// 是否已初始化
  bool get isInitialized => _initialized && _config.apiKey.isNotEmpty;

  /// 获取当前配置
  ApiConfig get config => _config;

  /// 发送聊天请求（支持流式，自动重试 + 请求节流）
  Future<String> sendChat({
    required List<Map<String, String>> messages,
    OnStreamChunk? onChunk,
    OnStreamComplete? onComplete,
    OnStreamError? onError,
  }) async {
    if (!isInitialized) {
      const error = 'AI 引擎未初始化，请先配置 API 密钥';
      onError?.call(error);
      throw StateError(error);
    }

    // 请求节流：确保最小间隔
    final sinceLast = DateTime.now().difference(_lastRequestTime);
    if (sinceLast < _minInterval) {
      await Future.delayed(_minInterval - sinceLast);
    }

    // 带指数退避的重试循环
    var attempt = 0;
    while (true) {
      try {
        _lastRequestTime = DateTime.now();
        final body = {
          'model': _config.model,
          'messages': messages,
          'temperature': _config.temperature,
          'max_tokens': _config.maxTokens,
          'stream': onChunk != null,
          if (_config.provider == 'zhipu' && _config.thinkingEnabled)
            'thinking': {'type': 'enabled'},
        };

        if (body['stream'] as bool) {
          return await _sendStreamingRequest(body, onChunk!, onComplete, onError);
        } else {
          return await _sendNormalRequest(body);
        }
      } on DioException catch (e) {
        final statusCode = e.response?.statusCode;
        if ((statusCode == 429 || statusCode == 503) && attempt < AppConstants.maxRetries) {
          attempt++;
          final delay = Duration(seconds: (1 << attempt).clamp(1, 16));
          onError?.call('请求频繁，${delay.inSeconds}秒后重试（$attempt/${AppConstants.maxRetries}）...');
          await Future.delayed(delay);
          continue;
        }
        final errorMsg = _handleDioError(e);
        onError?.call(errorMsg);
        throw Exception(errorMsg);
      } catch (e) {
        if (attempt < AppConstants.maxRetries) {
          attempt++;
          await Future.delayed(Duration(seconds: (1 << attempt).clamp(1, 8)));
          continue;
        }
        final errorMsg = '请求失败: $e';
        onError?.call(errorMsg);
        throw Exception(errorMsg);
      }
    }
  }

  /// 流式请求
  Future<String> _sendStreamingRequest(
    Map<String, dynamic> body,
    OnStreamChunk onChunk,
    OnStreamComplete? onComplete,
    OnStreamError? onError,
  ) async {
    final fullContent = StringBuffer();

    try {
      final response = await _dio!.post<ResponseBody>(
        '/chat/completions',
        data: body,
        options: Options(responseType: ResponseType.stream),
      );

      await for (final line in response.data!.stream
          .cast<List<int>>()
          .transform(utf8.decoder)
          .transform(const LineSplitter())) {
        if (line.startsWith('data: ')) {
          final data = line.substring(6).trim();
          if (data == '[DONE]') continue;

          try {
            final json = jsonDecode(data) as Map<String, dynamic>;
            final choice = (json['choices'] as List?)?.firstOrNull;
            if (choice == null) continue;

            final delta = choice['delta'] as Map<String, dynamic>?;
            final content = delta?['content'] as String?;
            if (content != null && content.isNotEmpty) {
              fullContent.write(content);
              onChunk(content);
            }
          } catch (_) {
            // 跳过解析失败的行
          }
        }
      }

      final result = fullContent.toString();
      onComplete?.call(result);
      return result;
    } catch (e) {
      final errorMsg = '流式请求失败: $e';
      onError?.call(errorMsg);
      rethrow;
    }
  }

  /// 普通（非流式）请求
  Future<String> _sendNormalRequest(Map<String, dynamic> body) async {
    final response = await _dio!.post<Map<String, dynamic>>(
      '/chat/completions',
      data: body,
    );

    final data = response.data;
    final choice = (data?['choices'] as List?)?.firstOrNull;
    final message = choice?['message'] as Map<String, dynamic>?;
    return message?['content'] as String? ?? '';
  }

  /// 处理 Dio 错误
  String _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return '连接超时，请检查网络';
      case DioExceptionType.receiveTimeout:
        return '响应超时，请重试';
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final body = e.response?.data;
        if (statusCode == 401) return 'API 密钥无效，请检查配置';
        if (statusCode == 429) return '请求过于频繁，请稍后重试';
        if (statusCode == 500) return '服务器内部错误，请稍后重试';
        return '请求失败 (HTTP $statusCode): $body';
      case DioExceptionType.cancel:
        return '请求已取消';
      default:
        return '网络异常: ${e.message}';
    }
  }

  /// 估算文本 token 数（用于窗口控制）
  int estimateTokens(String text) {
    return text.length ~/ 2; // 中文约 2 字符/token
  }

  /// 检查内容是否超出窗口限制
  bool wouldExceedLimit(int totalTokens, int modelLimit) {
    return totalTokens > modelLimit * AppConstants.maxContextWindowRatio ~/ 100;
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/app_config.dart';
import '../data/repositories/settings_repository.dart';
import '../services/ai_engine/ai_engine.dart';

/// 设置提供者
final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier(ref);
});

class SettingsState {
  final ApiConfig apiConfig;
  final ReadingPreferences readingPrefs;
  final bool isInitialized;

  const SettingsState({
    this.apiConfig = const ApiConfig(),
    this.readingPrefs = const ReadingPreferences(),
    this.isInitialized = false,
  });

  SettingsState copyWith({
    ApiConfig? apiConfig,
    ReadingPreferences? readingPrefs,
    bool? isInitialized,
  }) {
    return SettingsState(
      apiConfig: apiConfig ?? this.apiConfig,
      readingPrefs: readingPrefs ?? this.readingPrefs,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  final SettingsRepository _repository = SettingsRepository();

  SettingsNotifier(Ref ref) : super(const SettingsState()) {
    _loadSettings();
  }

  void _loadSettings() async {
    final apiConfig = await _repository.loadApiConfig();
    final readingPrefs = _repository.loadReadingPreferences();

    // 初始化 AI 引擎
    AIEngine.instance.initialize(apiConfig);

    state = SettingsState(
      apiConfig: apiConfig,
      readingPrefs: readingPrefs,
      isInitialized: true,
    );
  }

  /// 保存 API 配置
  Future<void> saveApiConfig(ApiConfig config) async {
    await _repository.saveApiConfig(config);
    AIEngine.instance.initialize(config);
    state = state.copyWith(apiConfig: config);
  }

  /// 保存阅读排版配置
  void saveReadingPrefs(ReadingPreferences prefs) {
    _repository.saveReadingPreferences(prefs);
    state = state.copyWith(readingPrefs: prefs);
  }

  /// 检查 API 是否已配置
  bool get hasApiKey => state.apiConfig.apiKey.isNotEmpty;
}

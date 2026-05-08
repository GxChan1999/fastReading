import 'dart:ui';
import 'package:equatable/equatable.dart';

/// 应用配置项模型
class AppConfigItem extends Equatable {
  final String key;
  final String value;

  const AppConfigItem({
    required this.key,
    required this.value,
  });

  @override
  List<Object?> get props => [key, value];
}

/// API 配置
class ApiConfig {
  final String provider; // openai / doubao / claude / zhipu
  final String apiKey;
  final String baseUrl;
  final String model;
  final double temperature;
  final int maxTokens;
  final bool thinkingEnabled;

  const ApiConfig({
    this.provider = 'openai',
    this.apiKey = '',
    this.baseUrl = 'https://api.openai.com/v1',
    this.model = 'gpt-4o',
    this.temperature = 0.7,
    this.maxTokens = 4096,
    this.thinkingEnabled = false,
  });

  Map<String, dynamic> toJson() => {
        'provider': provider,
        'apiKey': apiKey,
        'baseUrl': baseUrl,
        'model': model,
        'temperature': temperature,
        'maxTokens': maxTokens,
        'thinkingEnabled': thinkingEnabled,
      };

  factory ApiConfig.fromJson(Map<String, dynamic> json) => ApiConfig(
        provider: json['provider'] as String? ?? 'openai',
        apiKey: json['apiKey'] as String? ?? '',
        baseUrl: json['baseUrl'] as String? ?? 'https://api.openai.com/v1',
        model: json['model'] as String? ?? 'gpt-4o',
        temperature: (json['temperature'] as num?)?.toDouble() ?? 0.7,
        maxTokens: json['maxTokens'] as int? ?? 4096,
        thinkingEnabled: json['thinkingEnabled'] as bool? ?? false,
      );

  ApiConfig copyWith({
    String? provider,
    String? apiKey,
    String? baseUrl,
    String? model,
    double? temperature,
    int? maxTokens,
    bool? thinkingEnabled,
  }) {
    return ApiConfig(
      provider: provider ?? this.provider,
      apiKey: apiKey ?? this.apiKey,
      baseUrl: baseUrl ?? this.baseUrl,
      model: model ?? this.model,
      temperature: temperature ?? this.temperature,
      maxTokens: maxTokens ?? this.maxTokens,
      thinkingEnabled: thinkingEnabled ?? this.thinkingEnabled,
    );
  }
}

/// 阅读排版配置
class ReadingPreferences {
  final double fontSize;
  final double lineHeight;
  final double paragraphSpacing;
  final Color backgroundColor;
  final Color textColor;
  final bool useSystemFont;

  const ReadingPreferences({
    this.fontSize = 18.0,
    this.lineHeight = 1.8,
    this.paragraphSpacing = 12.0,
    this.backgroundColor = const Color(0xFFF8F5F0),
    this.textColor = const Color(0xFF333333),
    this.useSystemFont = true,
  });

  Map<String, dynamic> toJson() => {
        'fontSize': fontSize,
        'lineHeight': lineHeight,
        'paragraphSpacing': paragraphSpacing,
        'backgroundColor': backgroundColor.value,
        'textColor': textColor.value,
        'useSystemFont': useSystemFont,
      };

  factory ReadingPreferences.fromJson(Map<String, dynamic> json) =>
      ReadingPreferences(
        fontSize: (json['fontSize'] as num?)?.toDouble() ?? 18.0,
        lineHeight: (json['lineHeight'] as num?)?.toDouble() ?? 1.8,
        paragraphSpacing: (json['paragraphSpacing'] as num?)?.toDouble() ?? 12.0,
        backgroundColor: Color(json['backgroundColor'] as int? ?? 0xFFF8F5F0),
        textColor: Color(json['textColor'] as int? ?? 0xFF333333),
        useSystemFont: json['useSystemFont'] as bool? ?? true,
      );
}

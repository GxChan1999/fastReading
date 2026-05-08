import 'dart:io';
import 'package:flutter/foundation.dart';

/// 平台工具类
class PlatformUtils {
  PlatformUtils._();

  /// 是否为桌面端
  static bool get isDesktop {
    if (kIsWeb) return false;
    return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  }

  /// 是否为移动端
  static bool get isMobile {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  /// 是否为 Windows
  static bool get isWindows {
    if (kIsWeb) return false;
    return Platform.isWindows;
  }

  /// 是否为 macOS
  static bool get isMacOS {
    if (kIsWeb) return false;
    return Platform.isMacOS;
  }

  /// 是否为 Android
  static bool get isAndroid {
    if (kIsWeb) return false;
    return Platform.isAndroid;
  }

  /// 是否为 iOS
  static bool get isIOS {
    if (kIsWeb) return false;
    return Platform.isIOS;
  }

  /// 是否支持拖拽导入（PC 端）
  static bool get supportsDragDrop => isDesktop;

  /// 获取平台默认导入目录提示
  static String get filePickerHint {
    if (isDesktop) return '支持拖拽或点击选择文件';
    return '点击选择文件';
  }
}

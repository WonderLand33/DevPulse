import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

/// 桌面窗口初始化：尺寸、最小尺寸、居中。
class WindowService {
  static Future<void> init() async {
    await windowManager.ensureInitialized();
    const options = WindowOptions(
      size: Size(1180, 760),
      minimumSize: Size(920, 600),
      center: true,
      title: 'DevPulse',
      titleBarStyle: TitleBarStyle.normal,
    );
    await windowManager.waitUntilReadyToShow(options, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }
}

/// 图钉置顶状态。切换 setAlwaysOnTop。
class PinController extends Notifier<bool> {
  @override
  bool build() => false;

  Future<void> toggle() async {
    state = !state;
    await windowManager.setAlwaysOnTop(state);
  }
}

final pinProvider = NotifierProvider<PinController, bool>(PinController.new);

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/kv_store.dart';

/// 主题模式控制器：读写持久化到 settings box。
class ThemeModeController extends Notifier<ThemeMode> {
  static const _key = 'themeMode';

  @override
  ThemeMode build() {
    final raw = KvStore.instance.setting<String>(_key, 'dark');
    return switch (raw) {
      'light' => ThemeMode.light,
      'system' => ThemeMode.system,
      _ => ThemeMode.dark,
    };
  }

  void set(ThemeMode mode) {
    state = mode;
    KvStore.instance.putSetting(_key, mode.name);
  }

  void toggle() {
    set(state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
  }
}

final themeModeProvider =
    NotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new);

/// 全局字号缩放（设置面板可调）。
class FontScaleController extends Notifier<double> {
  static const _key = 'fontScale';

  @override
  double build() => KvStore.instance.setting<double>(_key, 1.0);

  void set(double v) {
    state = v.clamp(0.85, 1.35);
    KvStore.instance.putSetting(_key, state);
  }
}

final fontScaleProvider =
    NotifierProvider<FontScaleController, double>(FontScaleController.new);

/// 界面字体族（null=系统默认）。
class UiFontController extends Notifier<String?> {
  static const _key = 'uiFont';
  @override
  String? build() {
    final v = KvStore.instance.settings.get(_key);
    return v is String && v.isNotEmpty ? v : null;
  }

  void set(String? family) {
    state = (family != null && family.isNotEmpty) ? family : null;
    KvStore.instance.putSetting(_key, state ?? '');
  }
}

final uiFontProvider =
    NotifierProvider<UiFontController, String?>(UiFontController.new);

/// 等宽字体族（null=系统回退链）。
class MonoFontController extends Notifier<String?> {
  static const _key = 'monoFont';
  @override
  String? build() {
    final v = KvStore.instance.settings.get(_key);
    return v is String && v.isNotEmpty ? v : null;
  }

  void set(String? family) {
    state = (family != null && family.isNotEmpty) ? family : null;
    KvStore.instance.putSetting(_key, state ?? '');
  }
}

final monoFontProvider =
    NotifierProvider<MonoFontController, String?>(MonoFontController.new);

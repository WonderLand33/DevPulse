import 'package:hive_ce_flutter/hive_ce_flutter.dart';

/// 本地高速 KV 存储封装（基于 Hive CE，纯 Dart、无原生构建负担）。
///
/// 三个 box：
///  - settings：应用设置（主题、缩进、剪贴板开关等）
///  - todos：极客 TODO 任务
///  - totp：TOTP 账号「元数据」（不含种子；种子在 SecureStore）
class KvStore {
  KvStore._();
  static final KvStore instance = KvStore._();

  late final Box settings;
  late final Box todos;
  late final Box totp;
  late final Box notes;

  bool _ready = false;
  bool get isReady => _ready;

  Future<void> init() async {
    if (_ready) return;
    await Hive.initFlutter('devpulse');
    settings = await Hive.openBox('settings');
    todos = await Hive.openBox('todos');
    totp = await Hive.openBox('totp');
    notes = await Hive.openBox('notes');
    _ready = true;
  }

  // ---- settings 便捷读写 ----
  T setting<T>(String key, T fallback) {
    final v = settings.get(key);
    if (v is T) return v;
    return fallback;
  }

  Future<void> putSetting(String key, Object? value) =>
      settings.put(key, value);
}

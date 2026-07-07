import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 当前选中模块 id。
///
/// 独立成小文件（不放在 registry.dart），是因为 registry.dart 会 import
/// 全部模块页面，而 tool_scaffold.dart（被所有模块页面依赖）需要读取这个
/// provider 来渲染全局图标——放一起会造成循环依赖。
class SelectedModule extends Notifier<String> {
  @override
  String build() => 'json';

  void select(String id) => state = id;
}

final selectedModuleProvider =
    NotifierProvider<SelectedModule, String>(SelectedModule.new);

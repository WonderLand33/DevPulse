import 'package:flutter/widgets.dart';

/// 工具模块契约。侧栏与命令面板消费同一份注册表。
class ToolModule {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;

  /// 侧栏分组名。
  final String group;

  /// 搜索关键词（命令面板与侧栏搜索匹配）。
  final List<String> keywords;

  /// 页面构建器。
  final WidgetBuilder builder;

  const ToolModule({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.group,
    required this.keywords,
    required this.builder,
  });

  bool matchesQuery(String q) {
    if (q.isEmpty) return true;
    final lower = q.toLowerCase();
    if (title.toLowerCase().contains(lower)) return true;
    if (subtitle.toLowerCase().contains(lower)) return true;
    return keywords.any((k) => k.toLowerCase().contains(lower));
  }
}

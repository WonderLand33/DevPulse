import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../modules/registry.dart';
import '../storage/kv_store.dart';
import '../theme/app_theme.dart';
import 'sidebar.dart';

/// 顶层双栏外壳。
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});
  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  static const _widthKey = 'sidebarWidth';
  late double _sidebarWidth;

  /// 全部模块页面只构建一次，此后始终保持挂载（用 IndexedStack 切换可见项），
  /// 这样切换侧栏模块不会销毁重建页面、不会清空用户已输入的内容。
  late final List<Widget> _pages = kModules
      .map((m) => KeyedSubtree(key: ValueKey(m.id), child: m.builder(context)))
      .toList();

  @override
  void initState() {
    super.initState();
    _sidebarWidth =
        KvStore.instance.setting<double>(_widthKey, Dims.sidebarDefault);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    final selectedId = ref.watch(selectedModuleProvider);
    final rawIndex = kModules.indexWhere((m) => m.id == selectedId);
    final activeIndex = rawIndex < 0 ? 0 : rawIndex;

    return Scaffold(
      backgroundColor: p.background,
      body: Row(
        children: [
          SizedBox(width: _sidebarWidth, child: const Sidebar()),
          _DragHandle(
            onDelta: (dx) {
              setState(() {
                _sidebarWidth = (_sidebarWidth + dx)
                    .clamp(Dims.sidebarMin, Dims.sidebarMax);
              });
            },
            onEnd: () =>
                KvStore.instance.putSetting(_widthKey, _sidebarWidth),
          ),
          Expanded(
            child: IndexedStack(
              index: activeIndex,
              children: [
                for (var i = 0; i < _pages.length; i++)
                  // 隐藏的模块仍保持挂载（保留状态），但排除出
                  // 无障碍语义树，避免 Windows accessibility
                  // bridge 因树过大/含大量隐藏节点而报错刷屏。
                  ExcludeSemantics(
                    excluding: i != activeIndex,
                    child: _pages[i],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 可拖拽的侧栏分隔条。
class _DragHandle extends StatefulWidget {
  final ValueChanged<double> onDelta;
  final VoidCallback onEnd;
  const _DragHandle({required this.onDelta, required this.onEnd});
  @override
  State<_DragHandle> createState() => _DragHandleState();
}

class _DragHandleState extends State<_DragHandle> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return MouseRegion(
      cursor: SystemMouseCursors.resizeLeftRight,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onHorizontalDragUpdate: (d) => widget.onDelta(d.delta.dx),
        onHorizontalDragEnd: (_) => widget.onEnd(),
        child: Container(
          width: 6,
          color: Colors.transparent,
          child: Center(
            child: Container(
              width: 1,
              color: _hover ? p.accent : p.border,
            ),
          ),
        ),
      ),
    );
  }
}

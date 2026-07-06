import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../modules/registry.dart';
import '../command_palette/palette.dart';
import '../intent_bus.dart';
import '../storage/kv_store.dart';
import '../theme/app_theme.dart';
import '../theme/theme_controller.dart';
import '../widgets/app_feedback.dart';
import '../window/window_service.dart';
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
  int _lastNavSeq = 0;

  @override
  void initState() {
    super.initState();
    _sidebarWidth =
        KvStore.instance.setting<double>(_widthKey, Dims.sidebarDefault);
  }

  void _openPalette() => showCommandPalette(context, ref);

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    // 响应命令面板/剪贴板等发起的模块切换请求。
    ref.listen(navRequestProvider, (prev, next) {
      if (next.seq != _lastNavSeq && next.moduleId != null) {
        _lastNavSeq = next.seq;
        ref.read(selectedModuleProvider.notifier).select(next.moduleId!);
      }
    });

    final selectedId = ref.watch(selectedModuleProvider);
    final module = moduleById(selectedId);

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyK, control: true):
            _openPalette,
        const SingleActivator(LogicalKeyboardKey.keyK, meta: true):
            _openPalette,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
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
                child: Column(
                  children: [
                    _TopBar(onPalette: _openPalette),
                    const Divider(height: 1),
                    Expanded(
                      child: KeyedSubtree(
                        key: ValueKey(selectedId),
                        child: module.builder(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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

class _TopBar extends ConsumerWidget {
  final VoidCallback onPalette;
  const _TopBar({required this.onPalette});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final pinned = ref.watch(pinProvider);
    final mode = ref.watch(themeModeProvider);
    final isDark = mode == ThemeMode.dark ||
        (mode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    return Container(
      height: 46,
      color: p.background,
      padding: const EdgeInsets.symmetric(horizontal: Dims.gap),
      child: Row(
        children: [
          // 命令面板入口
          _BarButton(
            icon: Icons.search,
            tooltip: '命令面板 (Ctrl+K)',
            onTap: onPalette,
            child: Text('Ctrl K',
                style: TextStyle(
                    fontSize: 11,
                    color: p.textSecondary,
                    fontWeight: FontWeight.w600)),
          ),
          const Spacer(),
          _BarIcon(
            icon: isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            tooltip: isDark ? '切换到浅色' : '切换到深色',
            onTap: () => ref.read(themeModeProvider.notifier).toggle(),
          ),
          _BarIcon(
            icon: pinned ? Icons.push_pin : Icons.push_pin_outlined,
            tooltip: pinned ? '取消置顶' : '窗口置顶',
            active: pinned,
            onTap: () async {
              await ref.read(pinProvider.notifier).toggle();
              if (context.mounted) {
                showToast(context,
                    ref.read(pinProvider) ? '窗口已置顶' : '已取消置顶');
              }
            },
          ),
          _BarIcon(
            icon: Icons.tune,
            tooltip: '设置',
            onTap: () =>
                ref.read(selectedModuleProvider.notifier).select('settings'),
          ),
        ],
      ),
    );
  }
}

class _BarButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Widget child;
  const _BarButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    required this.child,
  });
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(Dims.radiusSm),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(color: p.border),
            borderRadius: BorderRadius.circular(Dims.radiusSm),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: p.textSecondary),
              const SizedBox(width: 6),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _BarIcon extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool active;
  const _BarIcon({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.active = false,
  });
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(Dims.radiusSm),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Icon(icon,
              size: 18, color: active ? p.accent : p.textSecondary),
        ),
      ),
    );
  }
}

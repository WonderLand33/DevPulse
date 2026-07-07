import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../selected_module.dart';
import '../theme/app_theme.dart';
import '../theme/theme_controller.dart';
import '../widgets/app_feedback.dart';
import '../window/window_service.dart';

/// 每个工具模块的统一 chrome：顶部标题栏（图标/标题/副标题 + 操作条 + 全局图标），
/// 下方内容区。全局图标（主题/置顶/设置）直接内置在这里，而不是单独占一整行，
/// 避免全局顶栏在移除命令面板后只剩三个图标、大片留白的问题。
class ToolScaffold extends ConsumerWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget> actions;
  final Widget body;

  const ToolScaffold({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actions = const [],
    required this.body,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(
              Dims.gapLg, Dims.gapMd, Dims.gapMd, Dims.gapMd),
          decoration: BoxDecoration(
            color: p.background,
            border: Border(bottom: BorderSide(color: p.border)),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: p.accentSoft,
                  borderRadius: BorderRadius.circular(Dims.radiusSm),
                ),
                child: Icon(icon, size: 20, color: p.accent),
              ),
              const SizedBox(width: Dims.gap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: p.textPrimary)),
                    const SizedBox(height: 1),
                    Text(subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 12.5, color: p.textSecondary)),
                  ],
                ),
              ),
              if (actions.isNotEmpty) ...[
                const SizedBox(width: Dims.gap),
                Wrap(spacing: 2, crossAxisAlignment: WrapCrossAlignment.center,
                    children: actions),
              ],
              const SizedBox(width: Dims.gap),
              Container(width: 1, height: 20, color: p.border),
              const SizedBox(width: 2),
              const _GlobalHeaderIcons(),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(Dims.gapMd),
            child: body,
          ),
        ),
      ],
    );
  }
}

/// 主题切换 / 窗口置顶 / 设置入口——所有模块共用，随 ToolScaffold 一起渲染。
class _GlobalHeaderIcons extends ConsumerWidget {
  const _GlobalHeaderIcons();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pinned = ref.watch(pinProvider);
    final mode = ref.watch(themeModeProvider);
    final isDark = mode == ThemeMode.dark ||
        (mode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
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
              showToast(
                  context, ref.read(pinProvider) ? '窗口已置顶' : '已取消置顶');
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
          padding: const EdgeInsets.all(7),
          child: Icon(icon, size: 17, color: active ? p.accent : p.textSecondary),
        ),
      ),
    );
  }
}

/// 尚未实现模块的占位。
class ComingSoon extends StatelessWidget {
  final String title;
  const ComingSoon(this.title, {super.key});
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.construction_outlined, size: 44, color: p.textSecondary),
          const SizedBox(height: Dims.gap),
          Text('$title · 即将上线',
              style: TextStyle(color: p.textSecondary, fontSize: 14)),
        ],
      ),
    );
  }
}

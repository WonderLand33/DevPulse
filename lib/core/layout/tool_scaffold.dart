import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// 每个工具模块的统一 chrome：顶部标题栏（图标/标题/副标题 + 操作条），下方内容区。
class ToolScaffold extends StatelessWidget {
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
  Widget build(BuildContext context) {
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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import 'app_feedback.dart';

/// 复制按钮：点击复制文本并提示。
class CopyButton extends StatelessWidget {
  final String Function() text;
  final String label;
  final bool dense;
  const CopyButton({
    super.key,
    required this.text,
    this.label = '复制',
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    return ToolbarButton(
      icon: Icons.copy_all_outlined,
      label: label,
      dense: dense,
      onTap: () async {
        final t = text();
        if (t.isEmpty) {
          showToast(context, '没有可复制的内容', error: true);
          return;
        }
        await Clipboard.setData(ClipboardData(text: t));
        if (context.mounted) showToast(context, '已复制到剪贴板');
      },
    );
  }
}

/// 统一风格的工具条按钮（图标 + 文案）。
class ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool dense;
  final Color? color;
  const ToolbarButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.dense = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final c = color ?? p.textSecondary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(Dims.radiusSm),
        onTap: onTap,
        child: Opacity(
          opacity: onTap == null ? 0.4 : 1,
          child: Padding(
            padding: EdgeInsets.symmetric(
                horizontal: dense ? 8 : 10, vertical: dense ? 5 : 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: dense ? 15 : 17, color: c),
                if (label.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Text(label,
                      style: TextStyle(
                          fontSize: dense ? 12 : 13,
                          color: c,
                          fontWeight: FontWeight.w500)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 带标题的分区卡片。
class SectionCard extends StatelessWidget {
  final String? title;
  final IconData? icon;
  final List<Widget> actions;
  final Widget child;
  final EdgeInsets padding;
  final bool expand;

  const SectionCard({
    super.key,
    this.title,
    this.icon,
    this.actions = const [],
    required this.child,
    this.padding = const EdgeInsets.all(Dims.gapMd),
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      children: [
        if (title != null || actions.isNotEmpty)
          Container(
            height: 42,
            padding: const EdgeInsets.only(left: Dims.gapMd, right: Dims.gapSm),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: p.border)),
            ),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: p.textSecondary),
                  const SizedBox(width: Dims.gapSm),
                ],
                if (title != null)
                  Text(title!,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: p.textPrimary)),
                const Spacer(),
                ...actions,
              ],
            ),
          ),
        if (expand)
          Expanded(child: Padding(padding: padding, child: child))
        else
          Padding(padding: padding, child: child),
      ],
    );

    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        border: Border.all(color: p.border),
        borderRadius: BorderRadius.circular(Dims.radius),
      ),
      clipBehavior: Clip.antiAlias,
      child: content,
    );
  }
}

/// 空态提示。
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? hint;
  const EmptyState(
      {super.key, required this.icon, required this.message, this.hint});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: p.textSecondary.withValues(alpha: 0.5)),
          const SizedBox(height: Dims.gap),
          Text(message,
              style: TextStyle(color: p.textSecondary, fontSize: 13)),
          if (hint != null) ...[
            const SizedBox(height: 4),
            Text(hint!,
                style: TextStyle(
                    color: p.textSecondary.withValues(alpha: 0.7),
                    fontSize: 12)),
          ],
        ],
      ),
    );
  }
}

/// 键值结果行（左标签右值 + 可复制）。
class ResultRow extends StatelessWidget {
  final String label;
  final String value;
  final bool mono;
  final Color? valueColor;
  final bool copyable;
  const ResultRow({
    super.key,
    required this.label,
    required this.value,
    this.mono = false,
    this.valueColor,
    this.copyable = true,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 128,
            child: Text(label,
                style: TextStyle(color: p.textSecondary, fontSize: 12.5)),
          ),
          const SizedBox(width: Dims.gap),
          Expanded(
            child: SelectableText(
              value,
              style: mono
                  ? context.mono(size: 12.5, color: valueColor)
                  : TextStyle(
                      color: valueColor ?? p.textPrimary, fontSize: 12.5),
            ),
          ),
          if (copyable && value.isNotEmpty)
            CopyButton(text: () => value, label: '', dense: true),
        ],
      ),
    );
  }
}

/// 状态徽章（成功/告警/危险/普通）。
enum BadgeKind { neutral, success, warning, danger, info }

class StatusBadge extends StatelessWidget {
  final String text;
  final BadgeKind kind;
  final IconData? icon;
  const StatusBadge(this.text,
      {super.key, this.kind = BadgeKind.neutral, this.icon});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = switch (kind) {
      BadgeKind.success => p.success,
      BadgeKind.warning => p.warning,
      BadgeKind.danger => p.danger,
      BadgeKind.info => p.info,
      BadgeKind.neutral => p.textSecondary,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(Dims.radiusSm),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(text,
              style: TextStyle(
                  color: color, fontSize: 11.5, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

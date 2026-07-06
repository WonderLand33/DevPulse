import 'package:diff_match_patch/diff_match_patch.dart' as dmp;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/layout/tool_scaffold.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/code_field.dart';
import '../../core/widgets/common.dart';
import 'diff_logic.dart';

class DiffPage extends ConsumerStatefulWidget {
  const DiffPage({super.key});
  @override
  ConsumerState<DiffPage> createState() => _DiffPageState();
}

class _DiffPageState extends ConsumerState<DiffPage> {
  final _left = TextEditingController();
  final _right = TextEditingController();
  bool _unified = false;
  bool _ignoreWs = false;
  bool _ignoreCase = false;

  @override
  void dispose() {
    _left.dispose();
    _right.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final ops = DiffLogic.lineDiff(
      _left.text,
      _right.text,
      ignoreWhitespace: _ignoreWs,
      ignoreCase: _ignoreCase,
    );
    final stats = DiffLogic.stats(ops);
    final hasInput = _left.text.isNotEmpty || _right.text.isNotEmpty;

    return ToolScaffold(
      icon: Icons.difference_outlined,
      title: '文本对比 Diff',
      subtitle: 'Split / Unified · 行级与字符级差异',
      actions: [
        StatusBadge('+${stats.added}', kind: BadgeKind.success),
        const SizedBox(width: 4),
        StatusBadge('-${stats.removed}', kind: BadgeKind.danger),
        const SizedBox(width: 4),
        StatusBadge('~${stats.modified}', kind: BadgeKind.warning),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                      value: false,
                      icon: Icon(Icons.vertical_split, size: 15),
                      label: Text('双栏')),
                  ButtonSegment(
                      value: true,
                      icon: Icon(Icons.view_agenda_outlined, size: 15),
                      label: Text('合并')),
                ],
                selected: {_unified},
                showSelectedIcon: false,
                onSelectionChanged: (s) => setState(() => _unified = s.first),
              ),
              const SizedBox(width: Dims.gapMd),
              FilterChip(
                label: const Text('忽略空格'),
                selected: _ignoreWs,
                onSelected: (v) => setState(() => _ignoreWs = v),
              ),
              const SizedBox(width: Dims.gapSm),
              FilterChip(
                label: const Text('忽略大小写'),
                selected: _ignoreCase,
                onSelected: (v) => setState(() => _ignoreCase = v),
              ),
            ],
          ),
          const SizedBox(height: Dims.gap),
          // 输入
          SizedBox(
            height: 150,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: CodeInput(
                    controller: _left,
                    hint: '原始文本…',
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: Dims.gap),
                Expanded(
                  child: CodeInput(
                    controller: _right,
                    hint: '对比文本…',
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Dims.gap),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: p.surfaceAlt,
                border: Border.all(color: p.border),
                borderRadius: BorderRadius.circular(Dims.radiusSm),
              ),
              clipBehavior: Clip.antiAlias,
              child: !hasInput
                  ? const EmptyState(
                      icon: Icons.difference_outlined,
                      message: '在上方输入两段文本查看差异')
                  : SingleChildScrollView(
                      child: _unified
                          ? _UnifiedView(ops: ops)
                          : _SplitView(ops: ops),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

TextSpan _inlineSpans(
    BuildContext context, String a, String b, {required bool showLeft}) {
  final p = context.palette;
  final segs = DiffLogic.inlineDiff(a, b);
  final spans = <TextSpan>[];
  for (final s in segs) {
    if (s.op == dmp.DIFF_EQUAL) {
      spans.add(TextSpan(text: s.text));
    } else if (s.op == dmp.DIFF_DELETE && showLeft) {
      spans.add(TextSpan(
          text: s.text,
          style: TextStyle(
              backgroundColor: p.danger.withValues(alpha: 0.35),
              color: p.textPrimary)));
    } else if (s.op == dmp.DIFF_INSERT && !showLeft) {
      spans.add(TextSpan(
          text: s.text,
          style: TextStyle(
              backgroundColor: p.success.withValues(alpha: 0.35),
              color: p.textPrimary)));
    }
  }
  return TextSpan(style: context.mono(size: 12.5), children: spans);
}

class _SplitView extends StatelessWidget {
  final List<DiffLineOp> ops;
  const _SplitView({required this.ops});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    Color? bg(DOp op, bool left) => switch (op) {
          DOp.equal => null,
          DOp.delete => left ? p.danger.withValues(alpha: 0.12) : null,
          DOp.insert => left ? null : p.success.withValues(alpha: 0.12),
          DOp.replace =>
            (left ? p.danger : p.success).withValues(alpha: 0.12),
        };

    Widget cell(DiffLineOp o, bool left) {
      final text = left ? o.left : o.right;
      final gutter = switch (o.op) {
        DOp.delete => left ? '-' : '',
        DOp.insert => left ? '' : '+',
        DOp.replace => left ? '-' : '+',
        DOp.equal => '',
      };
      Widget content;
      if (o.op == DOp.replace && o.left != null && o.right != null) {
        content = RichText(
            text: _inlineSpans(context, o.left!, o.right!, showLeft: left));
      } else {
        content = Text(text ?? '', style: context.mono(size: 12.5));
      }
      return Container(
        color: bg(o.op, left),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1.5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 14,
              child: Text(gutter,
                  style: context.mono(size: 12.5, color: p.textSecondary)),
            ),
            Expanded(child: content),
          ],
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [for (final o in ops) cell(o, true)],
          ),
        ),
        Container(width: 1, color: p.border),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [for (final o in ops) cell(o, false)],
          ),
        ),
      ],
    );
  }
}

class _UnifiedView extends StatelessWidget {
  final List<DiffLineOp> ops;
  const _UnifiedView({required this.ops});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final rows = <Widget>[];

    Widget line(String gutter, String text, Color? bg, Color gutterColor,
        {TextSpan? rich}) {
      return Container(
        width: double.infinity,
        color: bg,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1.5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
                width: 14,
                child: Text(gutter,
                    style: context.mono(size: 12.5, color: gutterColor))),
            Expanded(
                child: rich != null
                    ? RichText(text: rich)
                    : Text(text, style: context.mono(size: 12.5))),
          ],
        ),
      );
    }

    for (final o in ops) {
      switch (o.op) {
        case DOp.equal:
          rows.add(line(' ', o.left ?? '', null, p.textSecondary));
        case DOp.delete:
          rows.add(line('-', o.left ?? '',
              p.danger.withValues(alpha: 0.12), p.danger));
        case DOp.insert:
          rows.add(line('+', o.right ?? '',
              p.success.withValues(alpha: 0.12), p.success));
        case DOp.replace:
          rows.add(line('-', o.left ?? '',
              p.danger.withValues(alpha: 0.12), p.danger,
              rich: _inlineSpans(context, o.left!, o.right!, showLeft: true)));
          rows.add(line('+', o.right ?? '',
              p.success.withValues(alpha: 0.12), p.success,
              rich: _inlineSpans(context, o.left!, o.right!, showLeft: false)));
      }
    }
    return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch, children: rows);
  }
}

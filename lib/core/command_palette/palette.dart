import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../modules/module.dart';
import '../../modules/registry.dart';
import '../theme/app_theme.dart';
import '../util/calc.dart';
import '../widgets/app_feedback.dart';

/// 打开命令面板。
Future<void> showCommandPalette(BuildContext context, WidgetRef ref) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'palette',
    barrierColor: Colors.black.withValues(alpha: 0.45),
    transitionDuration: Dims.fast,
    pageBuilder: (_, a, b) => const SizedBox.shrink(),
    transitionBuilder: (ctx, anim, a, b) {
      return Opacity(
        opacity: anim.value,
        child: Align(
          alignment: const Alignment(0, -0.35),
          child: Transform.translate(
            offset: Offset(0, (1 - anim.value) * -12),
            child: _PaletteCard(ref: ref),
          ),
        ),
      );
    },
  );
}

class _PaletteCard extends StatefulWidget {
  final WidgetRef ref;
  const _PaletteCard({required this.ref});
  @override
  State<_PaletteCard> createState() => _PaletteCardState();
}

class _PaletteCardState extends State<_PaletteCard> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  String _query = '';
  int _index = 0;

  List<ToolModule> get _results =>
      kModules.where((m) => m.matchesQuery(_query)).toList();

  double? get _calc => Calc.tryEval(_query);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _confirm() {
    final results = _results;
    if (results.isEmpty) {
      // 若是运算，回车复制结果
      final c = _calc;
      if (c != null) {
        Clipboard.setData(ClipboardData(text: prettyNum(c)));
        Navigator.of(context).pop();
        showToast(context, '已复制运算结果');
      }
      return;
    }
    final m = results[_index.clamp(0, results.length - 1)];
    widget.ref.read(selectedModuleProvider.notifier).select(m.id);
    Navigator.of(context).pop();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent e) {
    if (e is! KeyDownEvent) return KeyEventResult.ignored;
    final len = _results.length;
    if (e.logicalKey == LogicalKeyboardKey.arrowDown) {
      setState(() => _index = len == 0 ? 0 : (_index + 1) % len);
      return KeyEventResult.handled;
    }
    if (e.logicalKey == LogicalKeyboardKey.arrowUp) {
      setState(() => _index = len == 0 ? 0 : (_index - 1 + len) % len);
      return KeyEventResult.handled;
    }
    if (e.logicalKey == LogicalKeyboardKey.escape) {
      Navigator.of(context).pop();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final results = _results;
    final calc = _calc;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 560,
        constraints: const BoxConstraints(maxHeight: 460),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(Dims.radiusLg),
          border: Border.all(color: p.border),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 32,
                offset: const Offset(0, 12)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 输入
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: Dims.gapMd, vertical: Dims.gapSm),
              child: Row(
                children: [
                  Icon(Icons.search, color: p.textSecondary, size: 20),
                  const SizedBox(width: Dims.gap),
                  Expanded(
                    child: Focus(
                      onKeyEvent: _onKey,
                      child: TextField(
                        controller: _controller,
                        focusNode: _focus,
                        autofocus: true,
                        onChanged: (v) => setState(() {
                          _query = v;
                          _index = 0;
                        }),
                        onSubmitted: (_) => _confirm(),
                        style: TextStyle(fontSize: 16, color: p.textPrimary),
                        decoration: const InputDecoration(
                          filled: false,
                          border: InputBorder.none,
                          hintText: '搜索工具，或输入表达式即时计算…',
                          isDense: true,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // 运算预览
            if (calc != null)
              Container(
                width: double.infinity,
                color: p.accentSoft,
                padding: const EdgeInsets.symmetric(
                    horizontal: Dims.gapMd, vertical: Dims.gap),
                child: Row(
                  children: [
                    Icon(Icons.calculate_outlined, size: 18, color: p.accent),
                    const SizedBox(width: Dims.gap),
                    Text('= ${prettyNum(calc)}',
                        style: context.mono(
                            size: 15,
                            color: p.accent,
                            weight: FontWeight.w700)),
                    const Spacer(),
                    Text('回车复制',
                        style:
                            TextStyle(fontSize: 11, color: p.textSecondary)),
                  ],
                ),
              ),
            // 结果列表
            Flexible(
              child: results.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(Dims.gapLg),
                      child: Text(
                          calc != null ? '按回车复制运算结果' : '没有匹配的工具',
                          style: TextStyle(
                              color: p.textSecondary, fontSize: 13)),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.all(Dims.gapSm),
                      itemCount: results.length,
                      itemBuilder: (ctx, i) {
                        final m = results[i];
                        final active = i == _index;
                        return InkWell(
                          borderRadius:
                              BorderRadius.circular(Dims.radiusSm),
                          onTap: () {
                            widget.ref
                                .read(selectedModuleProvider.notifier)
                                .select(m.id);
                            Navigator.of(context).pop();
                          },
                          onHover: (h) {
                            if (h) setState(() => _index = i);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: Dims.gap, vertical: 10),
                            decoration: BoxDecoration(
                              color: active
                                  ? p.accentSoft
                                  : Colors.transparent,
                              borderRadius:
                                  BorderRadius.circular(Dims.radiusSm),
                            ),
                            child: Row(
                              children: [
                                Icon(m.icon,
                                    size: 18,
                                    color: active
                                        ? p.accent
                                        : p.textSecondary),
                                const SizedBox(width: Dims.gap),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(m.title,
                                          style: TextStyle(
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w600,
                                              color: p.textPrimary)),
                                      Text(m.subtitle,
                                          style: TextStyle(
                                              fontSize: 11.5,
                                              color: p.textSecondary)),
                                    ],
                                  ),
                                ),
                                if (active)
                                  Icon(Icons.keyboard_return,
                                      size: 15, color: p.textSecondary),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

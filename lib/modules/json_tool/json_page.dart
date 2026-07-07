import 'dart:convert';
import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:re_editor/re_editor.dart';
import 'package:re_highlight/languages/json.dart';
import 'package:re_highlight/styles/atom-one-dark.dart';
import 'package:re_highlight/styles/atom-one-light.dart';

import '../../core/layout/tool_scaffold.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_feedback.dart';
import '../../core/widgets/common.dart';
import 'json_logic.dart';
import 'simple_find_bar.dart';

/// JSON 处理器：单一可编辑代码框，所见即所得。
/// 内置折叠展开（左侧折叠指示器）、行号、内容搜索（Ctrl+F）。
class JsonPage extends ConsumerStatefulWidget {
  const JsonPage({super.key});
  @override
  ConsumerState<JsonPage> createState() => _JsonPageState();
}

class _JsonPageState extends ConsumerState<JsonPage> {
  late final CodeLineEditingController _code;
  bool _dragging = false;
  bool _showFind = false;
  String? _error;
  int? _errLine;
  int? _errCol;

  @override
  void initState() {
    super.initState();
    _code = CodeLineEditingController();
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _apply(JsonResult r) {
    setState(() {
      if (r.ok) {
        _code.text = r.output ?? '';
        _error = null;
        _errLine = null;
        _errCol = null;
      } else {
        _error = r.error;
        _errLine = r.line;
        _errCol = r.col;
      }
    });
  }

  void _format() => _apply(JsonLogic.format(_code.text, '2'));
  void _minify() => _apply(JsonLogic.minify(_code.text));
  void _escape() => _apply(JsonResult(output: JsonLogic.escape(_code.text)));
  void _unescape() => _apply(JsonLogic.unescape(_code.text));

  Future<void> _paste() async {
    final d = await Clipboard.getData(Clipboard.kTextPlain);
    if (d?.text != null) {
      _code.text = d!.text!;
      _format();
    }
  }

  Future<void> _onDrop(DropDoneDetails d) async {
    if (d.files.isEmpty) return;
    try {
      _code.text = await File(d.files.first.path).readAsString();
      _format();
    } catch (_) {}
  }

  bool? get _validity {
    final t = _code.text.trim();
    if (t.isEmpty) return null;
    try {
      json.decode(t);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final valid = _validity;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyF, control: true):
            () => setState(() => _showFind = !_showFind),
        const SingleActivator(LogicalKeyboardKey.keyF, meta: true):
            () => setState(() => _showFind = !_showFind),
      },
      child: ToolScaffold(
        icon: Icons.data_object,
        title: 'JSON 处理器',
        subtitle: '单框所见即所得 · 折叠展开 · 内容搜索 (Ctrl+F)',
        actions: [
          if (valid == true)
            const StatusBadge('合法',
                kind: BadgeKind.success, icon: Icons.check)
          else if (valid == false)
            const StatusBadge('非法',
                kind: BadgeKind.danger, icon: Icons.close),
          const SizedBox(width: 4),
          ToolbarButton(
              icon: Icons.search,
              label: '搜索',
              dense: true,
              onTap: () => setState(() => _showFind = !_showFind)),
          ToolbarButton(
              icon: Icons.content_paste_outlined,
              label: '粘贴',
              dense: true,
              onTap: _paste),
          ToolbarButton(
              icon: Icons.clear_all,
              label: '清空',
              dense: true,
              onTap: () => setState(() {
                    _code.text = '';
                    _error = null;
                  })),
          ToolbarButton(
              icon: Icons.copy_all_outlined,
              label: '复制',
              dense: true,
              onTap: () async {
                if (_code.text.isEmpty) {
                  showToast(context, '没有可复制的内容', error: true);
                  return;
                }
                await Clipboard.setData(ClipboardData(text: _code.text));
                if (context.mounted) showToast(context, '已复制到剪贴板');
              }),
        ],
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _controls(p),
            const SizedBox(height: Dims.gap),
            if (_showFind) ...[
              SimpleFindBar(
                controller: _code,
                onClose: () => setState(() => _showFind = false),
              ),
              const SizedBox(height: Dims.gap),
            ],
            if (_error != null) _errorBanner(p),
            Expanded(child: _editor(p, dark)),
          ],
        ),
      ),
    );
  }

  Widget _editor(AppPalette p, bool dark) {
    return DropTarget(
      onDragEntered: (_) => setState(() => _dragging = true),
      onDragExited: (_) => setState(() => _dragging = false),
      onDragDone: (d) {
        setState(() => _dragging = false);
        _onDrop(d);
      },
      child: Container(
        decoration: BoxDecoration(
          color: p.surfaceAlt,
          border: Border.all(
              color: _dragging ? p.accent : p.border,
              width: _dragging ? 1.5 : 1),
          borderRadius: BorderRadius.circular(Dims.radiusSm),
        ),
        clipBehavior: Clip.antiAlias,
        child: CodeEditor(
          controller: _code,
          wordWrap: false,
          onChanged: (_) => setState(() {}),
          padding: const EdgeInsets.symmetric(vertical: Dims.gapSm),
          hint: '在此粘贴或拖入 JSON，点「格式化」即就地美化，可折叠可搜索…',
          style: CodeEditorStyle(
            fontSize: 13,
            fontHeight: 1.5,
            fontFamily: kUserMonoFamily,
            fontFamilyFallback: kMonoFontFallback,
            textColor: p.textPrimary,
            backgroundColor: p.surfaceAlt,
            cursorColor: p.accent,
            selectionColor: p.accent.withValues(alpha: 0.28),
            chunkIndicatorColor: p.textSecondary,
            codeTheme: CodeHighlightTheme(
              languages: {'json': CodeHighlightThemeMode(mode: langJson)},
              theme: dark ? atomOneDarkTheme : atomOneLightTheme,
            ),
          ),
          indicatorBuilder:
              (context, editingController, chunkController, notifier) {
            return Row(
              children: [
                DefaultCodeLineNumber(
                    controller: editingController, notifier: notifier),
                DefaultCodeChunkIndicator(
                    width: 20, controller: chunkController, notifier: notifier),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _controls(AppPalette p) {
    return Row(
      children: [
        FilledButton.icon(
            onPressed: _format,
            icon: const Icon(Icons.auto_fix_high, size: 16),
            label: const Text('格式化')),
        const SizedBox(width: Dims.gapSm),
        OutlinedButton(onPressed: _minify, child: const Text('压缩')),
        const SizedBox(width: Dims.gapSm),
        OutlinedButton(onPressed: _escape, child: const Text('转义')),
        const SizedBox(width: Dims.gapSm),
        OutlinedButton(onPressed: _unescape, child: const Text('去转义')),
        const Spacer(),
        Text('可点击行号右侧箭头折叠/展开',
            style: TextStyle(fontSize: 11.5, color: p.textSecondary)),
      ],
    );
  }

  Widget _errorBanner(AppPalette p) {
    final loc =
        (_errLine != null) ? ' （第 $_errLine 行，第 $_errCol 列）' : '';
    return Container(
      margin: const EdgeInsets.only(bottom: Dims.gap),
      padding:
          const EdgeInsets.symmetric(horizontal: Dims.gap, vertical: Dims.gapSm),
      decoration: BoxDecoration(
        color: p.danger.withValues(alpha: 0.12),
        border: Border.all(color: p.danger.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(Dims.radiusSm),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 16, color: p.danger),
          const SizedBox(width: Dims.gapSm),
          Expanded(
            child: Text('$_error$loc',
                style: TextStyle(color: p.danger, fontSize: 12.5)),
          ),
        ],
      ),
    );
  }
}

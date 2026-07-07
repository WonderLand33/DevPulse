import 'package:flutter/material.dart';
import 'package:re_editor/re_editor.dart';

import '../../core/theme/app_theme.dart';

/// 极简查找条：在主线程用普通字符串匹配实现，不使用 re_editor 自带的
/// isolate 查找机制（该机制在桌面端偶发导致进程崩溃）。
class SimpleFindBar extends StatefulWidget {
  final CodeLineEditingController controller;
  final VoidCallback onClose;
  const SimpleFindBar({
    super.key,
    required this.controller,
    required this.onClose,
  });

  @override
  State<SimpleFindBar> createState() => _SimpleFindBarState();
}

class _Match {
  final int line;
  final int start;
  final int end;
  const _Match(this.line, this.start, this.end);
}

class _SimpleFindBarState extends State<SimpleFindBar> {
  final _queryCtrl = TextEditingController();
  final _focus = FocusNode();
  bool _caseSensitive = false;
  List<_Match> _matches = const [];
  int _current = -1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _queryCtrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _search() {
    final query = _queryCtrl.text;
    if (query.isEmpty) {
      setState(() {
        _matches = const [];
        _current = -1;
      });
      return;
    }
    final needle = _caseSensitive ? query : query.toLowerCase();
    final lines = widget.controller.text.split('\n');
    final matches = <_Match>[];
    for (var lineIndex = 0; lineIndex < lines.length; lineIndex++) {
      final line =
          _caseSensitive ? lines[lineIndex] : lines[lineIndex].toLowerCase();
      var from = 0;
      while (true) {
        final idx = line.indexOf(needle, from);
        if (idx < 0) break;
        matches.add(_Match(lineIndex, idx, idx + needle.length));
        from = idx + needle.length;
      }
    }
    setState(() {
      _matches = matches;
      _current = matches.isEmpty ? -1 : 0;
    });
    _jumpToCurrent();
  }

  void _jumpToCurrent() {
    if (_current < 0 || _current >= _matches.length) return;
    final m = _matches[_current];
    widget.controller.selection = CodeLineSelection.fromRange(
      range: CodeLineRange(index: m.line, start: m.start, end: m.end),
    );
    widget.controller.makeCursorCenterIfInvisible();
  }

  void _next() {
    if (_matches.isEmpty) return;
    setState(() => _current = (_current + 1) % _matches.length);
    _jumpToCurrent();
  }

  void _previous() {
    if (_matches.isEmpty) return;
    setState(() => _current = (_current - 1 + _matches.length) % _matches.length);
    _jumpToCurrent();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final hasQuery = _queryCtrl.text.isNotEmpty;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Dims.gapSm, vertical: 4),
      decoration: BoxDecoration(
        color: p.surface,
        border: Border.all(color: p.border),
        borderRadius: BorderRadius.circular(Dims.radiusSm),
      ),
      child: Row(
        children: [
          Icon(Icons.search, size: 15, color: p.textSecondary),
          const SizedBox(width: 6),
          SizedBox(
            width: 220,
            child: TextField(
              controller: _queryCtrl,
              focusNode: _focus,
              autofocus: true,
              onChanged: (_) => _search(),
              onSubmitted: (_) => _next(),
              style: TextStyle(fontSize: 13, color: p.textPrimary),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: '在 JSON 中查找…',
              ),
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 40,
            child: Text(
              hasQuery ? '${_current + 1}/${_matches.length}' : '',
              style: TextStyle(fontSize: 11.5, color: p.textSecondary),
            ),
          ),
          _caseToggle(p),
          const Spacer(),
          _iconBtn(
            icon: Icons.keyboard_arrow_up,
            tooltip: '上一个',
            onTap: _matches.isEmpty ? null : _previous,
          ),
          _iconBtn(
            icon: Icons.keyboard_arrow_down,
            tooltip: '下一个',
            onTap: _matches.isEmpty ? null : _next,
          ),
          _iconBtn(icon: Icons.close, tooltip: '关闭', onTap: widget.onClose),
        ],
      ),
    );
  }

  Widget _caseToggle(AppPalette p) {
    return Tooltip(
      message: '区分大小写',
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: () {
          setState(() => _caseSensitive = !_caseSensitive);
          _search();
        },
        child: Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _caseSensitive ? p.accentSoft : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text('Aa',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _caseSensitive ? p.accent : p.textSecondary)),
        ),
      ),
    );
  }

  Widget _iconBtn({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onTap,
  }) {
    final p = context.palette;
    return IconButton(
      icon: Icon(icon, size: 18),
      tooltip: tooltip,
      color: p.textSecondary,
      constraints: const BoxConstraints.tightFor(width: 30, height: 30),
      padding: EdgeInsets.zero,
      onPressed: onTap,
    );
  }
}

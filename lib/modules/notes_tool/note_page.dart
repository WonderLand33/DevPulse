import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/layout/tool_scaffold.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_feedback.dart';
import '../../core/widgets/code_field.dart';
import '../../core/widgets/common.dart';
import 'note_controller.dart';

class NotePage extends ConsumerStatefulWidget {
  const NotePage({super.key});
  @override
  ConsumerState<NotePage> createState() => _NotePageState();
}

class _NotePageState extends ConsumerState<NotePage> {
  final _editor = TextEditingController();
  String? _selectedId;
  String _query = '';
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _editor.dispose();
    super.dispose();
  }

  void _select(Note note) {
    _flush();
    setState(() {
      _selectedId = note.id;
      _editor.text = note.content;
    });
  }

  void _onChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (_selectedId != null) {
        ref.read(noteProvider.notifier).update(_selectedId!, v);
      }
    });
  }

  /// 立即写入未保存内容。
  void _flush() {
    _debounce?.cancel();
    if (_selectedId != null) {
      ref.read(noteProvider.notifier).update(_selectedId!, _editor.text);
    }
  }

  void _create() {
    _flush();
    final id = ref.read(noteProvider.notifier).create();
    setState(() {
      _selectedId = id;
      _editor.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final notes = ref.watch(noteProvider);
    final filtered = notes.where((n) {
      if (_query.isEmpty) return true;
      return n.content.toLowerCase().contains(_query.toLowerCase());
    }).toList();

    // 选中项若被删除则清空
    final selected =
        notes.where((n) => n.id == _selectedId).firstOrNull;
    if (_selectedId != null && selected == null) {
      _selectedId = null;
      _editor.clear();
    }

    return ToolScaffold(
      icon: Icons.bolt,
      title: '备忘快贴',
      subtitle: '灵感与代码片段的即时暂存区 · 本地持久化',
      actions: [
        FilledButton.icon(
          onPressed: _create,
          icon: const Icon(Icons.add, size: 16),
          label: const Text('新建'),
        ),
      ],
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 列表
          SizedBox(
            width: 260,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  onChanged: (v) => setState(() => _query = v),
                  decoration: const InputDecoration(
                    hintText: '搜索快贴…',
                    prefixIcon: Icon(Icons.search, size: 18),
                  ),
                ),
                const SizedBox(height: Dims.gapSm),
                Expanded(
                  child: notes.isEmpty
                      ? const EmptyState(
                          icon: Icons.bolt,
                          message: '还没有快贴',
                          hint: '点「新建」记录灵感')
                      : filtered.isEmpty
                          ? const EmptyState(
                              icon: Icons.search_off, message: '无匹配')
                          : ListView.builder(
                              itemCount: filtered.length,
                              itemBuilder: (ctx, i) =>
                                  _noteTile(p, filtered[i]),
                            ),
                ),
              ],
            ),
          ),
          Container(width: 1, color: p.border),
          const SizedBox(width: Dims.gapMd),
          // 编辑器
          Expanded(
            child: _selectedId == null
                ? Container(
                    decoration: BoxDecoration(
                      color: p.surfaceAlt,
                      border: Border.all(color: p.border),
                      borderRadius: BorderRadius.circular(Dims.radiusSm),
                    ),
                    child: const EmptyState(
                        icon: Icons.edit_note,
                        message: '选择或新建一条快贴开始记录'),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.bolt, size: 16, color: p.accent),
                          const SizedBox(width: 6),
                          Text('编辑中',
                              style: TextStyle(
                                  fontSize: 12, color: p.textSecondary)),
                          const Spacer(),
                          ToolbarButton(
                            icon: selected?.pinned == true
                                ? Icons.push_pin
                                : Icons.push_pin_outlined,
                            label: selected?.pinned == true ? '已置顶' : '置顶',
                            dense: true,
                            color: selected?.pinned == true ? p.accent : null,
                            onTap: () => ref
                                .read(noteProvider.notifier)
                                .togglePin(_selectedId!),
                          ),
                          CopyButton(
                              text: () => _editor.text, dense: true),
                          ToolbarButton(
                            icon: Icons.delete_outline,
                            label: '删除',
                            dense: true,
                            onTap: () {
                              ref
                                  .read(noteProvider.notifier)
                                  .remove(_selectedId!);
                              setState(() {
                                _selectedId = null;
                                _editor.clear();
                              });
                              showToast(context, '已删除');
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: Dims.gapSm),
                      Expanded(
                        child: CodeInput(
                          controller: _editor,
                          hint: '记录你的灵感、命令、代码片段…',
                          onChanged: _onChanged,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _noteTile(AppPalette p, Note note) {
    final active = note.id == _selectedId;
    return GestureDetector(
      onTap: () => _select(note),
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6, right: 4),
        padding: const EdgeInsets.symmetric(
            horizontal: Dims.gap, vertical: Dims.gapSm),
        decoration: BoxDecoration(
          color: active ? p.accentSoft : p.surface,
          border: Border.all(color: active ? p.accent : p.border),
          borderRadius: BorderRadius.circular(Dims.radiusSm),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (note.pinned)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Icon(Icons.push_pin, size: 12, color: p.accent),
                  ),
                Expanded(
                  child: Text(note.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: p.textPrimary)),
                ),
              ],
            ),
            if (note.preview.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(note.preview,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11.5, color: p.textSecondary)),
              ),
          ],
        ),
      ),
    );
  }
}

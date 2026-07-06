import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/layout/tool_scaffold.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_feedback.dart';
import '../../core/widgets/common.dart';
import 'todo_controller.dart';

class TodoPage extends ConsumerStatefulWidget {
  const TodoPage({super.key});
  @override
  ConsumerState<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends ConsumerState<TodoPage> {
  final _input = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _input.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _add() {
    ref.read(todoProvider.notifier).add(_input.text);
    _input.clear();
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final todos = ref.watch(todoProvider);
    final pending = todos.where((e) => !e.done).toList();
    final done = todos.where((e) => e.done).toList();

    return ToolScaffold(
      icon: Icons.checklist_rtl,
      title: 'TODO LIST',
      subtitle: '轻量任务清单 · 本地持久化',
      actions: [
        if (done.isNotEmpty)
          ToolbarButton(
              icon: Icons.cleaning_services_outlined,
              label: '清除已完成',
              dense: true,
              onTap: () => ref.read(todoProvider.notifier).clearDone()),
      ],
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      focusNode: _focus,
                      onSubmitted: (_) => _add(),
                      decoration: const InputDecoration(
                        hintText: '添加任务，回车确认…',
                        prefixIcon: Icon(Icons.add_task, size: 18),
                      ),
                    ),
                  ),
                  const SizedBox(width: Dims.gapSm),
                  FilledButton(onPressed: _add, child: const Text('添加')),
                ],
              ),
              const SizedBox(height: Dims.gapMd),
              if (todos.isEmpty)
                const Expanded(
                  child: EmptyState(
                      icon: Icons.task_alt,
                      message: '暂无任务',
                      hint: '在上方输入框添加你的第一条待办'),
                )
              else
                Expanded(
                  child: ListView(
                    children: [
                      ...pending.map((e) => _tile(p, e)),
                      if (done.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: Dims.gapSm, horizontal: 4),
                          child: Text('已完成 (${done.length})',
                              style: TextStyle(
                                  fontSize: 11.5,
                                  color: p.textSecondary,
                                  fontWeight: FontWeight.w600)),
                        ),
                        ...done.map((e) => _tile(p, e)),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tile(AppPalette p, TodoItem e) {
    return Container(
      margin: const EdgeInsets.only(bottom: Dims.gapSm),
      decoration: BoxDecoration(
        color: p.surface,
        border: Border.all(color: p.border),
        borderRadius: BorderRadius.circular(Dims.radiusSm),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Dims.gapSm, vertical: 2),
        child: Row(
          children: [
            Checkbox(
              value: e.done,
              onChanged: (_) => ref.read(todoProvider.notifier).toggle(e.id),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    e.text,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: e.done ? p.textSecondary : p.textPrimary,
                      decoration:
                          e.done ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  if (e.tag != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 3, bottom: 3),
                      child: StatusBadge(e.tag!, kind: BadgeKind.info),
                    ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.copy_all_outlined,
                  size: 16, color: p.textSecondary),
              tooltip: '复制',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: e.text));
                showToast(context, '已复制');
              },
            ),
            IconButton(
              icon: Icon(Icons.close, size: 16, color: p.textSecondary),
              tooltip: '删除',
              onPressed: () => ref.read(todoProvider.notifier).remove(e.id),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/kv_store.dart';

class TodoItem {
  final String id;
  final String text;
  final bool done;
  final String? tag;
  final int createdAt;

  const TodoItem({
    required this.id,
    required this.text,
    required this.done,
    this.tag,
    required this.createdAt,
  });

  TodoItem copyWith({bool? done}) => TodoItem(
        id: id,
        text: text,
        done: done ?? this.done,
        tag: tag,
        createdAt: createdAt,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'text': text,
        'done': done,
        'tag': tag,
        'createdAt': createdAt,
      };

  static TodoItem fromMap(Map map) => TodoItem(
        id: map['id'] as String,
        text: map['text'] as String,
        done: map['done'] as bool? ?? false,
        tag: map['tag'] as String?,
        createdAt: map['createdAt'] as int? ?? 0,
      );
}

class TodoController extends Notifier<List<TodoItem>> {
  dynamic get _box => KvStore.instance.todos;

  @override
  List<TodoItem> build() => _load();

  List<TodoItem> _load() {
    final items = <TodoItem>[];
    for (final e in _box.values) {
      items.add(TodoItem.fromMap(e as Map));
    }
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  void add(String text, {String? tag}) {
    final t = text.trim();
    if (t.isEmpty) return;
    final now = DateTime.now();
    final item = TodoItem(
      id: '${now.microsecondsSinceEpoch}',
      text: t,
      done: false,
      tag: tag,
      createdAt: now.millisecondsSinceEpoch,
    );
    _box.put(item.id, item.toMap());
    state = _load();
  }

  void toggle(String id) {
    final item = state.firstWhere((e) => e.id == id);
    final updated = item.copyWith(done: !item.done);
    _box.put(id, updated.toMap());
    state = _load();
  }

  void remove(String id) {
    _box.delete(id);
    state = _load();
  }

  void clearDone() {
    for (final e in state.where((e) => e.done)) {
      _box.delete(e.id);
    }
    state = _load();
  }
}

final todoProvider =
    NotifierProvider<TodoController, List<TodoItem>>(TodoController.new);

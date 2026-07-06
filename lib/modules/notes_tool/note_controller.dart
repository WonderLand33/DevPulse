import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/kv_store.dart';

class Note {
  final String id;
  final String content;
  final bool pinned;
  final int updatedAt;

  const Note({
    required this.id,
    required this.content,
    required this.pinned,
    required this.updatedAt,
  });

  /// 标题取第一行非空文本。
  String get title {
    for (final line in content.split('\n')) {
      final t = line.trim();
      if (t.isNotEmpty) return t.length > 40 ? '${t.substring(0, 40)}…' : t;
    }
    return '空白快贴';
  }

  String get preview {
    final lines = content.split('\n').where((l) => l.trim().isNotEmpty).toList();
    if (lines.length <= 1) return '';
    final rest = lines.sublist(1).join(' ');
    return rest.length > 60 ? '${rest.substring(0, 60)}…' : rest;
  }

  Note copyWith({String? content, bool? pinned, int? updatedAt}) => Note(
        id: id,
        content: content ?? this.content,
        pinned: pinned ?? this.pinned,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'content': content,
        'pinned': pinned,
        'updatedAt': updatedAt,
      };

  static Note fromMap(Map m) => Note(
        id: m['id'] as String,
        content: m['content'] as String? ?? '',
        pinned: m['pinned'] as bool? ?? false,
        updatedAt: m['updatedAt'] as int? ?? 0,
      );
}

class NoteController extends Notifier<List<Note>> {
  dynamic get _box => KvStore.instance.notes;

  @override
  List<Note> build() => _load();

  List<Note> _load() {
    final items = <Note>[];
    for (final e in _box.values) {
      items.add(Note.fromMap(e as Map));
    }
    // 置顶优先，其次按创建顺序（id=创建微秒）倒序。
    // 不按 updatedAt 排序，避免点击/编辑导致列表重排「乱跳」。
    items.sort((a, b) {
      if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
      final ai = int.tryParse(a.id) ?? 0;
      final bi = int.tryParse(b.id) ?? 0;
      return bi.compareTo(ai);
    });
    return items;
  }

  /// 新建并返回 id。
  String create({String content = ''}) {
    final now = DateTime.now();
    final note = Note(
      id: '${now.microsecondsSinceEpoch}',
      content: content,
      pinned: false,
      updatedAt: now.millisecondsSinceEpoch,
    );
    _box.put(note.id, note.toMap());
    state = _load();
    return note.id;
  }

  void update(String id, String content) {
    final existing = _box.get(id);
    if (existing == null) return;
    final note = Note.fromMap(existing as Map).copyWith(
      content: content,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    _box.put(id, note.toMap());
    state = _load();
  }

  void togglePin(String id) {
    final existing = _box.get(id);
    if (existing == null) return;
    final note = Note.fromMap(existing as Map);
    _box.put(id, note.copyWith(pinned: !note.pinned).toMap());
    state = _load();
  }

  void remove(String id) {
    _box.delete(id);
    state = _load();
  }
}

final noteProvider =
    NotifierProvider<NoteController, List<Note>>(NoteController.new);

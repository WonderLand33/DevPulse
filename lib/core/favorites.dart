import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'storage/kv_store.dart';

/// 工具收藏：有序的模块 id 列表，持久化到 settings box。
class FavoritesController extends Notifier<List<String>> {
  static const _key = 'favorites';

  @override
  List<String> build() {
    final raw = KvStore.instance.settings.get(_key);
    if (raw is List) return raw.cast<String>();
    return <String>[];
  }

  bool isFavorite(String id) => state.contains(id);

  void toggle(String id) {
    final next = List<String>.from(state);
    if (next.contains(id)) {
      next.remove(id);
    } else {
      next.add(id);
    }
    state = next;
    KvStore.instance.putSetting(_key, next);
  }
}

final favoritesProvider =
    NotifierProvider<FavoritesController, List<String>>(
        FavoritesController.new);

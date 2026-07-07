import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../modules/module.dart';
import '../../modules/registry.dart';
import '../favorites.dart';
import '../theme/app_theme.dart';

/// 左侧模块树 + 搜索 + 收藏。
class Sidebar extends ConsumerStatefulWidget {
  const Sidebar({super.key});
  @override
  ConsumerState<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends ConsumerState<Sidebar> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final selected = ref.watch(selectedModuleProvider);
    final favIds = ref.watch(favoritesProvider);

    final filtered =
        kModules.where((m) => m.matchesQuery(_query)).toList();
    final groups = <String, List<ToolModule>>{};
    for (final m in filtered) {
      groups.putIfAbsent(m.group, () => []).add(m);
    }

    // 收藏（按收藏顺序，且匹配搜索）
    final favModules = <ToolModule>[];
    for (final id in favIds) {
      final m = kModules.where((e) => e.id == id).firstOrNull;
      if (m != null && m.matchesQuery(_query)) favModules.add(m);
    }

    Widget tile(ToolModule m) => _ModuleTile(
          module: m,
          selected: m.id == selected,
          isFavorite: favIds.contains(m.id),
          onTap: () => ref.read(selectedModuleProvider.notifier).select(m.id),
          onToggleFav: () =>
              ref.read(favoritesProvider.notifier).toggle(m.id),
        );

    return Container(
      color: p.surfaceAlt,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 品牌
          Padding(
            padding: const EdgeInsets.fromLTRB(
                Dims.gapMd, Dims.gapMd, Dims.gapMd, Dims.gapSm),
            child: Row(
              children: [
                Icon(Icons.graphic_eq, color: p.accent, size: 22),
                const SizedBox(width: Dims.gapSm),
                Text('DevPulse',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: p.textPrimary,
                        letterSpacing: 0.2)),
                const Spacer(),
                Tooltip(
                  message: '100% 本地离线',
                  child: Icon(Icons.shield_outlined,
                      size: 15, color: p.success),
                ),
              ],
            ),
          ),
          // 搜索
          Padding(
            padding: const EdgeInsets.fromLTRB(Dims.gap, 0, Dims.gap, Dims.gapSm),
            child: TextField(
              controller: _search,
              onChanged: (v) => setState(() => _query = v),
              style: TextStyle(fontSize: 13, color: p.textPrimary),
              decoration: InputDecoration(
                hintText: '搜索工具…',
                prefixIcon: Icon(Icons.search, size: 18, color: p.textSecondary),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close, size: 15),
                        onPressed: () {
                          _search.clear();
                          setState(() => _query = '');
                        },
                      ),
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: Dims.gapSm),
              children: [
                if (favModules.isNotEmpty) ...[
                  _groupHeader(p, '★ 收藏'),
                  for (final m in favModules) tile(m),
                  const SizedBox(height: Dims.gapSm),
                ],
                for (final entry in groups.entries) ...[
                  _groupHeader(p, entry.key),
                  for (final m in entry.value) tile(m),
                ],
                if (filtered.isEmpty && favModules.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(Dims.gapLg),
                    child: Text('无匹配工具',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: p.textSecondary, fontSize: 12)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _groupHeader(AppPalette p, String title) => Padding(
        padding: const EdgeInsets.fromLTRB(
            Dims.gapMd, Dims.gap, Dims.gapMd, Dims.gapXs),
        child: Text(title.toUpperCase(),
            style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: p.textSecondary.withValues(alpha: 0.8))),
      );
}

class _ModuleTile extends StatefulWidget {
  final ToolModule module;
  final bool selected;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onToggleFav;
  const _ModuleTile({
    required this.module,
    required this.selected,
    required this.isFavorite,
    required this.onTap,
    required this.onToggleFav,
  });

  @override
  State<_ModuleTile> createState() => _ModuleTileState();
}

class _ModuleTileState extends State<_ModuleTile> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final m = widget.module;
    final bg = widget.selected
        ? p.accentSoft
        : (_hover ? p.border.withValues(alpha: 0.4) : Colors.transparent);
    final fg = widget.selected ? p.accent : p.textPrimary;
    final showStar = _hover || widget.isFavorite;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Dims.gapSm, vertical: 1),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: Dims.fast,
            padding:
                const EdgeInsets.symmetric(horizontal: Dims.gap, vertical: 8),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(Dims.radiusSm),
            ),
            child: Row(
              children: [
                Icon(m.icon,
                    size: 17,
                    color: widget.selected ? p.accent : p.textSecondary),
                const SizedBox(width: Dims.gap),
                Expanded(
                  child: Text(m.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 13,
                          color: fg,
                          fontWeight: widget.selected
                              ? FontWeight.w600
                              : FontWeight.w400)),
                ),
                // 收藏星标
                SizedBox(
                  width: 22,
                  child: showStar
                      ? InkWell(
                          borderRadius: BorderRadius.circular(4),
                          onTap: widget.onToggleFav,
                          child: Tooltip(
                            message: widget.isFavorite ? '取消收藏' : '收藏',
                            child: Icon(
                              widget.isFavorite
                                  ? Icons.star
                                  : Icons.star_border,
                              size: 16,
                              color: widget.isFavorite
                                  ? p.warning
                                  : p.textSecondary,
                            ),
                          ),
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

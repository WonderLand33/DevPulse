import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/layout/tool_scaffold.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/actions.dart';
import '../../core/widgets/common.dart';
import 'unix_time_logic.dart';

class UnixTimePage extends ConsumerStatefulWidget {
  const UnixTimePage({super.key});
  @override
  ConsumerState<UnixTimePage> createState() => _UnixTimePageState();
}

class _UnixTimePageState extends ConsumerState<UnixTimePage> {
  final _input = TextEditingController();
  String _unit = 'auto';
  Timer? _clock;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(seconds: 1),
        (_) => setState(() => _now = DateTime.now()));
  }

  @override
  void dispose() {
    _clock?.cancel();
    _input.dispose();
    super.dispose();
  }

  void _now_() {
    _input.text = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
    setState(() {});
  }

  Future<void> _fromClipboard() async {
    final d = await Clipboard.getData(Clipboard.kTextPlain);
    if (d?.text != null) {
      _input.text = d!.text!.trim();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final ms = UnixTimeLogic.parse(_input.text, unit: _unit);
    final info = ms != null ? UnixTimeLogic.fromMs(ms) : null;

    return ToolScaffold(
      icon: Icons.schedule,
      title: 'Unix 时间转换',
      subtitle: '时间戳 ↔ 可读时间 · 秒/毫秒自动识别 · 支持加减运算',
      actions: [
        ToolbarButton(
            icon: Icons.bolt, label: 'Now', dense: true, onTap: _now_),
        ToolbarButton(
            icon: Icons.content_paste_outlined,
            label: 'Clipboard',
            dense: true,
            onTap: _fromClipboard),
        ClearButton(
            dense: true, onClear: () => setState(() => _input.clear())),
      ],
      body: ListView(
        children: [
          _liveClock(p),
          const SizedBox(height: Dims.gapMd),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _input,
                  onChanged: (_) => setState(() {}),
                  style: context.mono(size: 15),
                  decoration: const InputDecoration(
                    hintText: '输入时间戳，或 1700000000 + 3600',
                    prefixIcon: Icon(Icons.tag, size: 18),
                  ),
                ),
              ),
              const SizedBox(width: Dims.gap),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'auto', label: Text('自动')),
                  ButtonSegment(value: 'sec', label: Text('秒')),
                  ButtonSegment(value: 'ms', label: Text('毫秒')),
                ],
                selected: {_unit},
                showSelectedIcon: false,
                onSelectionChanged: (s) => setState(() => _unit = s.first),
              ),
            ],
          ),
          const SizedBox(height: Dims.gapMd),
          if (info == null)
            const SectionCard(
              child: EmptyState(
                  icon: Icons.schedule,
                  message: '输入时间戳查看多维时间信息'),
            )
          else
            _details(p, info),
        ],
      ),
    );
  }

  Widget _liveClock(AppPalette p) {
    final nowSec = _now.millisecondsSinceEpoch ~/ 1000;
    return Container(
      padding: const EdgeInsets.all(Dims.gapMd),
      decoration: BoxDecoration(
        color: p.surface,
        border: Border.all(color: p.border),
        borderRadius: BorderRadius.circular(Dims.radius),
      ),
      child: Row(
        children: [
          Icon(Icons.access_time_filled, color: p.accent, size: 20),
          const SizedBox(width: Dims.gap),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('当前时间',
                  style: TextStyle(fontSize: 11.5, color: p.textSecondary)),
              Text(UnixTimeLogic.fmt(_now),
                  style: context.mono(size: 15, weight: FontWeight.w600)),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('当前时间戳（秒）',
                  style: TextStyle(fontSize: 11.5, color: p.textSecondary)),
              Row(
                children: [
                  SelectableText('$nowSec',
                      style: context.mono(
                          size: 15, color: p.accent, weight: FontWeight.w600)),
                  CopyButton(text: () => '$nowSec', label: '', dense: true),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _details(AppPalette p, UnixTimeInfo info) {
    return SectionCard(
      title: '解析结果',
      icon: Icons.event_note,
      child: Column(
        children: [
          ResultRow(
              label: '本地时间', value: UnixTimeLogic.fmt(info.local), mono: true),
          ResultRow(
              label: 'UTC 时间', value: UnixTimeLogic.fmt(info.utc), mono: true),
          ResultRow(
              label: 'ISO-8601',
              value: info.utc.toIso8601String(),
              mono: true),
          ResultRow(
              label: '时间戳（秒）', value: '${info.epochSec}', mono: true),
          ResultRow(
              label: '时间戳（毫秒）', value: '${info.epochMs}', mono: true),
          const Divider(height: Dims.gapLg),
          ResultRow(label: '星期', value: info.weekdayName, copyable: false),
          ResultRow(
              label: '一年中第几天',
              value: '第 ${info.dayOfYear} 天',
              copyable: false),
          ResultRow(
              label: '一年中第几周',
              value: '第 ${info.weekOfYear} 周',
              copyable: false),
          ResultRow(
              label: '相对现在',
              value: UnixTimeLogic.relative(info.local, _now),
              valueColor: p.accent,
              copyable: false),
        ],
      ),
    );
  }
}

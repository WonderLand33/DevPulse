import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/layout/tool_scaffold.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/actions.dart';
import '../../core/widgets/common.dart';
import '../unix_time/unix_time_logic.dart';
import 'cron_logic.dart';

class CronPage extends ConsumerStatefulWidget {
  const CronPage({super.key});
  @override
  ConsumerState<CronPage> createState() => _CronPageState();
}

class _CronPageState extends ConsumerState<CronPage> {
  final _input = TextEditingController(text: '0 4 * * 1');

  static const _examples = [
    ('*/5 * * * *', '每 5 分钟'),
    ('0 4 * * 1', '每周一 04:00'),
    ('0 0 1 * *', '每月 1 日 0 点'),
    ('30 9 * * 1-5', '工作日 9:30'),
    ('0 */2 * * *', '每 2 小时'),
    ('0 0 * * 0', '每周日午夜'),
  ];

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    CronExpr? expr;
    String? error;
    List<DateTime> nextTimes = const [];
    String description = '';

    final text = _input.text.trim();
    if (text.isNotEmpty) {
      try {
        expr = CronExpr.parse(text);
        description = CronDescribe.describe(expr);
        nextTimes = expr.next(DateTime.now(), 5);
      } on CronParseException catch (e) {
        error = e.message;
      } catch (e) {
        error = e.toString();
      }
    }

    return ToolScaffold(
      icon: Icons.timer_outlined,
      title: 'Cron 表达式',
      subtitle: '自然语言解析 · 预测未来 5 次执行 · 支持 5/6 段',
      actions: [
        PasteButton(controller: _input, dense: true, onPasted: () => setState(() {})),
      ],
      body: ListView(
        children: [
          TextField(
            controller: _input,
            onChanged: (_) => setState(() {}),
            style: context.mono(size: 18, weight: FontWeight.w600),
            decoration: const InputDecoration(
              hintText: '分 时 日 月 周（如 0 4 * * 1）',
              prefixIcon: Icon(Icons.timer, size: 20),
            ),
          ),
          const SizedBox(height: Dims.gapSm),
          Wrap(
            spacing: Dims.gapSm,
            runSpacing: Dims.gapSm,
            children: [
              for (final e in _examples)
                ActionChip(
                  label: Text(e.$1, style: context.mono(size: 11.5)),
                  onPressed: () {
                    _input.text = e.$1;
                    setState(() {});
                  },
                ),
            ],
          ),
          const SizedBox(height: Dims.gapMd),
          if (error != null)
            _errorCard(p, error)
          else if (expr != null) ...[
            _descCard(p, description, expr.hasSeconds),
            const SizedBox(height: Dims.gapMd),
            _nextCard(p, nextTimes),
          ],
        ],
      ),
    );
  }

  Widget _descCard(AppPalette p, String desc, bool hasSeconds) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Dims.gapLg),
      decoration: BoxDecoration(
        color: p.accentSoft,
        border: Border.all(color: p.accent.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(Dims.radius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.translate, size: 16, color: p.accent),
              const SizedBox(width: Dims.gapSm),
              Text('自然语言',
                  style: TextStyle(
                      fontSize: 12,
                      color: p.accent,
                      fontWeight: FontWeight.w600)),
              const Spacer(),
              StatusBadge(hasSeconds ? '6 段（含秒）' : '5 段',
                  kind: BadgeKind.info),
            ],
          ),
          const SizedBox(height: Dims.gapSm),
          Text(desc,
              style: TextStyle(
                  fontSize: 18,
                  color: p.textPrimary,
                  fontWeight: FontWeight.w600,
                  height: 1.4)),
        ],
      ),
    );
  }

  Widget _nextCard(AppPalette p, List<DateTime> times) {
    return SectionCard(
      title: '接下来 5 次执行',
      icon: Icons.event_repeat,
      child: times.isEmpty
          ? Text('未来一段时间内无匹配执行时间',
              style: TextStyle(color: p.textSecondary, fontSize: 13))
          : Column(
              children: [
                for (var i = 0; i < times.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: p.surfaceAlt,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('${i + 1}',
                              style: TextStyle(
                                  fontSize: 11, color: p.textSecondary)),
                        ),
                        const SizedBox(width: Dims.gap),
                        Text(UnixTimeLogic.fmt(times[i]),
                            style: context.mono(size: 13.5)),
                        const SizedBox(width: Dims.gap),
                        Text(_weekday(times[i]),
                            style: TextStyle(
                                fontSize: 12, color: p.textSecondary)),
                        const Spacer(),
                        Text(UnixTimeLogic.relative(times[i], DateTime.now()),
                            style: TextStyle(
                                fontSize: 12.5,
                                color: p.accent,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }

  String _weekday(DateTime d) =>
      const ['周一', '周二', '周三', '周四', '周五', '周六', '周日'][d.weekday - 1];

  Widget _errorCard(AppPalette p, String msg) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(Dims.gapMd),
        decoration: BoxDecoration(
          color: p.danger.withValues(alpha: 0.12),
          border: Border.all(color: p.danger.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(Dims.radius),
        ),
        child: Row(children: [
          Icon(Icons.error_outline, size: 18, color: p.danger),
          const SizedBox(width: Dims.gapSm),
          Expanded(
              child: Text(msg,
                  style: TextStyle(color: p.danger, fontSize: 13))),
        ]),
      );
}

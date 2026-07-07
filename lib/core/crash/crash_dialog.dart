import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_theme.dart';
import '../widgets/app_feedback.dart';
import 'crash_log.dart';

const kIssuesUrl = 'https://github.com/WonderLand33/DevPulse/issues';

/// 全局导航 key：异常发生的位置通常没有可用的 BuildContext，
/// 借助它可以从任意地方（包括错误处理回调里）弹出对话框。
final GlobalKey<NavigatorState> crashNavigatorKey = GlobalKey<NavigatorState>();

bool _dialogShowing = false;

/// 记录一条异常到本地日志，并（若当前没有其它崩溃弹窗在显示）弹出提示。
///
/// 注意：这里只能捕获 Dart/Flutter 层面能感知到的异常（未捕获的
/// exception、组件构建报错等）。如果是导致整个进程直接终止的原生级
/// 崩溃，应用来不及渲染任何界面，这个弹窗也无能为力——那种情况只能
/// 依赖本地日志文件本身（下次启动后仍可在设置页里找到）。
Future<void> reportCrash(Object error, StackTrace stack,
    {String source = 'unknown'}) async {
  String entry;
  try {
    entry = await CrashLog.instance.record(error, stack, source: source);
  } catch (_) {
    return;
  }
  try {
    // context 在此处才刚取得（GlobalKey.currentContext），取完立即使用，
    // 与上面那次 await 之间没有真正的间隔，是安全的。
    final context = crashNavigatorKey.currentContext;
    if (context == null || _dialogShowing) return;
    _dialogShowing = true;
    await showDialog<void>(
      // ignore: use_build_context_synchronously
      context: context,
      barrierDismissible: true,
      builder: (_) => _CrashDialog(logText: entry),
    );
  } catch (_) {
    // 弹窗本身出问题也不应再向上抛出，避免二次触发错误处理。
  } finally {
    _dialogShowing = false;
  }
}

class _CrashDialog extends StatelessWidget {
  final String logText;
  const _CrashDialog({required this.logText});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.bug_report_outlined, color: p.danger, size: 20),
          const SizedBox(width: Dims.gapSm),
          const Text('应用出现了一个错误'),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '已自动记录到本地日志（不会联网上传）。可以复制日志内容，'
              '或直接反馈到 GitHub Issues。',
              style: TextStyle(fontSize: 12.5, color: p.textSecondary),
            ),
            const SizedBox(height: Dims.gap),
            Container(
              constraints: const BoxConstraints(maxHeight: 220),
              width: double.infinity,
              padding: const EdgeInsets.all(Dims.gapSm),
              decoration: BoxDecoration(
                color: p.surfaceAlt,
                border: Border.all(color: p.border),
                borderRadius: BorderRadius.circular(Dims.radiusSm),
              ),
              child: SingleChildScrollView(
                child: SelectableText(logText,
                    style: context.mono(size: 11.5)),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: logText));
            if (context.mounted) showToast(context, '已复制日志');
          },
          child: const Text('复制日志'),
        ),
        TextButton(
          onPressed: () =>
              launchUrl(Uri.parse(kIssuesUrl), mode: LaunchMode.externalApplication),
          child: const Text('反馈到 GitHub Issues'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('关闭'),
        ),
      ],
    );
  }
}

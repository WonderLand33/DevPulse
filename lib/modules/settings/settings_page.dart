import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/crash/crash_dialog.dart';
import '../../core/crash/crash_log.dart';
import '../../core/layout/tool_scaffold.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_controller.dart';
import '../../core/widgets/app_feedback.dart';
import '../../core/widgets/common.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final mode = ref.watch(themeModeProvider);
    final scale = ref.watch(fontScaleProvider);
    final uiFont = ref.watch(uiFontProvider);
    final monoFont = ref.watch(monoFontProvider);

    return ToolScaffold(
      icon: Icons.tune,
      title: '设置',
      subtitle: '外观 · 隐私 · 关于',
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            children: [
              SectionCard(
                title: '外观',
                icon: Icons.palette_outlined,
                child: Column(
                  children: [
                    _row(
                      p,
                      '主题模式',
                      SegmentedButton<ThemeMode>(
                        segments: const [
                          ButtonSegment(
                              value: ThemeMode.light,
                              icon: Icon(Icons.light_mode, size: 15),
                              label: Text('浅色')),
                          ButtonSegment(
                              value: ThemeMode.dark,
                              icon: Icon(Icons.dark_mode, size: 15),
                              label: Text('深色')),
                          ButtonSegment(
                              value: ThemeMode.system,
                              icon: Icon(Icons.brightness_auto, size: 15),
                              label: Text('跟随系统')),
                        ],
                        selected: {mode},
                        showSelectedIcon: false,
                        onSelectionChanged: (s) =>
                            ref.read(themeModeProvider.notifier).set(s.first),
                      ),
                    ),
                    const Divider(height: Dims.gapLg),
                    _row(
                      p,
                      '界面字体',
                      _fontDropdown(
                        context,
                        value: uiFont,
                        choices: kUiFontChoices,
                        onChanged: (v) =>
                            ref.read(uiFontProvider.notifier).set(v),
                      ),
                    ),
                    const Divider(height: Dims.gapLg),
                    _row(
                      p,
                      '等宽字体',
                      _fontDropdown(
                        context,
                        value: monoFont,
                        choices: kMonoFontChoices,
                        mono: true,
                        onChanged: (v) =>
                            ref.read(monoFontProvider.notifier).set(v),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        '字体未安装时会自动回退到系统默认（Windows / macOS 通用）。',
                        style:
                            TextStyle(fontSize: 11.5, color: p.textSecondary),
                      ),
                    ),
                    const Divider(height: Dims.gapLg),
                    _row(
                      p,
                      '字号缩放',
                      SizedBox(
                        width: 260,
                        child: Row(
                          children: [
                            Expanded(
                              child: Slider(
                                value: scale,
                                min: 0.85,
                                max: 1.35,
                                divisions: 10,
                                label: '${(scale * 100).round()}%',
                                onChanged: (v) => ref
                                    .read(fontScaleProvider.notifier)
                                    .set(v),
                              ),
                            ),
                            Text('${(scale * 100).round()}%',
                                style: TextStyle(
                                    fontSize: 12, color: p.textSecondary)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Dims.gapMd),
              const _CrashLogCard(),
              const SizedBox(height: Dims.gapMd),
              _aboutCard(p),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(AppPalette p, String label, Widget control) {
    return Row(
      children: [
        Expanded(
            child: Text(label,
                style: TextStyle(fontSize: 13.5, color: p.textPrimary))),
        control,
      ],
    );
  }

  Widget _fontDropdown(
    BuildContext context, {
    required String? value,
    required List<String> choices,
    required ValueChanged<String?> onChanged,
    bool mono = false,
  }) {
    final p = context.palette;
    return SizedBox(
      width: 220,
      child: DropdownButtonFormField<String>(
        initialValue: value,
        isExpanded: true,
        decoration: const InputDecoration(isDense: true),
        style: mono
            ? context.mono(size: 13)
            : TextStyle(fontSize: 13, color: p.textPrimary),
        items: [
          const DropdownMenuItem(value: null, child: Text('系统默认')),
          ...choices.map((f) => DropdownMenuItem(
                value: f,
                child: Text(f,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontFamily: f, fontSize: 13, color: p.textPrimary)),
              )),
        ],
        onChanged: onChanged,
      ),
    );
  }

  Widget _aboutCard(AppPalette p) {
    return SectionCard(
      title: '关于 DevPulse',
      icon: Icons.info_outline,
      child: Row(
        children: [
          Icon(Icons.graphic_eq, color: p.accent, size: 22),
          const SizedBox(width: Dims.gapSm),
          Text('DevPulse',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: p.textPrimary)),
          const SizedBox(width: Dims.gapSm),
          StatusBadge('v1.3', kind: BadgeKind.info),
          const Spacer(),
          Text('跨平台开发者工具箱 · 100% 本地离线',
              style: TextStyle(fontSize: 12.5, color: p.textSecondary)),
        ],
      ),
    );
  }
}

/// 崩溃日志：展示本地日志文件位置，并可一键复制全部内容 / 反馈到 Issues。
/// 主要用于原生级崩溃（应用来不及弹出错误对话框）之后，事后排查。
class _CrashLogCard extends StatefulWidget {
  const _CrashLogCard();
  @override
  State<_CrashLogCard> createState() => _CrashLogCardState();
}

class _CrashLogCardState extends State<_CrashLogCard> {
  String? _path;
  String _content = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final path = await CrashLog.instance.filePath;
    final content = await CrashLog.instance.readAll();
    if (!mounted) return;
    setState(() {
      _path = path;
      _content = content;
      _loading = false;
    });
  }

  int get _entryCount => _content
      .split('-' * 60)
      .where((s) => s.trim().isNotEmpty)
      .length;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SectionCard(
      title: '崩溃日志',
      icon: Icons.bug_report_outlined,
      child: _loading
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: Dims.gapSm),
              child: LinearProgressIndicator(),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ResultRow(label: '文件位置', value: _path ?? '', mono: true),
                const SizedBox(height: 2),
                Text(
                  _content.isEmpty ? '暂无记录，出现异常时会自动写入这里' : '已记录 $_entryCount 条异常',
                  style: TextStyle(fontSize: 12.5, color: p.textSecondary),
                ),
                if (_content.isNotEmpty) ...[
                  const SizedBox(height: Dims.gapSm),
                  Wrap(
                    spacing: Dims.gapSm,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () async {
                          await Clipboard.setData(
                              ClipboardData(text: _content));
                          if (context.mounted) showToast(context, '已复制全部日志');
                        },
                        icon: const Icon(Icons.copy_all_outlined, size: 15),
                        label: const Text('复制全部日志'),
                      ),
                      TextButton(
                        onPressed: () => launchUrl(Uri.parse(kIssuesUrl),
                            mode: LaunchMode.externalApplication),
                        child: const Text('反馈到 GitHub Issues'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
    );
  }
}

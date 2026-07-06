import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:markdown_widget/markdown_widget.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../core/layout/tool_scaffold.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/actions.dart';
import '../../core/widgets/code_field.dart';
import '../../core/widgets/common.dart';
import 'markdown_logic.dart';

const _sample = '''# DevPulse Markdown

支持 **GFM 标准**、代码高亮与实时预览。

## 特性
- 左侧编辑，右侧同步渲染
- 一键导出 **HTML** / **PDF**
- 100% 本地渲染

```dart
void main() {
  print('Hello DevPulse');
}
```

> 提示：右上角可导出文件。

| 模块 | 状态 |
| --- | --- |
| Markdown | ✅ |
''';

class MarkdownPage extends ConsumerStatefulWidget {
  const MarkdownPage({super.key});
  @override
  ConsumerState<MarkdownPage> createState() => _MarkdownPageState();
}

class _MarkdownPageState extends ConsumerState<MarkdownPage> {
  final _input = TextEditingController(text: _sample);

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _exportHtml() async {
    final html = MarkdownLogic.toHtml(_input.text);
    final loc = await getSaveLocation(
      suggestedName: 'document.html',
      acceptedTypeGroups: [
        const XTypeGroup(label: 'HTML', extensions: ['html'])
      ],
    );
    if (loc == null) return;
    await File(loc.path).writeAsString(html);
    if (mounted) _toast('已导出 HTML');
  }

  Future<void> _exportPdf() async {
    final font = await _loadCjkFont();
    final bytes = await MarkdownLogic.toPdf(_input.text, cjkFont: font);
    final loc = await getSaveLocation(
      suggestedName: 'document.pdf',
      acceptedTypeGroups: [
        const XTypeGroup(label: 'PDF', extensions: ['pdf'])
      ],
    );
    if (loc == null) return;
    await File(loc.path).writeAsBytes(bytes);
    if (mounted) {
      _toast(font == null
          ? '已导出 PDF（未找到系统中文字体，中文可能缺字）'
          : '已导出 PDF');
    }
  }

  /// 尝试加载系统中文 TTF 字体供 PDF 使用（离线，仅读本机已装字体）。
  Future<pw.Font?> _loadCjkFont() async {
    const candidates = [
      r'C:\Windows\Fonts\msyh.ttf',
      r'C:\Windows\Fonts\simhei.ttf',
      r'C:\Windows\Fonts\Deng.ttf',
      '/System/Library/Fonts/PingFang.ttc',
    ];
    for (final path in candidates) {
      try {
        final file = File(path);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          return pw.Font.ttf(bytes.buffer.asByteData());
        }
      } catch (_) {
        // 尝试下一个
      }
    }
    return null;
  }

  void _toast(String m) => ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final dark = Theme.of(context).brightness == Brightness.dark;

    return ToolScaffold(
      icon: Icons.article_outlined,
      title: 'Markdown 渲染',
      subtitle: '实时预览 · 导出 HTML / PDF',
      actions: [
        PasteButton(controller: _input, dense: true, onPasted: () => setState(() {})),
        ToolbarButton(
            icon: Icons.html, label: '导出 HTML', dense: true, onTap: _exportHtml),
        ToolbarButton(
            icon: Icons.picture_as_pdf_outlined,
            label: '导出 PDF',
            dense: true,
            onTap: _exportPdf),
      ],
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: CodeInput(
              controller: _input,
              hint: '在此编写 Markdown…',
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(width: Dims.gap),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: p.surface,
                border: Border.all(color: p.border),
                borderRadius: BorderRadius.circular(Dims.radiusSm),
              ),
              clipBehavior: Clip.antiAlias,
              child: _input.text.trim().isEmpty
                  ? const EmptyState(
                      icon: Icons.article_outlined, message: '预览显示在这里')
                  : Markdown(
                      key: ValueKey(dark),
                      data: _input.text,
                      dark: dark,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 封装 markdown_widget，套用主题背景内边距。
class Markdown extends StatelessWidget {
  final String data;
  final bool dark;
  const Markdown({super.key, required this.data, required this.dark});

  @override
  Widget build(BuildContext context) {
    return MarkdownWidget(
      data: data,
      padding: const EdgeInsets.all(Dims.gapMd),
      config: dark ? MarkdownConfig.darkConfig : MarkdownConfig.defaultConfig,
    );
  }
}

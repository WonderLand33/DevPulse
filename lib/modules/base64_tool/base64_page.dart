import 'dart:io';
import 'dart:typed_data';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pasteboard/pasteboard.dart';

import '../../core/layout/tool_scaffold.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/actions.dart';
import '../../core/widgets/app_feedback.dart';
import '../../core/widgets/code_field.dart';
import '../../core/widgets/common.dart';
import 'base64_logic.dart';

class Base64Page extends ConsumerStatefulWidget {
  const Base64Page({super.key});
  @override
  ConsumerState<Base64Page> createState() => _Base64PageState();
}

class _Base64PageState extends ConsumerState<Base64Page> {
  bool _imageMode = false;

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      icon: Icons.transform,
      title: 'Base64 工具箱',
      subtitle: '文本 / 图片 ↔ Base64 · UTF-8 / GBK · DataURL',
      actions: [
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(
                value: false,
                icon: Icon(Icons.text_fields, size: 15),
                label: Text('文本')),
            ButtonSegment(
                value: true,
                icon: Icon(Icons.image_outlined, size: 15),
                label: Text('图片')),
          ],
          selected: {_imageMode},
          showSelectedIcon: false,
          onSelectionChanged: (s) => setState(() => _imageMode = s.first),
        ),
      ],
      // IndexedStack 让两个子页始终保持挂载，切换 tab 不清空已输入的内容。
      body: IndexedStack(
        index: _imageMode ? 1 : 0,
        children: const [_TextTab(), _ImageTab()],
      ),
    );
  }
}

// ---------------- 文本模式 ----------------
class _TextTab extends ConsumerStatefulWidget {
  const _TextTab();
  @override
  ConsumerState<_TextTab> createState() => _TextTabState();
}

class _TextTabState extends ConsumerState<_TextTab> {
  final _input = TextEditingController();
  bool _decode = false;
  bool _gbk = false;
  String _output = '';
  String? _error;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _run() {
    setState(() {
      _error = null;
      if (_decode) {
        final r = Base64Logic.decodeText(_input.text, gbk: _gbk);
        _output = r.text ?? '';
        _error = r.error;
      } else {
        _output = Base64Logic.encodeText(_input.text, gbk: _gbk);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('编码')),
                ButtonSegment(value: true, label: Text('解码')),
              ],
              selected: {_decode},
              showSelectedIcon: false,
              onSelectionChanged: (s) {
                setState(() => _decode = s.first);
                _run();
              },
            ),
            const SizedBox(width: Dims.gapMd),
            FilterChip(
              label: const Text('GBK 编码'),
              selected: _gbk,
              onSelected: (v) {
                setState(() => _gbk = v);
                _run();
              },
            ),
            const Spacer(),
            PasteButton(controller: _input, dense: true, onPasted: _run),
            CopyButton(text: () => _output, dense: true),
          ],
        ),
        const SizedBox(height: Dims.gap),
        if (_error != null) _errBanner(p, _error!),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: CodeInput(
                  controller: _input,
                  hint: _decode ? '粘贴 Base64…' : '输入要编码的文本…',
                  onChanged: (_) => _run(),
                ),
              ),
              const SizedBox(width: Dims.gap),
              Expanded(
                child: _output.isEmpty
                    ? Container(
                        decoration: BoxDecoration(
                          color: p.surfaceAlt,
                          border: Border.all(color: p.border),
                          borderRadius: BorderRadius.circular(Dims.radiusSm),
                        ),
                        child: const EmptyState(
                            icon: Icons.transform, message: '结果显示在这里'),
                      )
                    : CodeInput(
                        controller:
                            TextEditingController(text: _output),
                        readOnly: true,
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _errBanner(AppPalette p, String msg) => Container(
        margin: const EdgeInsets.only(bottom: Dims.gap),
        padding: const EdgeInsets.symmetric(
            horizontal: Dims.gap, vertical: Dims.gapSm),
        decoration: BoxDecoration(
          color: p.danger.withValues(alpha: 0.12),
          border: Border.all(color: p.danger.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(Dims.radiusSm),
        ),
        child: Row(children: [
          Icon(Icons.error_outline, size: 16, color: p.danger),
          const SizedBox(width: Dims.gapSm),
          Expanded(
              child: Text(msg,
                  style: TextStyle(color: p.danger, fontSize: 12.5))),
        ]),
      );
}

// ---------------- 图片模式 ----------------
class _ImageTab extends ConsumerStatefulWidget {
  const _ImageTab();
  @override
  ConsumerState<_ImageTab> createState() => _ImageTabState();
}

class _ImageTabState extends ConsumerState<_ImageTab> {
  final _b64 = TextEditingController();
  Uint8List? _bytes;
  String _mime = 'image/png';
  bool _dragging = false;

  @override
  void dispose() {
    _b64.dispose();
    super.dispose();
  }

  void _setBytes(Uint8List bytes, String mime) {
    setState(() {
      _bytes = bytes;
      _mime = mime;
      _b64.text = Base64Logic.toDataUrl(bytes, mime);
    });
  }

  Future<void> _pickImage() async {
    const group = XTypeGroup(
        label: '图片', extensions: ['png', 'jpg', 'jpeg', 'gif', 'webp', 'bmp']);
    final file = await openFile(acceptedTypeGroups: [group]);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    _setBytes(bytes, Base64Logic.mimeFromExtension(file.name));
  }

  Future<void> _pasteImage() async {
    final bytes = await Pasteboard.image;
    if (bytes == null) {
      if (mounted) showToast(context, '剪贴板没有图片', error: true);
      return;
    }
    _setBytes(bytes, 'image/png');
  }

  void _decodeFromText() {
    final bytes = Base64Logic.decodeImage(_b64.text);
    if (bytes == null) {
      showToast(context, '无法解析为图片', error: true);
      return;
    }
    setState(() => _bytes = bytes);
  }

  Future<void> _save() async {
    if (_bytes == null) return;
    final ext = _mime.split('/').last;
    final location = await getSaveLocation(
      suggestedName: 'image.$ext',
      acceptedTypeGroups: [
        XTypeGroup(label: '图片', extensions: [ext])
      ],
    );
    if (location == null) return;
    await File(location.path).writeAsBytes(_bytes!);
    if (mounted) showToast(context, '已保存到 ${location.path}');
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 左：图片来源与预览
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  FilledButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.folder_open, size: 16),
                      label: const Text('选择图片')),
                  const SizedBox(width: Dims.gapSm),
                  OutlinedButton.icon(
                      onPressed: _pasteImage,
                      icon: const Icon(Icons.content_paste, size: 16),
                      label: const Text('粘贴图片')),
                  const Spacer(),
                  if (_bytes != null)
                    OutlinedButton.icon(
                        onPressed: _save,
                        icon: const Icon(Icons.download, size: 16),
                        label: const Text('保存')),
                ],
              ),
              const SizedBox(height: Dims.gap),
              Expanded(
                child: DropTarget(
                  onDragEntered: (_) => setState(() => _dragging = true),
                  onDragExited: (_) => setState(() => _dragging = false),
                  onDragDone: (d) async {
                    setState(() => _dragging = false);
                    if (d.files.isEmpty) return;
                    final f = d.files.first;
                    final bytes = await File(f.path).readAsBytes();
                    _setBytes(bytes, Base64Logic.mimeFromExtension(f.name));
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: p.surfaceAlt,
                      border: Border.all(
                          color: _dragging ? p.accent : p.border,
                          width: _dragging ? 1.5 : 1),
                      borderRadius: BorderRadius.circular(Dims.radiusSm),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _bytes == null
                        ? const EmptyState(
                            icon: Icons.image_outlined,
                            message: '拖入图片，或选择/粘贴',
                            hint: '生成 Base64 DataURL')
                        : InteractiveViewer(
                            child: Center(
                              child: Image.memory(_bytes!,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, e, s) => const EmptyState(
                                      icon: Icons.broken_image_outlined,
                                      message: '图片数据无效')),
                            ),
                          ),
                  ),
                ),
              ),
              if (_bytes != null)
                Padding(
                  padding: const EdgeInsets.only(top: Dims.gapSm),
                  child: Text(
                      '$_mime · ${(_bytes!.lengthInBytes / 1024).toStringAsFixed(1)} KB',
                      style:
                          TextStyle(fontSize: 12, color: p.textSecondary)),
                ),
            ],
          ),
        ),
        const SizedBox(width: Dims.gap),
        // 右：Base64/DataURL 文本
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text('Base64 / DataURL',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: p.textPrimary)),
                  const Spacer(),
                  PasteButton(controller: _b64, dense: true),
                  ToolbarButton(
                      icon: Icons.image,
                      label: '解码为图片',
                      dense: true,
                      onTap: _decodeFromText),
                  CopyButton(text: () => _b64.text, dense: true),
                ],
              ),
              const SizedBox(height: Dims.gap),
              Expanded(
                child: CodeInput(
                  controller: _b64,
                  hint: '这里显示 DataURL，或粘贴 Base64 后点「解码为图片」',
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

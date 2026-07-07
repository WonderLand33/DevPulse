import 'dart:io';
import 'dart:ui' as ui;

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/layout/tool_scaffold.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_feedback.dart';
import '../../core/widgets/code_field.dart';
import '../../core/widgets/common.dart';
import 'qr_logic.dart';

class QrPage extends ConsumerStatefulWidget {
  const QrPage({super.key});
  @override
  ConsumerState<QrPage> createState() => _QrPageState();
}

class _QrPageState extends ConsumerState<QrPage> {
  bool _decodeMode = false;

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      icon: Icons.qr_code_2,
      title: 'QR 二维码工具',
      subtitle: '生成（可调容错/配色/Logo）· 解码（拖入/粘贴/文件）',
      actions: [
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(
                value: false,
                icon: Icon(Icons.qr_code, size: 15),
                label: Text('生成')),
            ButtonSegment(
                value: true,
                icon: Icon(Icons.qr_code_scanner, size: 15),
                label: Text('解码')),
          ],
          selected: {_decodeMode},
          showSelectedIcon: false,
          onSelectionChanged: (s) => setState(() => _decodeMode = s.first),
        ),
      ],
      // IndexedStack 让两个子页始终保持挂载，切换 tab 不清空已输入的内容。
      body: IndexedStack(
        index: _decodeMode ? 1 : 0,
        children: const [_GenerateTab(), _DecodeTab()],
      ),
    );
  }
}

// ---------------- 生成 ----------------
class _GenerateTab extends ConsumerStatefulWidget {
  const _GenerateTab();
  @override
  ConsumerState<_GenerateTab> createState() => _GenerateTabState();
}

class _GenerateTabState extends ConsumerState<_GenerateTab> {
  final _input = TextEditingController(text: 'https://devpulse.app');
  int _ecLevel = QrErrorCorrectLevel.M;
  Color _fg = const Color(0xFF000000);
  Color _bg = const Color(0xFFFFFFFF);
  Uint8List? _logo;

  static const _fgColors = [
    Color(0xFF000000),
    Color(0xFF1B1D23),
    Color(0xFF2F6FEB),
    Color(0xFF1A7F37),
    Color(0xFFD1242F),
  ];
  static const _bgColors = [
    Color(0xFFFFFFFF),
    Color(0xFFF4F5F7),
    Color(0xFFFFF8E1),
    Color(0xFFE8F5E9),
  ];

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    const group = XTypeGroup(label: '图片', extensions: ['png', 'jpg', 'jpeg']);
    final f = await openFile(acceptedTypeGroups: [group]);
    if (f == null) return;
    _logo = await f.readAsBytes();
    setState(() {});
  }

  Future<void> _export() async {
    if (_input.text.isEmpty) return;
    try {
      final painter = QrPainter(
        data: _input.text,
        version: QrVersions.auto,
        errorCorrectionLevel: _ecLevel,
        eyeStyle: QrEyeStyle(eyeShape: QrEyeShape.square, color: _fg),
        dataModuleStyle: QrDataModuleStyle(
            dataModuleShape: QrDataModuleShape.square, color: _fg),
        // ignore: deprecated_member_use
        emptyColor: _bg,
        embeddedImage:
            _logo != null ? await _decodeUiImage(_logo!) : null,
        embeddedImageStyle: _logo != null
            ? const QrEmbeddedImageStyle(size: Size(60, 60))
            : null,
      );
      final data = await painter.toImageData(1024);
      if (data == null) return;
      final loc = await getSaveLocation(
        suggestedName: 'qrcode.png',
        acceptedTypeGroups: [
          const XTypeGroup(label: 'PNG', extensions: ['png'])
        ],
      );
      if (loc == null) return;
      await File(loc.path).writeAsBytes(data.buffer.asUint8List());
      if (mounted) showToast(context, '已导出二维码 PNG');
    } catch (e) {
      if (mounted) showToast(context, '导出失败：$e', error: true);
    }
  }

  Future<ui.Image> _decodeUiImage(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 左：配置
        Expanded(
          child: ListView(
            children: [
              Text('内容', style: TextStyle(fontSize: 12, color: p.textSecondary)),
              const SizedBox(height: Dims.gapSm),
              CodeInput(
                controller: _input,
                hint: '输入文本 / URL…',
                maxLines: 5,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: Dims.gapMd),
              Text('容错级别',
                  style: TextStyle(fontSize: 12, color: p.textSecondary)),
              const SizedBox(height: Dims.gapSm),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: QrErrorCorrectLevel.L, label: Text('L 7%')),
                  ButtonSegment(value: QrErrorCorrectLevel.M, label: Text('M 15%')),
                  ButtonSegment(value: QrErrorCorrectLevel.Q, label: Text('Q 25%')),
                  ButtonSegment(value: QrErrorCorrectLevel.H, label: Text('H 30%')),
                ],
                selected: {_ecLevel},
                showSelectedIcon: false,
                onSelectionChanged: (s) => setState(() => _ecLevel = s.first),
              ),
              const SizedBox(height: Dims.gapMd),
              _colorRow(p, '前景色', _fgColors, _fg, (c) => setState(() => _fg = c)),
              const SizedBox(height: Dims.gapSm),
              _colorRow(p, '背景色', _bgColors, _bg, (c) => setState(() => _bg = c)),
              const SizedBox(height: Dims.gapMd),
              Row(
                children: [
                  OutlinedButton.icon(
                      onPressed: _pickLogo,
                      icon: const Icon(Icons.add_photo_alternate_outlined,
                          size: 16),
                      label: const Text('内嵌 Logo')),
                  if (_logo != null) ...[
                    const SizedBox(width: Dims.gapSm),
                    TextButton(
                        onPressed: () => setState(() => _logo = null),
                        child: const Text('移除')),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: Dims.gapMd),
        // 右：预览
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: p.surfaceAlt,
                    border: Border.all(color: p.border),
                    borderRadius: BorderRadius.circular(Dims.radiusSm),
                  ),
                  padding: const EdgeInsets.all(Dims.gapLg),
                  child: Center(
                    child: _input.text.isEmpty
                        ? const EmptyState(
                            icon: Icons.qr_code_2, message: '输入内容生成二维码')
                        : Container(
                            padding: const EdgeInsets.all(Dims.gapMd),
                            decoration: BoxDecoration(
                              color: _bg,
                              borderRadius:
                                  BorderRadius.circular(Dims.radiusSm),
                            ),
                            child: QrImageView(
                              data: _input.text,
                              version: QrVersions.auto,
                              errorCorrectionLevel: _ecLevel,
                              eyeStyle: QrEyeStyle(
                                  eyeShape: QrEyeShape.square, color: _fg),
                              dataModuleStyle: QrDataModuleStyle(
                                  dataModuleShape: QrDataModuleShape.square,
                                  color: _fg),
                              backgroundColor: _bg,
                              embeddedImage: _logo != null
                                  ? MemoryImage(_logo!)
                                  : null,
                              embeddedImageStyle: const QrEmbeddedImageStyle(
                                  size: Size(48, 48)),
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: Dims.gap),
              FilledButton.icon(
                onPressed: _input.text.isEmpty ? null : _export,
                icon: const Icon(Icons.download, size: 16),
                label: const Text('导出 PNG'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _colorRow(AppPalette p, String label, List<Color> colors,
      Color selected, ValueChanged<Color> onSelect) {
    return Row(
      children: [
        SizedBox(
            width: 56,
            child: Text(label,
                style: TextStyle(fontSize: 12, color: p.textSecondary))),
        for (final c in colors)
          GestureDetector(
            onTap: () => onSelect(c),
            child: Container(
              width: 26,
              height: 26,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: c,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                    color: selected == c ? p.accent : p.border,
                    width: selected == c ? 2 : 1),
              ),
            ),
          ),
      ],
    );
  }
}

// ---------------- 解码 ----------------
class _DecodeTab extends ConsumerStatefulWidget {
  const _DecodeTab();
  @override
  ConsumerState<_DecodeTab> createState() => _DecodeTabState();
}

class _DecodeTabState extends ConsumerState<_DecodeTab> {
  Uint8List? _bytes;
  String? _result;
  bool _dragging = false;
  bool _decoding = false;

  Future<void> _process(Uint8List bytes) async {
    setState(() {
      _bytes = bytes;
      _decoding = true;
      _result = null;
    });
    final text = await Future(() => QrLogic.decode(bytes));
    if (!mounted) return;
    setState(() {
      _result = text;
      _decoding = false;
    });
    if (text == null && mounted) {
      showToast(context, '未识别到二维码', error: true);
    }
  }

  Future<void> _pick() async {
    const group =
        XTypeGroup(label: '图片', extensions: ['png', 'jpg', 'jpeg', 'gif', 'bmp']);
    final f = await openFile(acceptedTypeGroups: [group]);
    if (f == null) return;
    _process(await f.readAsBytes());
  }

  Future<void> _paste() async {
    final bytes = await Pasteboard.image;
    if (bytes == null) {
      if (mounted) showToast(context, '剪贴板没有图片', error: true);
      return;
    }
    _process(bytes);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  FilledButton.icon(
                      onPressed: _pick,
                      icon: const Icon(Icons.folder_open, size: 16),
                      label: const Text('选择图片')),
                  const SizedBox(width: Dims.gapSm),
                  OutlinedButton.icon(
                      onPressed: _paste,
                      icon: const Icon(Icons.content_paste, size: 16),
                      label: const Text('粘贴截图')),
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
                    _process(await File(d.files.first.path).readAsBytes());
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
                            icon: Icons.qr_code_scanner,
                            message: '拖入 / 选择 / 粘贴含二维码的图片')
                        : Center(child: Image.memory(_bytes!, fit: BoxFit.contain)),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: Dims.gapMd),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text('解码结果',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: p.textPrimary)),
                  const Spacer(),
                  if (_result != null)
                    CopyButton(text: () => _result ?? '', dense: true),
                ],
              ),
              const SizedBox(height: Dims.gap),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(Dims.gapMd),
                  decoration: BoxDecoration(
                    color: p.surfaceAlt,
                    border: Border.all(color: p.border),
                    borderRadius: BorderRadius.circular(Dims.radiusSm),
                  ),
                  child: _decoding
                      ? const Center(child: CircularProgressIndicator())
                      : _result == null
                          ? const EmptyState(
                              icon: Icons.text_snippet_outlined,
                              message: '结果显示在这里')
                          : SelectableText(_result!,
                              style: context.mono(size: 14)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

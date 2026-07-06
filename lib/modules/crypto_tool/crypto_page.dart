import 'package:flutter/foundation.dart' show compute;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/layout/tool_scaffold.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/actions.dart';
import '../../core/widgets/app_feedback.dart';
import '../../core/widgets/code_field.dart';
import '../../core/widgets/common.dart';
import 'crypto_logic.dart';

class CryptoPage extends ConsumerStatefulWidget {
  const CryptoPage({super.key});
  @override
  ConsumerState<CryptoPage> createState() => _CryptoPageState();
}

class _CryptoPageState extends ConsumerState<CryptoPage> {
  int _tab = 0; // 0 哈希 1 AES 2 RSA

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      icon: Icons.enhanced_encryption_outlined,
      title: '加密工具',
      subtitle: '哈希 · AES 对称加密 · RSA 非对称加密 · 100% 本地',
      actions: [
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 0, label: Text('哈希')),
            ButtonSegment(value: 1, label: Text('AES')),
            ButtonSegment(value: 2, label: Text('RSA')),
          ],
          selected: {_tab},
          showSelectedIcon: false,
          onSelectionChanged: (s) => setState(() => _tab = s.first),
        ),
      ],
      body: switch (_tab) {
        1 => const _AesTab(),
        2 => const _RsaTab(),
        _ => const _HashTab(),
      },
    );
  }
}

// ---------------- 哈希 ----------------
class _HashTab extends StatefulWidget {
  const _HashTab();
  @override
  State<_HashTab> createState() => _HashTabState();
}

class _HashTabState extends State<_HashTab> {
  final _input = TextEditingController();

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hashes = _input.text.isEmpty ? null : HashLogic.hashAll(_input.text);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 140,
          child: CodeInput(
            controller: _input,
            hint: '输入要计算哈希的文本…',
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(height: Dims.gapMd),
        Expanded(
          child: hashes == null
              ? const EmptyState(icon: Icons.tag, message: '输入文本查看哈希值')
              : SectionCard(
                  title: '哈希结果（十六进制）',
                  icon: Icons.tag,
                  child: Column(
                    children: [
                      for (final e in hashes.entries)
                        ResultRow(label: e.key, value: e.value, mono: true),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

// ---------------- AES ----------------
class _AesTab extends StatefulWidget {
  const _AesTab();
  @override
  State<_AesTab> createState() => _AesTabState();
}

class _AesTabState extends State<_AesTab> {
  final _input = TextEditingController();
  final _password = TextEditingController();
  String _mode = 'CBC';
  bool _decrypt = false;
  String _output = '';
  String? _error;

  @override
  void dispose() {
    _input.dispose();
    _password.dispose();
    super.dispose();
  }

  void _run() {
    final r = _decrypt
        ? AesLogic.decrypt(_input.text, _password.text, _mode)
        : AesLogic.encrypt(_input.text, _password.text, _mode);
    setState(() {
      _output = r.output ?? '';
      _error = r.error;
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
                ButtonSegment(value: false, label: Text('加密')),
                ButtonSegment(value: true, label: Text('解密')),
              ],
              selected: {_decrypt},
              showSelectedIcon: false,
              onSelectionChanged: (s) => setState(() {
                _decrypt = s.first;
                _output = '';
                _error = null;
              }),
            ),
            const SizedBox(width: Dims.gapMd),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'CBC', label: Text('AES-CBC')),
                ButtonSegment(value: 'GCM', label: Text('AES-GCM')),
              ],
              selected: {_mode},
              showSelectedIcon: false,
              onSelectionChanged: (s) => setState(() => _mode = s.first),
            ),
            const Spacer(),
            FilledButton.icon(
                onPressed: _run,
                icon: Icon(_decrypt ? Icons.lock_open : Icons.lock, size: 16),
                label: Text(_decrypt ? '解密' : '加密')),
          ],
        ),
        const SizedBox(height: Dims.gap),
        TextField(
          controller: _password,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: '密钥 / 口令（经 SHA-256 派生 AES-256 密钥）',
            prefixIcon: Icon(Icons.key, size: 18),
          ),
        ),
        const SizedBox(height: Dims.gap),
        if (_error != null) ...[
          _errBanner(p, _error!),
          const SizedBox(height: Dims.gap),
        ],
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(children: [
                      Text(_decrypt ? '密文（Base64）' : '明文',
                          style: TextStyle(
                              fontSize: 12, color: p.textSecondary)),
                      const Spacer(),
                      PasteButton(controller: _input, dense: true),
                    ]),
                    const SizedBox(height: 6),
                    Expanded(
                        child: CodeInput(
                            controller: _input,
                            hint: _decrypt ? '粘贴 Base64 密文…' : '输入明文…')),
                  ],
                ),
              ),
              const SizedBox(width: Dims.gap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(children: [
                      Text(_decrypt ? '明文' : '密文（Base64）',
                          style: TextStyle(
                              fontSize: 12, color: p.textSecondary)),
                      const Spacer(),
                      CopyButton(text: () => _output, dense: true),
                    ]),
                    const SizedBox(height: 6),
                    Expanded(
                      child: _output.isEmpty
                          ? _outBox(p, '结果显示在这里')
                          : CodeInput(
                              controller:
                                  TextEditingController(text: _output),
                              readOnly: true),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _outBox(AppPalette p, String msg) => Container(
        decoration: BoxDecoration(
          color: p.surfaceAlt,
          border: Border.all(color: p.border),
          borderRadius: BorderRadius.circular(Dims.radiusSm),
        ),
        child: EmptyState(icon: Icons.lock_outline, message: msg),
      );

  Widget _errBanner(AppPalette p, String msg) => Container(
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

// ---------------- RSA ----------------
class _RsaTab extends StatefulWidget {
  const _RsaTab();
  @override
  State<_RsaTab> createState() => _RsaTabState();
}

class _RsaTabState extends State<_RsaTab> {
  final _publicPem = TextEditingController();
  final _privatePem = TextEditingController();
  final _message = TextEditingController();
  final _signature = TextEditingController();

  int _keySize = 2048;
  bool _generating = false;
  String _op = 'encrypt'; // encrypt/decrypt/sign/verify
  String _output = '';
  String? _error;
  bool? _verifyOk;

  @override
  void dispose() {
    _publicPem.dispose();
    _privatePem.dispose();
    _message.dispose();
    _signature.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    setState(() => _generating = true);
    try {
      final pair = await compute(generateRsaPem, _keySize);
      _publicPem.text = pair.publicPem;
      _privatePem.text = pair.privatePem;
    } catch (e) {
      if (mounted) showToast(context, '生成失败：$e', error: true);
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  void _run() {
    setState(() {
      _error = null;
      _output = '';
      _verifyOk = null;
    });
    switch (_op) {
      case 'encrypt':
        final r = RsaLogic.encrypt(_message.text, _publicPem.text);
        setState(() {
          _output = r.output ?? '';
          _error = r.error;
        });
      case 'decrypt':
        final r = RsaLogic.decrypt(_message.text, _privatePem.text);
        setState(() {
          _output = r.output ?? '';
          _error = r.error;
        });
      case 'sign':
        final r = RsaLogic.sign(_message.text, _privatePem.text);
        setState(() {
          _output = r.output ?? '';
          _error = r.error;
        });
      case 'verify':
        final r =
            RsaLogic.verify(_message.text, _signature.text, _publicPem.text);
        setState(() {
          _verifyOk = r.ok;
          _error = r.error;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 左：密钥对
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 2048, label: Text('2048')),
                      ButtonSegment(value: 4096, label: Text('4096')),
                    ],
                    selected: {_keySize},
                    showSelectedIcon: false,
                    onSelectionChanged: (s) =>
                        setState(() => _keySize = s.first),
                  ),
                  const SizedBox(width: Dims.gapSm),
                  FilledButton.icon(
                    onPressed: _generating ? null : _generate,
                    icon: _generating
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child:
                                CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.vpn_key, size: 16),
                    label: Text(_generating ? '生成中…' : '生成密钥对'),
                  ),
                ],
              ),
              const SizedBox(height: Dims.gap),
              Text('公钥 PEM',
                  style: TextStyle(fontSize: 12, color: p.textSecondary)),
              const SizedBox(height: 4),
              Expanded(
                  child: CodeInput(
                      controller: _publicPem,
                      hint: '-----BEGIN PUBLIC KEY-----',
                      fontSize: 11)),
              const SizedBox(height: Dims.gapSm),
              Row(children: [
                Text('私钥 PEM',
                    style: TextStyle(fontSize: 12, color: p.textSecondary)),
                const Spacer(),
                CopyButton(text: () => _privatePem.text, dense: true),
              ]),
              const SizedBox(height: 4),
              Expanded(
                  child: CodeInput(
                      controller: _privatePem,
                      hint: '-----BEGIN RSA PRIVATE KEY-----',
                      fontSize: 11)),
            ],
          ),
        ),
        const SizedBox(width: Dims.gapMd),
        // 右：操作
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'encrypt', label: Text('加密')),
                  ButtonSegment(value: 'decrypt', label: Text('解密')),
                  ButtonSegment(value: 'sign', label: Text('签名')),
                  ButtonSegment(value: 'verify', label: Text('验签')),
                ],
                selected: {_op},
                showSelectedIcon: false,
                onSelectionChanged: (s) => setState(() {
                  _op = s.first;
                  _output = '';
                  _error = null;
                  _verifyOk = null;
                }),
              ),
              const SizedBox(height: Dims.gap),
              Text(_op == 'decrypt' ? '密文（Base64）' : '消息 / 明文',
                  style: TextStyle(fontSize: 12, color: p.textSecondary)),
              const SizedBox(height: 4),
              Expanded(
                  child: CodeInput(
                      controller: _message, hint: '输入内容…', fontSize: 12)),
              if (_op == 'verify') ...[
                const SizedBox(height: Dims.gapSm),
                Text('签名（Base64）',
                    style: TextStyle(fontSize: 12, color: p.textSecondary)),
                const SizedBox(height: 4),
                SizedBox(
                    height: 70,
                    child: CodeInput(
                        controller: _signature,
                        hint: '待校验签名…',
                        fontSize: 11)),
              ],
              const SizedBox(height: Dims.gap),
              Row(
                children: [
                  FilledButton(onPressed: _run, child: const Text('执行')),
                  const SizedBox(width: Dims.gap),
                  if (_verifyOk != null)
                    StatusBadge(_verifyOk! ? '签名有效' : '签名无效',
                        kind: _verifyOk!
                            ? BadgeKind.success
                            : BadgeKind.danger,
                        icon: _verifyOk!
                            ? Icons.check_circle
                            : Icons.cancel),
                  const Spacer(),
                  if (_output.isNotEmpty)
                    CopyButton(text: () => _output, dense: true),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: Dims.gapSm),
                Text(_error!,
                    style: TextStyle(color: p.danger, fontSize: 12.5)),
              ],
              if (_output.isNotEmpty) ...[
                const SizedBox(height: Dims.gapSm),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(Dims.gap),
                  decoration: BoxDecoration(
                    color: p.surfaceAlt,
                    border: Border.all(color: p.border),
                    borderRadius: BorderRadius.circular(Dims.radiusSm),
                  ),
                  child: SelectableText(_output,
                      style: context.mono(size: 12), maxLines: 6),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

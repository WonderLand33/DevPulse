import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/layout/tool_scaffold.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_feedback.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/ring_countdown.dart';
import 'totp_controller.dart';
import 'totp_logic.dart';

class TotpPage extends ConsumerStatefulWidget {
  const TotpPage({super.key});
  @override
  ConsumerState<TotpPage> createState() => _TotpPageState();
}

class _TotpPageState extends ConsumerState<TotpPage> {
  Timer? _timer;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(
        const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final st = ref.watch(totpProvider);
    final accounts = st.accounts.where((a) {
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return a.label.toLowerCase().contains(q) ||
          a.issuer.toLowerCase().contains(q);
    }).toList();

    return ToolScaffold(
      icon: Icons.security,
      title: 'TOTP 认证令牌',
      subtitle: '桌面版验证器 · 种子经系统级加密存储 · 绝无网络备份',
      actions: [
        FilledButton.icon(
          onPressed: _showAddDialog,
          icon: const Icon(Icons.add, size: 16),
          label: const Text('添加令牌'),
        ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _securityNote(p),
          const SizedBox(height: Dims.gap),
          if (st.accounts.isNotEmpty)
            TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(
                hintText: '搜索账号 / 备注…',
                prefixIcon: Icon(Icons.search, size: 18),
              ),
            ),
          const SizedBox(height: Dims.gap),
          Expanded(
            child: st.accounts.isEmpty
                ? const EmptyState(
                    icon: Icons.security,
                    message: '尚未添加令牌',
                    hint: '点右上「添加令牌」，支持 otpauth:// 或手动输入')
                : accounts.isEmpty
                    ? const EmptyState(
                        icon: Icons.search_off, message: '无匹配账号')
                    : GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 420,
                          mainAxisExtent: 96,
                          crossAxisSpacing: Dims.gap,
                          mainAxisSpacing: Dims.gap,
                        ),
                        itemCount: accounts.length,
                        itemBuilder: (ctx, i) =>
                            _TotpCard(account: accounts[i], secret: st.secrets[accounts[i].id]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _securityNote(AppPalette p) => Container(
        padding: const EdgeInsets.symmetric(
            horizontal: Dims.gap, vertical: Dims.gapSm),
        decoration: BoxDecoration(
          color: p.success.withValues(alpha: 0.1),
          border: Border.all(color: p.success.withValues(alpha: 0.35)),
          borderRadius: BorderRadius.circular(Dims.radiusSm),
        ),
        child: Row(
          children: [
            Icon(Icons.lock_outline, size: 15, color: p.success),
            const SizedBox(width: Dims.gapSm),
            Expanded(
              child: Text(
                '种子密钥存于系统 Credential Manager / Keychain，本工具不联网、不备份。',
                style: TextStyle(fontSize: 12, color: p.textSecondary),
              ),
            ),
          ],
        ),
      );

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (_) => const _AddTotpDialog(),
    );
  }
}

class _TotpCard extends ConsumerStatefulWidget {
  final TotpAccount account;
  final String? secret;
  const _TotpCard({required this.account, required this.secret});
  @override
  ConsumerState<_TotpCard> createState() => _TotpCardState();
}

class _TotpCardState extends ConsumerState<_TotpCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final a = widget.account;
    final loaded = widget.secret != null;
    final code = loaded
        ? TotpLogic.generate(widget.secret!,
            digits: a.digits, period: a.period, algorithm: a.algorithm)
        : '------';
    final remaining = TotpLogic.remaining(a.period);
    final progress = TotpLogic.progress(a.period);

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: loaded ? () => _copy(code) : null,
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: Dims.gapMd, vertical: Dims.gap),
          decoration: BoxDecoration(
            color: p.surface,
            border: Border.all(color: _hover ? p.accent : p.border),
            borderRadius: BorderRadius.circular(Dims.radius),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        if (a.issuer.isNotEmpty) ...[
                          Flexible(
                            child: Text(a.issuer,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: p.textPrimary)),
                          ),
                          Text(' · ',
                              style:
                                  TextStyle(color: p.textSecondary)),
                        ],
                        Flexible(
                          child: Text(a.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 12, color: p.textSecondary)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      TotpLogic.pretty(code),
                      style: context.mono(
                          size: 26,
                          weight: FontWeight.w700,
                          color: remaining <= 5 ? p.warning : p.accent),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Dims.gapSm),
              if (_hover)
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(Icons.copy_all_outlined,
                          size: 18, color: p.accent),
                      tooltip: '复制验证码',
                      onPressed: loaded ? () => _copy(code) : null,
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline,
                          size: 18, color: p.textSecondary),
                      tooltip: '删除',
                      onPressed: () => _confirmDelete(a),
                    ),
                  ],
                )
              else
                RingCountdown(
                    progress: progress, remainingSeconds: remaining),
            ],
          ),
        ),
      ),
    );
  }

  void _copy(String code) {
    Clipboard.setData(ClipboardData(text: code));
    showToast(context, '验证码已复制');
  }

  void _confirmDelete(TotpAccount a) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除令牌'),
        content: Text('确定删除 “${a.issuer.isNotEmpty ? "${a.issuer} · " : ""}${a.label}”？此操作不可撤销，种子将从加密存储中移除。'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: context.palette.danger),
            onPressed: () {
              ref.read(totpProvider.notifier).remove(a.id);
              Navigator.pop(ctx);
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}

// ---------------- 添加对话框 ----------------
class _AddTotpDialog extends ConsumerStatefulWidget {
  const _AddTotpDialog();
  @override
  ConsumerState<_AddTotpDialog> createState() => _AddTotpDialogState();
}

class _AddTotpDialogState extends ConsumerState<_AddTotpDialog> {
  bool _manual = false;

  // manual fields
  final _label = TextEditingController();
  final _issuer = TextEditingController();
  final _secret = TextEditingController();
  int _digits = 6;
  int _period = 30;
  String _algorithm = 'SHA1';

  // uri field
  final _uri = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _label.dispose();
    _issuer.dispose();
    _secret.dispose();
    _uri.dispose();
    super.dispose();
  }

  Future<void> _pasteUri() async {
    final d = await Clipboard.getData(Clipboard.kTextPlain);
    if (d?.text != null) _uri.text = d!.text!.trim();
    setState(() {});
  }

  void _submit() {
    setState(() => _error = null);
    TotpConfig? config;
    if (_manual) {
      if (!TotpLogic.isValidBase32(_secret.text)) {
        setState(() => _error = '密钥不是合法的 Base32');
        return;
      }
      config = TotpConfig(
        label: _label.text.trim().isEmpty ? '未命名' : _label.text.trim(),
        issuer: _issuer.text.trim(),
        secret: TotpLogic.normalizeSecret(_secret.text),
        digits: _digits,
        period: _period,
        algorithm: _algorithm,
      );
    } else {
      config = TotpLogic.parseUri(_uri.text);
      if (config == null) {
        setState(() => _error = '无法解析 otpauth:// 链接');
        return;
      }
    }
    ref.read(totpProvider.notifier).addFromConfig(config);
    Navigator.pop(context);
    showToast(context, '已添加令牌');
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AlertDialog(
      title: const Text('添加 TOTP 令牌'),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('otpauth 链接')),
                ButtonSegment(value: true, label: Text('手动输入')),
              ],
              selected: {_manual},
              showSelectedIcon: false,
              onSelectionChanged: (s) => setState(() => _manual = s.first),
            ),
            const SizedBox(height: Dims.gapMd),
            if (!_manual)
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _uri,
                      style: context.mono(size: 12.5),
                      maxLines: 3,
                      minLines: 1,
                      decoration: const InputDecoration(
                        hintText: 'otpauth://totp/...',
                      ),
                    ),
                  ),
                  IconButton(
                      onPressed: _pasteUri,
                      icon: const Icon(Icons.content_paste, size: 18),
                      tooltip: '粘贴'),
                ],
              )
            else ...[
              TextField(
                controller: _issuer,
                decoration: const InputDecoration(
                    labelText: '服务名（Issuer）', hintText: '如 GitHub'),
              ),
              const SizedBox(height: Dims.gapSm),
              TextField(
                controller: _label,
                decoration: const InputDecoration(
                    labelText: '账号 / 备注', hintText: '如 me@example.com'),
              ),
              const SizedBox(height: Dims.gapSm),
              TextField(
                controller: _secret,
                style: context.mono(size: 13),
                decoration: const InputDecoration(
                    labelText: 'Base32 密钥（Secret）'),
              ),
              const SizedBox(height: Dims.gapSm),
              Row(
                children: [
                  Expanded(
                    child: _dropdown<int>('位数', _digits, const [6, 8],
                        (v) => setState(() => _digits = v)),
                  ),
                  const SizedBox(width: Dims.gapSm),
                  Expanded(
                    child: _dropdown<int>('周期(秒)', _period, const [30, 60],
                        (v) => setState(() => _period = v)),
                  ),
                  const SizedBox(width: Dims.gapSm),
                  Expanded(
                    child: _dropdown<String>('算法', _algorithm,
                        const ['SHA1', 'SHA256', 'SHA512'],
                        (v) => setState(() => _algorithm = v)),
                  ),
                ],
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: Dims.gap),
              Text(_error!, style: TextStyle(color: p.danger, fontSize: 12.5)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: const Text('取消')),
        FilledButton(onPressed: _submit, child: const Text('添加')),
      ],
    );
  }

  Widget _dropdown<T>(
      String label, T value, List<T> options, ValueChanged<T> onChanged) {
    return InputDecorator(
      decoration: InputDecoration(labelText: label, isDense: true),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isDense: true,
          isExpanded: true,
          items: options
              .map((o) =>
                  DropdownMenuItem(value: o, child: Text('$o')))
              .toList(),
          onChanged: (v) => v == null ? null : onChanged(v),
        ),
      ),
    );
  }
}

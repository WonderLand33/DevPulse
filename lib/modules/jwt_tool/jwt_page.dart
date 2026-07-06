import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/layout/tool_scaffold.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/actions.dart';
import '../../core/widgets/code_field.dart';
import '../../core/widgets/common.dart';
import '../unix_time/unix_time_logic.dart';
import 'jwt_logic.dart';

class JwtPage extends ConsumerStatefulWidget {
  const JwtPage({super.key});
  @override
  ConsumerState<JwtPage> createState() => _JwtPageState();
}

class _JwtPageState extends ConsumerState<JwtPage> {
  final _input = TextEditingController();
  final _secret = TextEditingController();
  JwtParts _parts = const JwtParts();

  @override
  void dispose() {
    _input.dispose();
    _secret.dispose();
    super.dispose();
  }

  void _parse() => setState(() => _parts = JwtLogic.parse(_input.text));

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final expired = _parts.isExpired;
    return ToolScaffold(
      icon: Icons.vpn_key_outlined,
      title: 'JWT 调试器',
      subtitle: '三段解析 · 过期倒计时 · HMAC 本地验签',
      actions: [
        PasteButton(controller: _input, dense: true, onPasted: _parse),
        ClearButton(
            dense: true,
            onClear: () {
              _input.clear();
              _parse();
            }),
      ],
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 左：Token 输入 + 分段着色
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _ColoredTokenField(
                    controller: _input,
                    parts: _parts,
                    onChanged: (_) => _parse(),
                  ),
                ),
                if (_parts.error != null) ...[
                  const SizedBox(height: Dims.gap),
                  _banner(p, _parts.error!, p.danger, Icons.error_outline),
                ],
                const SizedBox(height: Dims.gap),
                _verifyBox(p),
              ],
            ),
          ),
          const SizedBox(width: Dims.gap),
          // 右：解码结果
          Expanded(
            flex: 6,
            child: (_parts.header == null && _parts.payload == null)
                ? Container(
                    decoration: BoxDecoration(
                      color: p.surfaceAlt,
                      border: Border.all(color: p.border),
                      borderRadius: BorderRadius.circular(Dims.radiusSm),
                    ),
                    child: const EmptyState(
                        icon: Icons.vpn_key_outlined,
                        message: '粘贴 JWT 查看解码结果'),
                  )
                : ListView(
                    children: [
                      if (_parts.exp != null)
                        _expBanner(p, expired),
                      _segment(
                        p,
                        'HEADER',
                        JwtLogic.pretty(_parts.header),
                        p.danger,
                      ),
                      const SizedBox(height: Dims.gap),
                      _segment(
                        p,
                        'PAYLOAD',
                        JwtLogic.pretty(_parts.payload),
                        p.info,
                      ),
                      if (_parts.payload != null) ...[
                        const SizedBox(height: Dims.gap),
                        _claims(p),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _expBanner(AppPalette p, bool expired) {
    final exp = _parts.exp!;
    final rel = UnixTimeLogic.relative(exp, DateTime.now());
    return Container(
      margin: const EdgeInsets.only(bottom: Dims.gap),
      padding: const EdgeInsets.all(Dims.gap),
      decoration: BoxDecoration(
        color: (expired ? p.danger : p.success).withValues(alpha: 0.12),
        border: Border.all(
            color: (expired ? p.danger : p.success).withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(Dims.radiusSm),
      ),
      child: Row(
        children: [
          Icon(expired ? Icons.gpp_bad : Icons.verified_user,
              size: 18, color: expired ? p.danger : p.success),
          const SizedBox(width: Dims.gapSm),
          Expanded(
            child: Text(
              expired
                  ? '令牌已于 ${UnixTimeLogic.fmt(exp)} 过期（$rel）'
                  : '令牌有效，将于 ${UnixTimeLogic.fmt(exp)} 过期（$rel）',
              style: TextStyle(
                  color: expired ? p.danger : p.success,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _segment(AppPalette p, String title, String body, Color color) {
    return SectionCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: Dims.gap, vertical: Dims.gapSm),
            child: Row(
              children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(
                    color: color, shape: BoxShape.circle)),
                const SizedBox(width: Dims.gapSm),
                Text(title,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: color)),
                const Spacer(),
                CopyButton(text: () => body, label: '', dense: true),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(Dims.gap),
            child: SelectableText(body, style: context.mono(size: 12.5)),
          ),
        ],
      ),
    );
  }

  Widget _claims(AppPalette p) {
    final rows = <Widget>[];
    _parts.payload!.forEach((k, v) {
      final hint = JwtLogic.claimHint(k);
      String val = v.toString();
      if ((k == 'exp' || k == 'iat' || k == 'nbf') && v is num) {
        val = '${UnixTimeLogic.fmt(DateTime.fromMillisecondsSinceEpoch((v * 1000).round()))}  ($v)';
      }
      rows.add(ResultRow(
        label: hint != null ? '$k · $hint' : k,
        value: val,
        mono: true,
      ));
    });
    return SectionCard(
      title: '声明速览',
      icon: Icons.list_alt,
      child: Column(children: rows),
    );
  }

  Widget _verifyBox(AppPalette p) {
    final token = _input.text.trim();
    bool? result;
    bool unsupported = false;
    if (token.isNotEmpty && _parts.error == null && _secret.text.isNotEmpty) {
      final r = JwtLogic.verifyHmac(token, _secret.text);
      if (r == null) {
        unsupported = true;
      } else {
        result = r;
      }
    }
    Color borderColor = p.border;
    if (result == true) borderColor = p.success;
    if (result == false) borderColor = p.danger;

    return Container(
      padding: const EdgeInsets.all(Dims.gap),
      decoration: BoxDecoration(
        color: p.surface,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(Dims.radiusSm),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _secret,
              onChanged: (_) => setState(() {}),
              style: context.mono(size: 13),
              decoration: const InputDecoration(
                hintText: 'HMAC 密钥（HS256/384/512 本地验签）',
                prefixIcon: Icon(Icons.key, size: 16),
              ),
            ),
          ),
          const SizedBox(width: Dims.gap),
          if (unsupported)
            const StatusBadge('非 HS* 算法',
                kind: BadgeKind.neutral, icon: Icons.info_outline)
          else if (result == true)
            const StatusBadge('签名有效',
                kind: BadgeKind.success, icon: Icons.check_circle)
          else if (result == false)
            const StatusBadge('签名无效',
                kind: BadgeKind.danger, icon: Icons.cancel)
          else
            Text('输入密钥校验',
                style: TextStyle(fontSize: 12, color: p.textSecondary)),
        ],
      ),
    );
  }

  Widget _banner(AppPalette p, String msg, Color color, IconData icon) =>
      Container(
        padding: const EdgeInsets.symmetric(
            horizontal: Dims.gap, vertical: Dims.gapSm),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          border: Border.all(color: color.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(Dims.radiusSm),
        ),
        child: Row(children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: Dims.gapSm),
          Expanded(
              child:
                  Text(msg, style: TextStyle(color: color, fontSize: 12.5))),
        ]),
      );
}

/// 输入框：把 Token 的三段以不同颜色显示（通过底层文本 + 提示条）。
class _ColoredTokenField extends StatelessWidget {
  final TextEditingController controller;
  final JwtParts parts;
  final ValueChanged<String> onChanged;
  const _ColoredTokenField({
    required this.controller,
    required this.parts,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _legend(p, 'Header', p.danger),
            const SizedBox(width: Dims.gap),
            _legend(p, 'Payload', p.info),
            const SizedBox(width: Dims.gap),
            _legend(p, 'Signature', p.textSecondary),
          ],
        ),
        const SizedBox(height: Dims.gapSm),
        Expanded(
          child: CodeInput(
            controller: controller,
            hint: '在此粘贴 JWT（eyJ...）',
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _legend(AppPalette p, String label, Color c) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(fontSize: 11.5, color: p.textSecondary)),
        ],
      );
}

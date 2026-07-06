import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/layout/tool_scaffold.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/actions.dart';
import '../../core/widgets/code_field.dart';
import '../../core/widgets/common.dart';
import '../unix_time/unix_time_logic.dart';
import 'x509_logic.dart';

class X509Page extends ConsumerStatefulWidget {
  const X509Page({super.key});
  @override
  ConsumerState<X509Page> createState() => _X509PageState();
}

class _X509PageState extends ConsumerState<X509Page> {
  final _input = TextEditingController();
  X509Result _result = const X509Result();

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _parse() => setState(() => _result = X509Logic.parse(_input.text));

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ToolScaffold(
      icon: Icons.verified_user_outlined,
      title: 'X.509 证书解码',
      subtitle: 'PEM 解析 · 有效期告警 · 100% 本地',
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
          Expanded(
            flex: 4,
            child: CodeInput(
              controller: _input,
              hint: '在此粘贴 PEM 证书\n-----BEGIN CERTIFICATE-----\n...',
              fontSize: 12,
              onChanged: (_) => _parse(),
            ),
          ),
          const SizedBox(width: Dims.gap),
          Expanded(
            flex: 5,
            child: _result.error != null
                ? _errorBox(p, _result.error!)
                : _result.info == null
                    ? Container(
                        decoration: BoxDecoration(
                          color: p.surfaceAlt,
                          border: Border.all(color: p.border),
                          borderRadius: BorderRadius.circular(Dims.radiusSm),
                        ),
                        child: const EmptyState(
                            icon: Icons.verified_user_outlined,
                            message: '粘贴 PEM 证书查看详情'),
                      )
                    : _details(p, _result.info!),
          ),
        ],
      ),
    );
  }

  Widget _details(AppPalette p, CertInfo c) {
    return ListView(
      children: [
        _validityBanner(p, c),
        const SizedBox(height: Dims.gapMd),
        SectionCard(
          title: '主体 Subject',
          icon: Icons.badge_outlined,
          child: Column(
            children: [
              ResultRow(label: 'CN', value: c.subjectCN, mono: true),
              ResultRow(
                  label: 'DN',
                  value: X509Logic.formatDn(c.subject),
                  mono: true),
              if (c.san.isNotEmpty)
                ResultRow(
                    label: 'SAN', value: c.san.join('\n'), mono: true),
            ],
          ),
        ),
        const SizedBox(height: Dims.gapMd),
        SectionCard(
          title: '签发者 Issuer',
          icon: Icons.account_balance_outlined,
          child: Column(
            children: [
              ResultRow(label: 'CN', value: c.issuerCN, mono: true),
              ResultRow(
                  label: 'DN',
                  value: X509Logic.formatDn(c.issuer),
                  mono: true),
            ],
          ),
        ),
        const SizedBox(height: Dims.gapMd),
        SectionCard(
          title: '技术细节',
          icon: Icons.memory,
          child: Column(
            children: [
              ResultRow(
                  label: '版本', value: 'v${c.version}', copyable: false),
              ResultRow(
                  label: '序列号', value: c.serialNumber, mono: true),
              ResultRow(
                  label: '签名算法',
                  value: c.signatureAlgorithm,
                  copyable: false),
              ResultRow(
                  label: '公钥算法',
                  value: c.publicKeyAlgorithm,
                  copyable: false),
              ResultRow(
                  label: '公钥长度',
                  value: c.publicKeyLength != null
                      ? '${c.publicKeyLength} bit'
                      : '未知',
                  copyable: false),
              if (c.sha256Thumbprint != null)
                ResultRow(
                    label: 'SHA-256 指纹',
                    value: c.sha256Thumbprint!,
                    mono: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _validityBanner(AppPalette p, CertInfo c) {
    final (color, icon, text) = c.isExpired
        ? (p.danger, Icons.gpp_bad, '证书已过期')
        : c.notYetValid
            ? (p.warning, Icons.schedule, '证书尚未生效')
            : c.isExpiringSoon
                ? (p.warning, Icons.warning_amber, '证书即将过期')
                : (p.success, Icons.verified_user, '证书有效');

    return Container(
      padding: const EdgeInsets.all(Dims.gapMd),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(Dims.radius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: Dims.gapSm),
              Text(text,
                  style: TextStyle(
                      color: color,
                      fontSize: 15,
                      fontWeight: FontWeight.w700)),
              const Spacer(),
              if (!c.isExpired && !c.notYetValid)
                Text('剩余 ${c.daysRemaining} 天',
                    style: TextStyle(
                        color: color,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: Dims.gapSm),
          ResultRow(
              label: '生效时间 (Not Before)',
              value: UnixTimeLogic.fmt(c.notBefore),
              mono: true,
              copyable: false),
          ResultRow(
              label: '过期时间 (Not After)',
              value: UnixTimeLogic.fmt(c.notAfter),
              mono: true,
              copyable: false),
        ],
      ),
    );
  }

  Widget _errorBox(AppPalette p, String msg) => Container(
        padding: const EdgeInsets.all(Dims.gapMd),
        decoration: BoxDecoration(
          color: p.danger.withValues(alpha: 0.12),
          border: Border.all(color: p.danger.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(Dims.radiusSm),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.error_outline, size: 18, color: p.danger),
          const SizedBox(width: Dims.gapSm),
          Expanded(
              child: Text(msg,
                  style: TextStyle(color: p.danger, fontSize: 13))),
        ]),
      );
}

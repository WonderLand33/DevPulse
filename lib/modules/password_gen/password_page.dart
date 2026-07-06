import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/layout/tool_scaffold.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import 'password_logic.dart';

class PasswordPage extends ConsumerStatefulWidget {
  const PasswordPage({super.key});
  @override
  ConsumerState<PasswordPage> createState() => _PasswordPageState();
}

class _PasswordPageState extends ConsumerState<PasswordPage> {
  PasswordOptions _opt = const PasswordOptions();
  String _password = '';

  @override
  void initState() {
    super.initState();
    _regen();
  }

  void _regen() => setState(() => _password = PasswordLogic.generate(_opt));

  void _update(PasswordOptions o) {
    setState(() => _opt = o);
    _regen();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final bits = PasswordLogic.entropyBits(_opt);
    final strength = PasswordLogic.strength(bits);
    final poolEmpty = PasswordLogic.pool(_opt).isEmpty;

    return ToolScaffold(
      icon: Icons.password,
      title: '密码生成器',
      subtitle: '安全随机数生成 · 信息熵强度评估',
      actions: [
        CopyButton(text: () => _password, dense: true),
      ],
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            children: [
              // 密码展示
              Container(
                padding: const EdgeInsets.all(Dims.gapLg),
                decoration: BoxDecoration(
                  color: p.surface,
                  border: Border.all(color: p.border),
                  borderRadius: BorderRadius.circular(Dims.radius),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: SelectableText(
                            poolEmpty ? '请至少选择一种字符类型' : _password,
                            style: context.mono(
                                size: 22,
                                weight: FontWeight.w600,
                                color: poolEmpty ? p.danger : p.textPrimary),
                          ),
                        ),
                        IconButton(
                          onPressed: _regen,
                          icon: const Icon(Icons.refresh),
                          tooltip: '重新生成',
                          color: p.accent,
                        ),
                      ],
                    ),
                    const SizedBox(height: Dims.gapMd),
                    _strengthBar(p, strength.level, strength.label, bits),
                  ],
                ),
              ),
              const SizedBox(height: Dims.gapMd),
              // 选项
              SectionCard(
                title: '生成选项',
                icon: Icons.tune,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Text('长度',
                            style: TextStyle(
                                fontSize: 13, color: p.textSecondary)),
                        Expanded(
                          child: Slider(
                            value: _opt.length.toDouble(),
                            min: 1,
                            max: 128,
                            divisions: 127,
                            label: '${_opt.length}',
                            onChanged: (v) =>
                                _update(_opt.copyWith(length: v.round())),
                          ),
                        ),
                        Container(
                          width: 44,
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: p.accentSoft,
                            borderRadius: BorderRadius.circular(Dims.radiusSm),
                          ),
                          child: Text('${_opt.length}',
                              style: context.mono(
                                  size: 14,
                                  color: p.accent,
                                  weight: FontWeight.w700)),
                        ),
                      ],
                    ),
                    const Divider(height: Dims.gapLg),
                    Wrap(
                      spacing: Dims.gap,
                      runSpacing: Dims.gapSm,
                      children: [
                        _toggle('大写 A-Z', _opt.upper,
                            (v) => _update(_opt.copyWith(upper: v))),
                        _toggle('小写 a-z', _opt.lower,
                            (v) => _update(_opt.copyWith(lower: v))),
                        _toggle('数字 0-9', _opt.digits,
                            (v) => _update(_opt.copyWith(digits: v))),
                        _toggle('符号 !@#', _opt.symbols,
                            (v) => _update(_opt.copyWith(symbols: v))),
                        _toggle('排除易混淆 (Il1O0o)', _opt.excludeAmbiguous,
                            (v) => _update(
                                _opt.copyWith(excludeAmbiguous: v))),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _toggle(String label, bool value, ValueChanged<bool> onChanged) {
    return FilterChip(
      label: Text(label),
      selected: value,
      onSelected: onChanged,
    );
  }

  Widget _strengthBar(AppPalette p, int level, String label, double bits) {
    final colors = [p.danger, p.danger, p.warning, p.success, p.success];
    final color = colors[level];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (var i = 0; i < 5; i++) ...[
              Expanded(
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: i <= level ? color : p.border,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              if (i < 4) const SizedBox(width: 4),
            ],
          ],
        ),
        const SizedBox(height: Dims.gapSm),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('强度：$label',
                style: TextStyle(
                    color: color, fontSize: 13, fontWeight: FontWeight.w600)),
            Text('信息熵 ${bits.toStringAsFixed(1)} bits',
                style: TextStyle(color: p.textSecondary, fontSize: 12.5)),
          ],
        ),
      ],
    );
  }
}

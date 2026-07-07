import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/layout/tool_scaffold.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/actions.dart';
import '../../core/widgets/common.dart';
import 'radix_logic.dart';

/// 多进制实时转换器：二进制/八进制/十进制/十六进制 + 自定义 2~36 进制，
/// 任意一个框输入后其余框自动按同一个 64 位有符号整数值重新格式化。
class RadixPage extends ConsumerStatefulWidget {
  const RadixPage({super.key});
  @override
  ConsumerState<RadixPage> createState() => _RadixPageState();
}

class _RadixPageState extends ConsumerState<RadixPage> {
  static const _fixedRadices = {'bin': 2, 'oct': 8, 'dec': 10, 'hex': 16};
  static const _allFields = ['bin', 'oct', 'dec', 'hex', 'custom'];

  final _bin = TextEditingController();
  final _oct = TextEditingController();
  final _dec = TextEditingController();
  final _hex = TextEditingController();
  final _custom = TextEditingController();

  int _customRadix = 36;
  int? _value;
  String? _error;
  String? _errorField;

  @override
  void dispose() {
    for (final c in [_bin, _oct, _dec, _hex, _custom]) {
      c.dispose();
    }
    super.dispose();
  }

  int _radixOf(String field) =>
      field == 'custom' ? _customRadix : _fixedRadices[field]!;

  TextEditingController _ctrlOf(String field) => switch (field) {
        'bin' => _bin,
        'oct' => _oct,
        'dec' => _dec,
        'hex' => _hex,
        _ => _custom,
      };

  String _labelOf(String field) => switch (field) {
        'bin' => '二进制',
        'oct' => '八进制',
        'dec' => '十进制',
        'hex' => '十六进制',
        _ => '自定义',
      };

  void _handle(String field) {
    final r = RadixLogic.parse(_ctrlOf(field).text, _radixOf(field));
    setState(() {
      if (!r.ok) {
        _error = r.error;
        _errorField = field;
        return;
      }
      _error = null;
      _errorField = null;
      _value = r.value;
      _syncOthers(field);
    });
  }

  void _syncOthers(String except) {
    for (final f in _allFields) {
      if (f == except) continue;
      if (_value == null) {
        _ctrlOf(f).clear();
      } else {
        _ctrlOf(f).text = RadixLogic.format(_value!, _radixOf(f));
      }
    }
  }

  void _changeCustomRadix(int delta) {
    final next =
        (_customRadix + delta).clamp(RadixLogic.minRadix, RadixLogic.maxRadix);
    if (next == _customRadix) return;
    setState(() {
      _customRadix = next;
      if (_value != null) {
        _custom.text = RadixLogic.format(_value!, _customRadix);
        if (_errorField == 'custom') {
          _error = null;
          _errorField = null;
        }
        return;
      }
      if (_custom.text.trim().isEmpty) return;
      // 自定义框当前有内容但全局无合法值（说明之前解析失败），
      // 换了进制后重新校验一次，进制变化可能让原本非法的字符变合法。
      final r = RadixLogic.parse(_custom.text, _customRadix);
      if (r.ok) {
        _value = r.value;
        _error = null;
        _errorField = null;
        _syncOthers('custom');
      } else {
        _error = r.error;
        _errorField = 'custom';
      }
    });
  }

  void _clearAll() {
    setState(() {
      for (final c in [_bin, _oct, _dec, _hex, _custom]) {
        c.clear();
      }
      _value = null;
      _error = null;
      _errorField = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ToolScaffold(
      icon: Icons.numbers,
      title: '多进制转换器',
      subtitle: '二/八/十/十六进制 + 自定义 (2~36) 实时互转 · 64 位有符号整数',
      actions: [
        PasteButton(
            controller: _dec, dense: true, onPasted: () => _handle('dec')),
        ClearButton(dense: true, onClear: _clearAll),
      ],
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            children: [
              _row(p, 'bin'),
              const SizedBox(height: Dims.gapMd),
              _row(p, 'oct'),
              const SizedBox(height: Dims.gapMd),
              _row(p, 'dec'),
              const SizedBox(height: Dims.gapMd),
              _row(p, 'hex'),
              const SizedBox(height: Dims.gapLg),
              const Divider(),
              const SizedBox(height: Dims.gapSm),
              _customRow(p),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(AppPalette p, String field) {
    final hasError = _errorField == field;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 96,
          child: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text('${_labelOf(field)} (${_radixOf(field)})',
                style: TextStyle(fontSize: 13, color: p.textSecondary)),
          ),
        ),
        Expanded(
          child: TextField(
            controller: _ctrlOf(field),
            onChanged: (_) => _handle(field),
            style: context.mono(size: 15),
            decoration: InputDecoration(
              isDense: true,
              hintText: '在此输入…',
              errorText: hasError ? _error : null,
              errorMaxLines: 2,
            ),
          ),
        ),
        CopyButton(text: () => _ctrlOf(field).text, label: '', dense: true),
      ],
    );
  }

  Widget _customRow(AppPalette p) {
    final hasError = _errorField == 'custom';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 96,
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('自定义进制', style: TextStyle(fontSize: 13, color: p.textSecondary)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _stepBtn(p, Icons.remove, () => _changeCustomRadix(-1)),
                    SizedBox(
                      width: 28,
                      child: Text('$_customRadix',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: p.accent)),
                    ),
                    _stepBtn(p, Icons.add, () => _changeCustomRadix(1)),
                  ],
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: TextField(
            controller: _custom,
            onChanged: (_) => _handle('custom'),
            style: context.mono(size: 15),
            decoration: InputDecoration(
              isDense: true,
              hintText: '2~36 进制，字母不分大小写…',
              errorText: hasError ? _error : null,
              errorMaxLines: 2,
            ),
          ),
        ),
        CopyButton(text: () => _custom.text, label: '', dense: true),
      ],
    );
  }

  Widget _stepBtn(AppPalette p, IconData icon, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(4),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Icon(icon, size: 14, color: p.textSecondary),
      ),
    );
  }
}

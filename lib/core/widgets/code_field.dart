import 'package:flutter/material.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:flutter_highlight/themes/atom-one-light.dart';

import '../theme/app_theme.dart';

/// 等宽代码输入框：多行、填满可用高度、可选只读。
class CodeInput extends StatelessWidget {
  final TextEditingController controller;
  final String? hint;
  final bool readOnly;
  final ValueChanged<String>? onChanged;
  final double fontSize;
  final int? maxLines;
  final FocusNode? focusNode;

  const CodeInput({
    super.key,
    required this.controller,
    this.hint,
    this.readOnly = false,
    this.onChanged,
    this.fontSize = 13,
    this.maxLines,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      decoration: BoxDecoration(
        color: p.surfaceAlt,
        border: Border.all(color: p.border),
        borderRadius: BorderRadius.circular(Dims.radiusSm),
      ),
      clipBehavior: Clip.antiAlias,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        readOnly: readOnly,
        onChanged: onChanged,
        expands: maxLines == null,
        maxLines: maxLines,
        minLines: maxLines == null ? null : 1,
        textAlignVertical: TextAlignVertical.top,
        keyboardType: TextInputType.multiline,
        style: context.mono(size: fontSize),
        cursorColor: p.accent,
        scrollPadding: const EdgeInsets.all(20),
        decoration: InputDecoration(
          filled: false,
          border: InputBorder.none,
          isDense: true,
          hintText: hint,
          hintStyle: context.mono(size: fontSize, color: p.textSecondary),
          contentPadding: const EdgeInsets.all(Dims.gap),
        ),
      ),
    );
  }
}

/// 只读语法高亮视图。
class HighlightedView extends StatelessWidget {
  final String code;
  final String language;
  final double fontSize;
  const HighlightedView({
    super.key,
    required this.code,
    this.language = 'json',
    this.fontSize = 13,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: p.surfaceAlt,
        border: Border.all(color: p.border),
        borderRadius: BorderRadius.circular(Dims.radiusSm),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Dims.gap),
        child: HighlightView(
          code.isEmpty ? ' ' : code,
          language: language,
          theme: dark ? atomOneDarkTheme : atomOneLightTheme,
          textStyle: TextStyle(
            fontFamilyFallback: kMonoFontFallback,
            fontSize: fontSize,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}

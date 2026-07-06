import 'dart:convert';

/// JSON 处理结果。
class JsonResult {
  final String? output;
  final Object? parsed;
  final String? error;
  final int? line;
  final int? col;
  const JsonResult({this.output, this.parsed, this.error, this.line, this.col});

  bool get ok => error == null;
}

class JsonLogic {
  /// 缩进风格。
  static String indentFor(String style) => switch (style) {
        'tab' => '\t',
        '4' => '    ',
        _ => '  ',
      };

  static JsonResult format(String input, String style) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return const JsonResult(output: '');
    }
    try {
      final obj = json.decode(trimmed);
      final encoder = JsonEncoder.withIndent(indentFor(style));
      return JsonResult(output: encoder.convert(obj), parsed: obj);
    } on FormatException catch (e) {
      final loc = _locate(trimmed, e.offset);
      return JsonResult(
        error: _cleanMessage(e.message),
        line: loc?.$1,
        col: loc?.$2,
      );
    } catch (e) {
      return JsonResult(error: e.toString());
    }
  }

  static JsonResult minify(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return const JsonResult(output: '');
    try {
      final obj = json.decode(trimmed);
      return JsonResult(output: json.encode(obj), parsed: obj);
    } on FormatException catch (e) {
      final loc = _locate(trimmed, e.offset);
      return JsonResult(
          error: _cleanMessage(e.message), line: loc?.$1, col: loc?.$2);
    }
  }

  /// 代码级转义：把 JSON 文本变成可嵌入字符串的转义形式。
  static String escape(String input) => json.encode(input);

  /// 去转义：把带引号的转义字符串还原。
  static JsonResult unescape(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return const JsonResult(output: '');
    try {
      // 若本身没有外层引号，补上再解码。
      final wrapped =
          (trimmed.startsWith('"') && trimmed.endsWith('"'))
              ? trimmed
              : json.encode(trimmed);
      final decoded = json.decode(wrapped);
      return JsonResult(output: decoded.toString());
    } catch (e) {
      return JsonResult(error: '无法去转义：${e.toString()}');
    }
  }

  static (int, int)? _locate(String source, int? offset) {
    if (offset == null || offset < 0) return null;
    var line = 1, col = 1;
    for (var i = 0; i < offset && i < source.length; i++) {
      if (source[i] == '\n') {
        line++;
        col = 1;
      } else {
        col++;
      }
    }
    return (line, col);
  }

  static String _cleanMessage(String m) {
    // 去掉冗长的源码片段，只保留核心提示。
    final idx = m.indexOf('\n');
    return idx > 0 ? m.substring(0, idx) : m;
  }
}

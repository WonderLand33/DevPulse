/// 极简安全表达式求值器：支持 + - * / % ( ) 与小数、一元负号。
/// 纯本地、无 eval，用于命令面板的即时运算预览。
class Calc {
  final String _src;
  int _pos = 0;
  Calc(this._src);

  static double? tryEval(String input) {
    final s = input.trim();
    if (s.isEmpty) return null;
    // 至少包含一个运算符或括号，避免把纯数字也当表达式高亮
    if (!RegExp(r'[+\-*/%()]').hasMatch(s)) return null;
    if (!RegExp(r'^[0-9+\-*/%.()\s]+$').hasMatch(s)) return null;
    try {
      final c = Calc(s);
      final v = c._parseExpr();
      c._skipWs();
      if (c._pos != c._src.length) return null;
      if (v.isNaN || v.isInfinite) return null;
      return v;
    } catch (_) {
      return null;
    }
  }

  void _skipWs() {
    while (_pos < _src.length && _src[_pos] == ' ') {
      _pos++;
    }
  }

  double _parseExpr() {
    var value = _parseTerm();
    while (true) {
      _skipWs();
      if (_pos >= _src.length) break;
      final op = _src[_pos];
      if (op == '+' || op == '-') {
        _pos++;
        final rhs = _parseTerm();
        value = op == '+' ? value + rhs : value - rhs;
      } else {
        break;
      }
    }
    return value;
  }

  double _parseTerm() {
    var value = _parseFactor();
    while (true) {
      _skipWs();
      if (_pos >= _src.length) break;
      final op = _src[_pos];
      if (op == '*' || op == '/' || op == '%') {
        _pos++;
        final rhs = _parseFactor();
        if (op == '*') {
          value *= rhs;
        } else if (op == '/') {
          value /= rhs;
        } else {
          value %= rhs;
        }
      } else {
        break;
      }
    }
    return value;
  }

  double _parseFactor() {
    _skipWs();
    final ch = _src[_pos];
    if (ch == '(') {
      _pos++;
      final v = _parseExpr();
      _skipWs();
      if (_pos >= _src.length || _src[_pos] != ')') {
        throw const FormatException('missing )');
      }
      _pos++;
      return v;
    }
    if (ch == '-') {
      _pos++;
      return -_parseFactor();
    }
    if (ch == '+') {
      _pos++;
      return _parseFactor();
    }
    return _parseNumber();
  }

  double _parseNumber() {
    _skipWs();
    final start = _pos;
    while (_pos < _src.length &&
        (RegExp(r'[0-9.]').hasMatch(_src[_pos]))) {
      _pos++;
    }
    if (_pos == start) throw const FormatException('number expected');
    return double.parse(_src.substring(start, _pos));
  }
}

/// 数字友好格式化：整数不带小数，浮点去除多余 0。
String prettyNum(double v) {
  if (v == v.roundToDouble() && v.abs() < 1e15) {
    return v.toInt().toString();
  }
  var s = v.toStringAsFixed(6);
  s = s.replaceFirst(RegExp(r'0+$'), '');
  s = s.replaceFirst(RegExp(r'\.$'), '');
  return s;
}

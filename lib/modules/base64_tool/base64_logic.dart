import 'dart:convert';
import 'dart:typed_data';

import 'package:fast_gbk/fast_gbk.dart' as gbklib;

class Base64Logic {
  /// 文本 → Base64（可选 GBK 编码）。
  static String encodeText(String input, {bool gbk = false}) {
    if (input.isEmpty) return '';
    final bytes = gbk ? gbklib.gbk.encode(input) : utf8.encode(input);
    return base64.encode(bytes);
  }

  /// Base64 → 文本（可选 GBK 解码）。
  static ({String? text, String? error}) decodeText(String input,
      {bool gbk = false}) {
    final s = _sanitize(input);
    if (s.isEmpty) return (text: '', error: null);
    try {
      final bytes = base64.decode(_pad(s));
      final text = gbk ? gbklib.gbk.decode(bytes) : utf8.decode(bytes);
      return (text: text, error: null);
    } catch (e) {
      return (text: null, error: '无效的 Base64 或编码不匹配');
    }
  }

  /// 字节 → DataURL。
  static String toDataUrl(Uint8List bytes, String mime) =>
      'data:$mime;base64,${base64.encode(bytes)}';

  /// 从 Base64 或 DataURL 解出图片字节。
  static Uint8List? decodeImage(String input) {
    var s = input.trim();
    final comma = s.indexOf(',');
    if (s.startsWith('data:') && comma > 0) {
      s = s.substring(comma + 1);
    }
    s = _sanitize(s);
    if (s.isEmpty) return null;
    try {
      return base64.decode(_pad(s));
    } catch (_) {
      return null;
    }
  }

  static String _sanitize(String s) =>
      s.replaceAll(RegExp(r'\s'), '').trim();

  static String _pad(String s) {
    final mod = s.length % 4;
    return mod == 0 ? s : s + '=' * (4 - mod);
  }

  static String mimeFromExtension(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.bmp')) return 'image/bmp';
    if (lower.endsWith('.svg')) return 'image/svg+xml';
    return 'application/octet-stream';
  }
}

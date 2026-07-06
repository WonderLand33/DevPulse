import 'dart:convert';

import 'package:crypto/crypto.dart';

class JwtParts {
  final String headerRaw;
  final String payloadRaw;
  final String signature;
  final Map<String, dynamic>? header;
  final Map<String, dynamic>? payload;
  final String? error;

  const JwtParts({
    this.headerRaw = '',
    this.payloadRaw = '',
    this.signature = '',
    this.header,
    this.payload,
    this.error,
  });

  String? get alg => header?['alg'] as String?;

  DateTime? _ts(String key) {
    final v = payload?[key];
    if (v is num) {
      return DateTime.fromMillisecondsSinceEpoch((v * 1000).round());
    }
    return null;
  }

  DateTime? get exp => _ts('exp');
  DateTime? get iat => _ts('iat');
  DateTime? get nbf => _ts('nbf');

  bool get isExpired =>
      exp != null && DateTime.now().isAfter(exp!);
}

class JwtLogic {
  static JwtParts parse(String token) {
    final t = token.trim();
    if (t.isEmpty) return const JwtParts();
    final parts = t.split('.');
    if (parts.length != 3) {
      return const JwtParts(error: 'JWT 应由 3 段（以 . 分隔）组成');
    }
    try {
      final header = _decodeJson(parts[0]);
      final payload = _decodeJson(parts[1]);
      return JwtParts(
        headerRaw: parts[0],
        payloadRaw: parts[1],
        signature: parts[2],
        header: header,
        payload: payload,
      );
    } catch (e) {
      return JwtParts(error: '解析失败：${e.toString()}');
    }
  }

  static Map<String, dynamic> _decodeJson(String seg) {
    final decoded = utf8.decode(base64Url.decode(_pad(seg)));
    return json.decode(decoded) as Map<String, dynamic>;
  }

  static String _pad(String s) {
    final mod = s.length % 4;
    return mod == 0 ? s : s + '=' * (4 - mod);
  }

  static String pretty(Map<String, dynamic>? m) =>
      m == null ? '' : const JsonEncoder.withIndent('  ').convert(m);

  /// 本地验签，仅支持 HS256/384/512。返回 null 表示算法不支持。
  static bool? verifyHmac(String token, String secret) {
    final parts = token.trim().split('.');
    if (parts.length != 3) return false;
    Map<String, dynamic> header;
    try {
      header = _decodeJson(parts[0]);
    } catch (_) {
      return false;
    }
    final alg = header['alg'] as String?;
    final hash = switch (alg) {
      'HS256' => sha256,
      'HS384' => sha384,
      'HS512' => sha512,
      _ => null,
    };
    if (hash == null) return null;

    final signingInput = '${parts[0]}.${parts[1]}';
    final hmac = Hmac(hash, utf8.encode(secret));
    final digest = hmac.convert(utf8.encode(signingInput));
    final expected = base64Url.encode(digest.bytes).replaceAll('=', '');
    return _constEq(expected, parts[2]);
  }

  static bool _constEq(String a, String b) {
    if (a.length != b.length) return false;
    var r = 0;
    for (var i = 0; i < a.length; i++) {
      r |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return r == 0;
  }

  /// 常见声明的中文说明。
  static String? claimHint(String key) => const {
        'iss': '签发者',
        'sub': '主题（用户）',
        'aud': '接收方',
        'exp': '过期时间',
        'nbf': '生效时间',
        'iat': '签发时间',
        'jti': 'JWT ID',
      }[key];
}

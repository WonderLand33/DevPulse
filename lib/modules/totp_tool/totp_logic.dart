import 'package:otp/otp.dart';

/// 解析 otpauth:// 得到的配置。
class TotpConfig {
  final String label;
  final String issuer;
  final String secret; // Base32
  final int digits;
  final int period;
  final String algorithm; // SHA1 / SHA256 / SHA512

  const TotpConfig({
    required this.label,
    required this.issuer,
    required this.secret,
    this.digits = 6,
    this.period = 30,
    this.algorithm = 'SHA1',
  });
}

class TotpLogic {
  /// 校验 Base32 密钥是否合法。
  static bool isValidBase32(String s) {
    final cleaned = s.replaceAll(RegExp(r'\s'), '').toUpperCase();
    if (cleaned.isEmpty) return false;
    return RegExp(r'^[A-Z2-7]+=*$').hasMatch(cleaned);
  }

  static String normalizeSecret(String s) =>
      s.replaceAll(RegExp(r'\s'), '').replaceAll('=', '').toUpperCase();

  /// 解析 otpauth://totp/Issuer:account?secret=...&issuer=...&digits=6&period=30&algorithm=SHA1
  static TotpConfig? parseUri(String uri) {
    try {
      final parsed = Uri.parse(uri.trim());
      if (parsed.scheme != 'otpauth' || parsed.host.toLowerCase() != 'totp') {
        return null;
      }
      final secret = parsed.queryParameters['secret'];
      if (secret == null || !isValidBase32(secret)) return null;

      var label = Uri.decodeComponent(
          parsed.pathSegments.isNotEmpty ? parsed.pathSegments.first : '');
      var issuer = parsed.queryParameters['issuer'] ?? '';
      if (label.contains(':')) {
        final parts = label.split(':');
        if (issuer.isEmpty) issuer = parts.first.trim();
        label = parts.sublist(1).join(':').trim();
      }

      return TotpConfig(
        label: label.isEmpty ? (issuer.isEmpty ? '未命名' : issuer) : label,
        issuer: issuer,
        secret: normalizeSecret(secret),
        digits: int.tryParse(parsed.queryParameters['digits'] ?? '6') ?? 6,
        period: int.tryParse(parsed.queryParameters['period'] ?? '30') ?? 30,
        algorithm:
            (parsed.queryParameters['algorithm'] ?? 'SHA1').toUpperCase(),
      );
    } catch (_) {
      return null;
    }
  }

  static Algorithm _algo(String a) => switch (a.toUpperCase()) {
        'SHA256' => Algorithm.SHA256,
        'SHA512' => Algorithm.SHA512,
        _ => Algorithm.SHA1,
      };

  /// 生成当前验证码。
  static String generate(
    String secret, {
    int digits = 6,
    int period = 30,
    String algorithm = 'SHA1',
    int? nowMs,
  }) {
    final t = nowMs ?? DateTime.now().millisecondsSinceEpoch;
    return OTP.generateTOTPCodeString(
      secret,
      t,
      length: digits,
      interval: period,
      algorithm: _algo(algorithm),
      isGoogle: true,
    );
  }

  /// 当前周期剩余秒数。
  static int remaining(int period, {int? nowMs}) {
    final sec = (nowMs ?? DateTime.now().millisecondsSinceEpoch) ~/ 1000;
    return period - (sec % period);
  }

  /// 剩余比例 1..0。
  static double progress(int period, {int? nowMs}) =>
      remaining(period, nowMs: nowMs) / period;

  /// 把 6/8 位验证码美化为 3+3 / 4+4。
  static String pretty(String code) {
    if (code.length == 6) return '${code.substring(0, 3)} ${code.substring(3)}';
    if (code.length == 8) return '${code.substring(0, 4)} ${code.substring(4)}';
    return code;
  }
}

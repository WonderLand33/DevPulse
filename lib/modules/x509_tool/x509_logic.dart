import 'package:basic_utils/basic_utils.dart';

class CertInfo {
  final String subjectCN;
  final String issuerCN;
  final Map<String, String?> subject;
  final Map<String, String?> issuer;
  final DateTime notBefore;
  final DateTime notAfter;
  final String signatureAlgorithm;
  final String publicKeyAlgorithm;
  final int? publicKeyLength;
  final String serialNumber;
  final int version;
  final List<String> san;
  final String? sha256Thumbprint;

  CertInfo({
    required this.subjectCN,
    required this.issuerCN,
    required this.subject,
    required this.issuer,
    required this.notBefore,
    required this.notAfter,
    required this.signatureAlgorithm,
    required this.publicKeyAlgorithm,
    required this.publicKeyLength,
    required this.serialNumber,
    required this.version,
    required this.san,
    required this.sha256Thumbprint,
  });

  int get daysRemaining =>
      notAfter.difference(DateTime.now()).inDays;

  bool get isExpired => DateTime.now().isAfter(notAfter);
  bool get notYetValid => DateTime.now().isBefore(notBefore);

  /// 临期阈值：30 天内告警。
  bool get isExpiringSoon => !isExpired && daysRemaining <= 30;
}

class X509Result {
  final CertInfo? info;
  final String? error;
  const X509Result({this.info, this.error});
}

class X509Logic {
  static X509Result parse(String pem) {
    final text = pem.trim();
    if (text.isEmpty) return const X509Result();
    if (!text.contains('BEGIN CERTIFICATE')) {
      return const X509Result(error: '未检测到 PEM 证书（应以 -----BEGIN CERTIFICATE----- 开头）');
    }
    try {
      final data = X509Utils.x509CertificateFromPem(text);
      final tbs = data.tbsCertificate;
      if (tbs == null) {
        return const X509Result(error: '无法解析证书主体');
      }
      final pk = tbs.subjectPublicKeyInfo;
      return X509Result(
        info: CertInfo(
          subjectCN: tbs.subject['2.5.4.3'] ?? tbs.subject['CN'] ??
              _firstValue(tbs.subject),
          issuerCN: tbs.issuer['2.5.4.3'] ?? tbs.issuer['CN'] ??
              _firstValue(tbs.issuer),
          subject: tbs.subject,
          issuer: tbs.issuer,
          notBefore: tbs.validity.notBefore,
          notAfter: tbs.validity.notAfter,
          signatureAlgorithm: tbs.signatureAlgorithmReadableName ??
              tbs.signatureAlgorithm,
          publicKeyAlgorithm:
              pk.algorithmReadableName ?? pk.algorithm ?? '未知',
          publicKeyLength: pk.length,
          serialNumber: tbs.serialNumber.toRadixString(16).toUpperCase(),
          version: tbs.version,
          san: tbs.extensions?.subjectAlternativNames ?? const [],
          sha256Thumbprint: data.sha256Thumbprint,
        ),
      );
    } catch (e) {
      return X509Result(error: '解析失败：${e.toString()}');
    }
  }

  static String _firstValue(Map<String, String?> m) =>
      m.values.firstWhere((v) => v != null && v.isNotEmpty,
          orElse: () => '—') ??
      '—';

  /// 把 DN Map 格式化为可读串。
  static String formatDn(Map<String, String?> dn) {
    const names = {
      '2.5.4.3': 'CN',
      '2.5.4.10': 'O',
      '2.5.4.11': 'OU',
      '2.5.4.6': 'C',
      '2.5.4.7': 'L',
      '2.5.4.8': 'ST',
    };
    final parts = <String>[];
    dn.forEach((k, v) {
      if (v == null || v.isEmpty) return;
      parts.add('${names[k] ?? k}=$v');
    });
    return parts.join(', ');
  }
}

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:basic_utils/basic_utils.dart';
import 'package:crypto/crypto.dart';
import 'package:pointycastle/export.dart';

// ---------------- 哈希 ----------------
class HashLogic {
  /// 对文本按多种算法求哈希，返回 算法→十六进制。
  static Map<String, String> hashAll(String input) {
    final bytes = utf8.encode(input);
    return {
      'MD5': md5.convert(bytes).toString(),
      'SHA-1': sha1.convert(bytes).toString(),
      'SHA-256': sha256.convert(bytes).toString(),
      'SHA-384': sha384.convert(bytes).toString(),
      'SHA-512': sha512.convert(bytes).toString(),
    };
  }
}

// ---------------- AES ----------------
class AesResult {
  final String? output;
  final String? error;
  const AesResult({this.output, this.error});
}

class AesLogic {
  static final _rng = Random.secure();

  static Uint8List _randomBytes(int n) =>
      Uint8List.fromList(List.generate(n, (_) => _rng.nextInt(256)));

  /// 由口令派生 32 字节密钥（SHA-256）。
  static Uint8List _deriveKey(String password) =>
      Uint8List.fromList(sha256.convert(utf8.encode(password)).bytes);

  /// AES 加密。mode: 'CBC' | 'GCM'。输出 base64(iv || 密文[|| tag])。
  static AesResult encrypt(String plaintext, String password, String mode) {
    if (password.isEmpty) return const AesResult(error: '请输入密钥/口令');
    try {
      final key = _deriveKey(password);
      final data = Uint8List.fromList(utf8.encode(plaintext));
      if (mode == 'GCM') {
        final iv = _randomBytes(12);
        final cipher = GCMBlockCipher(AESEngine())
          ..init(true,
              AEADParameters(KeyParameter(key), 128, iv, Uint8List(0)));
        final ct = cipher.process(data);
        return AesResult(output: base64.encode(Uint8List.fromList(iv + ct)));
      } else {
        final iv = _randomBytes(16);
        final cipher = PaddedBlockCipherImpl(
            PKCS7Padding(), CBCBlockCipher(AESEngine()))
          ..init(
              true,
              PaddedBlockCipherParameters(
                  ParametersWithIV(KeyParameter(key), iv), null));
        final ct = cipher.process(data);
        return AesResult(output: base64.encode(Uint8List.fromList(iv + ct)));
      }
    } catch (e) {
      return AesResult(error: '加密失败：$e');
    }
  }

  /// AES 解密。输入 base64(iv || 密文[|| tag])。
  static AesResult decrypt(String b64, String password, String mode) {
    if (password.isEmpty) return const AesResult(error: '请输入密钥/口令');
    try {
      final key = _deriveKey(password);
      final all = base64.decode(b64.trim());
      if (mode == 'GCM') {
        if (all.length < 13) return const AesResult(error: '密文长度不足');
        final iv = all.sublist(0, 12);
        final ct = all.sublist(12);
        final cipher = GCMBlockCipher(AESEngine())
          ..init(false,
              AEADParameters(KeyParameter(key), 128, iv, Uint8List(0)));
        final pt = cipher.process(Uint8List.fromList(ct));
        return AesResult(output: utf8.decode(pt));
      } else {
        if (all.length < 17) return const AesResult(error: '密文长度不足');
        final iv = all.sublist(0, 16);
        final ct = all.sublist(16);
        final cipher = PaddedBlockCipherImpl(
            PKCS7Padding(), CBCBlockCipher(AESEngine()))
          ..init(
              false,
              PaddedBlockCipherParameters(
                  ParametersWithIV(KeyParameter(key), iv), null));
        final pt = cipher.process(Uint8List.fromList(ct));
        return AesResult(output: utf8.decode(pt));
      }
    } catch (e) {
      return AesResult(error: '解密失败（密钥/模式/密文不匹配）');
    }
  }
}

// ---------------- RSA ----------------
class RsaKeyPairPem {
  final String publicPem;
  final String privatePem;
  const RsaKeyPairPem(this.publicPem, this.privatePem);
}

/// 顶层函数，供 compute() 在后台 isolate 生成密钥对（避免卡 UI）。
RsaKeyPairPem generateRsaPem(int keySize) {
  final pair = CryptoUtils.generateRSAKeyPair(keySize: keySize);
  final pub = pair.publicKey as RSAPublicKey;
  final priv = pair.privateKey as RSAPrivateKey;
  return RsaKeyPairPem(
    CryptoUtils.encodeRSAPublicKeyToPem(pub),
    CryptoUtils.encodeRSAPrivateKeyToPem(priv),
  );
}

class RsaResult {
  final String? output;
  final String? error;
  const RsaResult({this.output, this.error});
}

class RsaLogic {
  static RsaResult encrypt(String plaintext, String publicPem) {
    try {
      final pub = CryptoUtils.rsaPublicKeyFromPem(publicPem);
      return RsaResult(output: CryptoUtils.rsaEncrypt(plaintext, pub));
    } catch (e) {
      return const RsaResult(error: '加密失败：请检查公钥 PEM 是否有效');
    }
  }

  static RsaResult decrypt(String cipherText, String privatePem) {
    try {
      final priv = CryptoUtils.rsaPrivateKeyFromPem(privatePem);
      return RsaResult(output: CryptoUtils.rsaDecrypt(cipherText.trim(), priv));
    } catch (e) {
      return const RsaResult(error: '解密失败：请检查私钥与密文是否匹配');
    }
  }

  static RsaResult sign(String message, String privatePem) {
    try {
      final priv = CryptoUtils.rsaPrivateKeyFromPem(privatePem);
      final sig = CryptoUtils.rsaSign(
          priv, Uint8List.fromList(utf8.encode(message)));
      return RsaResult(output: base64.encode(sig));
    } catch (e) {
      return const RsaResult(error: '签名失败：请检查私钥 PEM');
    }
  }

  static ({bool? ok, String? error}) verify(
      String message, String signatureB64, String publicPem) {
    try {
      final pub = CryptoUtils.rsaPublicKeyFromPem(publicPem);
      final ok = CryptoUtils.rsaVerify(
        pub,
        Uint8List.fromList(utf8.encode(message)),
        base64.decode(signatureB64.trim()),
      );
      return (ok: ok, error: null);
    } catch (e) {
      return (ok: null, error: '验签失败：请检查公钥与签名格式');
    }
  }
}

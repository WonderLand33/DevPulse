import 'package:flutter_test/flutter_test.dart';

import 'package:devpulse/core/util/calc.dart';
import 'package:devpulse/modules/base64_tool/base64_logic.dart';
import 'package:devpulse/modules/crypto_tool/crypto_logic.dart';
import 'package:devpulse/modules/cron_tool/cron_logic.dart';
import 'package:devpulse/modules/diff_tool/diff_logic.dart';
import 'package:devpulse/modules/jwt_tool/jwt_logic.dart';
import 'package:devpulse/modules/password_gen/password_logic.dart';
import 'package:devpulse/modules/totp_tool/totp_logic.dart';
import 'package:devpulse/modules/unix_time/unix_time_logic.dart';

void main() {
  group('Calc', () {
    test('基本运算', () {
      expect(Calc.tryEval('1 + 2 * 3'), 7);
      expect(Calc.tryEval('(1 + 2) * 3'), 9);
      expect(Calc.tryEval('10 / 4'), 2.5);
      expect(Calc.tryEval('10 % 3'), 1);
      expect(Calc.tryEval('-5 + 2'), -3);
    });
    test('非表达式返回 null', () {
      expect(Calc.tryEval('42'), isNull); // 纯数字不算
      expect(Calc.tryEval('abc'), isNull);
      expect(Calc.tryEval('1 +'), isNull);
    });
  });

  group('Base64', () {
    test('UTF-8 往返', () {
      const s = 'Hello, 世界! 🌍';
      final enc = Base64Logic.encodeText(s);
      final dec = Base64Logic.decodeText(enc);
      expect(dec.text, s);
    });
    test('GBK 往返', () {
      const s = '开发者脉搏';
      final enc = Base64Logic.encodeText(s, gbk: true);
      final dec = Base64Logic.decodeText(enc, gbk: true);
      expect(dec.text, s);
    });
    test('无填充也能解码', () {
      // "abc" -> YWJj
      final r = Base64Logic.decodeText('YWJj');
      expect(r.text, 'abc');
    });
  });

  group('Password', () {
    test('长度与字符池', () {
      const opt = PasswordOptions(length: 32);
      final pwd = PasswordLogic.generate(opt);
      expect(pwd.length, 32);
    });
    test('排除易混淆字符', () {
      const opt = PasswordOptions(
          length: 200, symbols: false, excludeAmbiguous: true);
      final pwd = PasswordLogic.generate(opt);
      for (final c in 'Il1O0o'.split('')) {
        expect(pwd.contains(c), isFalse, reason: '不应含 $c');
      }
    });
    test('信息熵随长度增加', () {
      final a = PasswordLogic.entropyBits(const PasswordOptions(length: 8));
      final b = PasswordLogic.entropyBits(const PasswordOptions(length: 16));
      expect(b, greaterThan(a));
    });
  });

  group('JWT', () {
    // jwt.io 官方示例，密钥 "your-256-bit-secret"
    const token =
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.'
        'eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.'
        'SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c';
    test('解析三段', () {
      final p = JwtLogic.parse(token);
      expect(p.error, isNull);
      expect(p.payload?['sub'], '1234567890');
      expect(p.payload?['name'], 'John Doe');
      expect(p.alg, 'HS256');
    });
    test('HMAC 验签', () {
      expect(JwtLogic.verifyHmac(token, 'your-256-bit-secret'), isTrue);
      expect(JwtLogic.verifyHmac(token, 'wrong'), isFalse);
    });
  });

  group('TOTP', () {
    // RFC 6238 测试向量：seed 为 ASCII "12345678901234567890" 的 Base32
    const secret = 'GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ';
    test('RFC 6238 向量 (SHA1, 8 位)', () {
      final code = TotpLogic.generate(secret,
          digits: 8, period: 30, algorithm: 'SHA1', nowMs: 59 * 1000);
      expect(code, '94287082');
    });
    test('剩余秒数在 [1, period]', () {
      final r = TotpLogic.remaining(30, nowMs: 0);
      expect(r, inInclusiveRange(1, 30));
    });
    test('otpauth 解析', () {
      final c = TotpLogic.parseUri(
          'otpauth://totp/GitHub:me@x.com?secret=$secret&issuer=GitHub&digits=6&period=30');
      expect(c, isNotNull);
      expect(c!.issuer, 'GitHub');
      expect(c.label, 'me@x.com');
      expect(c.secret, secret);
    });
  });

  group('Cron', () {
    test('每 5 分钟解析', () {
      final c = CronExpr.parse('*/5 * * * *');
      expect(CronDescribe.describe(c), contains('每 5 分钟'));
      final next = c.next(DateTime(2026, 1, 1, 0, 2), 3);
      expect(next.length, 3);
      expect(next.first, DateTime(2026, 1, 1, 0, 5));
    });
    test('每周一 4 点', () {
      final c = CronExpr.parse('0 4 * * 1');
      final next = c.next(DateTime(2026, 1, 1), 1).first;
      expect(next.weekday, DateTime.monday);
      expect(next.hour, 4);
      expect(next.minute, 0);
    });
    test('非法表达式抛异常', () {
      expect(() => CronExpr.parse('* * *'), throwsA(isA<CronParseException>()));
      expect(() => CronExpr.parse('99 * * * *'),
          throwsA(isA<CronParseException>()));
    });
  });

  group('Diff', () {
    test('行级增删改', () {
      final ops = DiffLogic.lineDiff('a\nb\nc', 'a\nB\nc\nd');
      final stats = DiffLogic.stats(ops);
      expect(stats.modified, 1); // b -> B
      expect(stats.added, 1); // + d
    });
    test('忽略大小写', () {
      final ops = DiffLogic.lineDiff('Hello', 'hello', ignoreCase: true);
      expect(ops.every((o) => o.op == DOp.equal), isTrue);
    });
  });

  group('Crypto', () {
    test('SHA-256 已知向量', () {
      expect(HashLogic.hashAll('abc')['SHA-256'],
          'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad');
    });
    test('AES-CBC 往返', () {
      const msg = 'DevPulse 加密测试 🔐';
      final enc = AesLogic.encrypt(msg, 'pwd123', 'CBC');
      expect(enc.output, isNotNull);
      final dec = AesLogic.decrypt(enc.output!, 'pwd123', 'CBC');
      expect(dec.output, msg);
    });
    test('AES-GCM 往返 + 错误口令失败', () {
      const msg = 'secret payload';
      final enc = AesLogic.encrypt(msg, 'right', 'GCM');
      expect(AesLogic.decrypt(enc.output!, 'right', 'GCM').output, msg);
      final bad = AesLogic.decrypt(enc.output!, 'wrong', 'GCM');
      expect(bad.error, isNotNull);
    });
    test('RSA 生成 + 加解密 + 签名验签', () {
      final pair = generateRsaPem(2048);
      const msg = 'hello rsa';
      final enc = RsaLogic.encrypt(msg, pair.publicPem);
      expect(enc.output, isNotNull);
      expect(RsaLogic.decrypt(enc.output!, pair.privatePem).output, msg);

      final sig = RsaLogic.sign(msg, pair.privatePem);
      expect(sig.output, isNotNull);
      expect(RsaLogic.verify(msg, sig.output!, pair.publicPem).ok, isTrue);
      expect(
          RsaLogic.verify('tampered', sig.output!, pair.publicPem).ok, isFalse);
    });
  });

  group('UnixTime', () {
    test('秒/毫秒自动识别', () {
      expect(UnixTimeLogic.parse('1700000000'), 1700000000 * 1000);
      expect(UnixTimeLogic.parse('1700000000000'), 1700000000000);
    });
    test('表达式加减', () {
      expect(UnixTimeLogic.parse('1700000000 + 3600'),
          (1700000000 + 3600) * 1000);
    });
  });
}

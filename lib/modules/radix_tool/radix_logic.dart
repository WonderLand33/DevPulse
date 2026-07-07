/// 多进制转换核心逻辑。基于 Dart 原生 [BigInt.parse] / [int.toRadixString]，
/// 两者均原生支持 2~36 进制、正负号前缀、大小写字母数字，无需手写解析。
class RadixResult {
  final int? value;
  final String? error;
  const RadixResult({this.value, this.error});
  bool get ok => error == null;
}

class RadixLogic {
  static const minRadix = 2;
  static const maxRadix = 36;

  static final BigInt _int64Min = BigInt.parse('-9223372036854775808');
  static final BigInt _int64Max = BigInt.parse('9223372036854775807');

  /// 把给定进制的字符串解析为 64 位有符号整数。
  /// 空输入返回 `RadixResult()`（value 和 error 均为 null，代表"暂无输入"）。
  static RadixResult parse(String input, int radix) {
    final s = input.trim();
    if (s.isEmpty) return const RadixResult();
    if (radix < minRadix || radix > maxRadix) {
      return const RadixResult(error: '进制必须在 2~36 之间');
    }
    BigInt value;
    try {
      value = BigInt.parse(s, radix: radix);
    } on FormatException {
      return RadixResult(error: '包含对 $radix 进制无效的字符');
    }
    if (value < _int64Min || value > _int64Max) {
      return const RadixResult(error: '超出 64 位有符号整数范围');
    }
    return RadixResult(value: value.toInt());
  }

  /// 把十进制数值格式化为给定进制字符串（字母固定小写）。
  static String format(int value, int radix) => value.toRadixString(radix);
}

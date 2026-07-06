import 'dart:math';

class PasswordOptions {
  final int length;
  final bool upper;
  final bool lower;
  final bool digits;
  final bool symbols;
  final bool excludeAmbiguous;

  const PasswordOptions({
    this.length = 20,
    this.upper = true,
    this.lower = true,
    this.digits = true,
    this.symbols = true,
    this.excludeAmbiguous = true,
  });

  PasswordOptions copyWith({
    int? length,
    bool? upper,
    bool? lower,
    bool? digits,
    bool? symbols,
    bool? excludeAmbiguous,
  }) =>
      PasswordOptions(
        length: length ?? this.length,
        upper: upper ?? this.upper,
        lower: lower ?? this.lower,
        digits: digits ?? this.digits,
        symbols: symbols ?? this.symbols,
        excludeAmbiguous: excludeAmbiguous ?? this.excludeAmbiguous,
      );
}

class PasswordLogic {
  static const _upper = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const _lower = 'abcdefghijklmnopqrstuvwxyz';
  static const _digits = '0123456789';
  static const _symbols = r'!@#$%^&*()-_=+[]{};:,.<>/?~';
  static const _ambiguous = 'Il1O0o';

  static final _rng = Random.secure();

  static String pool(PasswordOptions o) {
    var p = '';
    if (o.upper) p += _upper;
    if (o.lower) p += _lower;
    if (o.digits) p += _digits;
    if (o.symbols) p += _symbols;
    if (o.excludeAmbiguous) {
      p = p.split('').where((c) => !_ambiguous.contains(c)).join();
    }
    return p;
  }

  static String generate(PasswordOptions o) {
    final p = pool(o);
    if (p.isEmpty || o.length <= 0) return '';
    final buf = StringBuffer();
    for (var i = 0; i < o.length; i++) {
      buf.write(p[_rng.nextInt(p.length)]);
    }
    return buf.toString();
  }

  /// 信息熵（比特）= length * log2(poolSize)。
  static double entropyBits(PasswordOptions o) {
    final size = pool(o).length;
    if (size <= 1) return 0;
    return o.length * (log(size) / log(2));
  }

  /// 强度分级：0..4。
  static ({int level, String label}) strength(double bits) {
    if (bits < 28) return (level: 0, label: '很弱');
    if (bits < 50) return (level: 1, label: '弱');
    if (bits < 72) return (level: 2, label: '中等');
    if (bits < 100) return (level: 3, label: '强');
    return (level: 4, label: '极强');
  }
}

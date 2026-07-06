import '../../core/util/calc.dart';

class UnixTimeInfo {
  final DateTime local;
  final DateTime utc;
  final int epochMs;
  const UnixTimeInfo(
      {required this.local, required this.utc, required this.epochMs});

  int get epochSec => epochMs ~/ 1000;

  /// 一年中的第几天。
  int get dayOfYear {
    final start = DateTime(local.year, 1, 1);
    return local.difference(start).inDays + 1;
  }

  /// ISO-8601 周数。
  int get weekOfYear {
    final dayOfYearThursday = local
        .add(Duration(days: 4 - (local.weekday == 7 ? 7 : local.weekday)));
    final firstDay = DateTime(dayOfYearThursday.year, 1, 1);
    return ((dayOfYearThursday.difference(firstDay).inDays) / 7).floor() + 1;
  }

  String get weekdayName => const [
        '星期一',
        '星期二',
        '星期三',
        '星期四',
        '星期五',
        '星期六',
        '星期日'
      ][local.weekday - 1];
}

class UnixTimeLogic {
  /// 解析输入为毫秒时间戳。支持：
  ///  - 纯数字（10 位=秒，13 位=毫秒，其它按 unit 提示）
  ///  - 简单加减表达式（如 `1700000000 + 3600`）
  static int? parse(String input, {String unit = 'auto'}) {
    var s = input.trim();
    if (s.isEmpty) return null;

    // 表达式求值（含运算符时）
    final expr = Calc.tryEval(s);
    if (expr != null) s = expr.round().toString();

    final n = int.tryParse(s);
    if (n == null) return null;

    switch (unit) {
      case 'sec':
        return n * 1000;
      case 'ms':
        return n;
      default:
        // 自动识别：13 位及以上视为毫秒，否则视为秒
        final digits = n.abs().toString().length;
        return digits >= 13 ? n : n * 1000;
    }
  }

  static UnixTimeInfo fromMs(int ms) {
    final utc = DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
    final local = DateTime.fromMillisecondsSinceEpoch(ms);
    return UnixTimeInfo(local: local, utc: utc, epochMs: ms);
  }

  static String fmt(DateTime d) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)} '
        '${two(d.hour)}:${two(d.minute)}:${two(d.second)}';
  }

  /// 相对现在的中文描述。
  static String relative(DateTime target, DateTime now) {
    final diff = now.difference(target);
    final past = !diff.isNegative;
    final s = diff.abs();
    String out;
    if (s.inSeconds < 60) {
      out = '${s.inSeconds} 秒';
    } else if (s.inMinutes < 60) {
      out = '${s.inMinutes} 分钟';
    } else if (s.inHours < 24) {
      out = '${s.inHours} 小时';
    } else if (s.inDays < 30) {
      out = '${s.inDays} 天';
    } else if (s.inDays < 365) {
      out = '${(s.inDays / 30).floor()} 个月';
    } else {
      out = '${(s.inDays / 365).floor()} 年';
    }
    return past ? '$out前' : '$out后';
  }
}

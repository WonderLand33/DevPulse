// 纯 Dart Cron 解析：支持 5 段（分 时 日 月 周）与 6 段（秒 分 时 日 月 周）。
// 提供未来执行时间预测与中文自然语言描述。

class CronField {
  final Set<int> values;
  final bool wildcard;
  final int min;
  final int max;
  const CronField(this.values, this.wildcard, this.min, this.max);

  bool matches(int v) => wildcard || values.contains(v);
}

class CronParseException implements Exception {
  final String message;
  CronParseException(this.message);
  @override
  String toString() => message;
}

class CronExpr {
  final bool hasSeconds;
  final CronField second;
  final CronField minute;
  final CronField hour;
  final CronField day;
  final CronField month;
  final CronField weekday;

  CronExpr({
    required this.hasSeconds,
    required this.second,
    required this.minute,
    required this.hour,
    required this.day,
    required this.month,
    required this.weekday,
  });

  static CronExpr parse(String expr) {
    final parts = expr.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || (parts.length != 5 && parts.length != 6)) {
      throw CronParseException('Cron 表达式应为 5 段或 6 段，当前为 ${parts.length} 段');
    }
    final hasSeconds = parts.length == 6;
    final off = hasSeconds ? 1 : 0;
    return CronExpr(
      hasSeconds: hasSeconds,
      second: hasSeconds
          ? _field(parts[0], 0, 59, '秒')
          : _field('0', 0, 59, '秒'),
      minute: _field(parts[off], 0, 59, '分'),
      hour: _field(parts[off + 1], 0, 23, '时'),
      day: _field(parts[off + 2], 1, 31, '日'),
      month: _field(parts[off + 3], 1, 12, '月'),
      weekday: _weekdayField(parts[off + 4]),
    );
  }

  static CronField _field(String s, int min, int max, String name) {
    if (s == '*' || s == '?') {
      return CronField(const {}, true, min, max);
    }
    final values = <int>{};
    for (final token in s.split(',')) {
      var range = token;
      var step = 1;
      if (token.contains('/')) {
        final sp = token.split('/');
        range = sp[0];
        step = int.tryParse(sp[1]) ??
            (throw CronParseException('$name 字段步长无效：$token'));
        if (step <= 0) throw CronParseException('$name 字段步长必须为正');
      }
      int lo, hi;
      if (range == '*') {
        lo = min;
        hi = max;
      } else if (range.contains('-')) {
        final rp = range.split('-');
        lo = int.tryParse(rp[0]) ??
            (throw CronParseException('$name 字段无效：$token'));
        hi = int.tryParse(rp[1]) ??
            (throw CronParseException('$name 字段无效：$token'));
      } else {
        lo = hi = int.tryParse(range) ??
            (throw CronParseException('$name 字段无效：$token'));
      }
      if (lo < min || hi > max || lo > hi) {
        throw CronParseException('$name 字段超出范围 [$min-$max]：$token');
      }
      for (var v = lo; v <= hi; v += step) {
        values.add(v);
      }
    }
    return CronField(values, false, min, max);
  }

  /// 周字段：0 和 7 均表示周日，内部归一为 0-6（0=周日）。
  static CronField _weekdayField(String s) {
    if (s == '*' || s == '?') return const CronField({}, true, 0, 6);
    final f = _field(s.replaceAll('7', '0'), 0, 7, '周');
    final norm = f.values.map((v) => v == 7 ? 0 : v).toSet();
    return CronField(norm, false, 0, 6);
  }

  /// 从 [from] 之后计算 [count] 次执行时间。
  List<DateTime> next(DateTime from, int count) {
    final result = <DateTime>[];
    // 从下一秒/下一分开始
    var t = hasSeconds
        ? DateTime(from.year, from.month, from.day, from.hour, from.minute,
            from.second)
        .add(const Duration(seconds: 1))
        : DateTime(from.year, from.month, from.day, from.hour, from.minute)
            .add(const Duration(minutes: 1));

    final stepDuration =
        hasSeconds ? const Duration(seconds: 1) : const Duration(minutes: 1);
    var iterations = 0;
    final maxIter = hasSeconds ? 3000000 : 3000000;
    while (result.length < count && iterations < maxIter) {
      iterations++;
      if (_matches(t)) {
        result.add(t);
      }
      t = t.add(stepDuration);
    }
    return result;
  }

  bool _matches(DateTime t) {
    if (hasSeconds && !second.matches(t.second)) return false;
    if (!minute.matches(t.minute)) return false;
    if (!hour.matches(t.hour)) return false;
    if (!month.matches(t.month)) return false;
    // 日/周字段：Cron 语义为「任一匹配即可」（除非其中之一为通配）。
    final dowNorm = t.weekday == 7 ? 0 : t.weekday % 7; // Dart: 1=Mon..7=Sun
    final domMatch = day.matches(t.day);
    final dowMatch = weekday.matches(dowNorm);
    if (day.wildcard && weekday.wildcard) {
      // both wildcard -> always ok
    } else if (day.wildcard) {
      if (!dowMatch) return false;
    } else if (weekday.wildcard) {
      if (!domMatch) return false;
    } else {
      if (!(domMatch || dowMatch)) return false;
    }
    return true;
  }
}

class CronDescribe {
  static const _weekdays = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];

  static String describe(CronExpr c) {
    final parts = <String>[];

    // 频率主体
    final timeDesc = _timeDesc(c);
    final dateDesc = _dateDesc(c);
    parts.add(timeDesc);
    if (dateDesc.isNotEmpty) parts.add(dateDesc);

    return parts.where((e) => e.isNotEmpty).join('，');
  }

  static String _two(int v) => v.toString().padLeft(2, '0');

  static String _timeDesc(CronExpr c) {
    final everyMin = c.minute.wildcard;
    final everyHour = c.hour.wildcard;

    // 每 N 分钟 / 每分钟
    if (c.hasSeconds && c.second.wildcard) {
      return '每秒';
    }
    if (everyMin && everyHour) {
      return c.hasSeconds ? '每分钟' : '每分钟';
    }
    if (everyHour && !everyMin && c.minute.values.length == 1) {
      return '每小时的第 ${c.minute.values.first} 分钟';
    }
    if (everyHour && !everyMin) {
      final step = _detectStep(c.minute.values, 0, 59);
      if (step != null) return '每 $step 分钟';
      return '每小时的第 ${_list(c.minute.values)} 分钟';
    }
    if (everyMin && !everyHour) {
      return '每小时（在 ${_list(c.hour.values)} 时）的每分钟';
    }
    // 具体时刻
    if (c.hour.values.length == 1 && c.minute.values.length == 1) {
      return '${_two(c.hour.values.first)}:${_two(c.minute.values.first)}';
    }
    final hourStep = _detectStep(c.hour.values, 0, 23);
    if (hourStep != null && c.minute.values.length == 1) {
      return '每 $hourStep 小时的第 ${c.minute.values.first} 分钟';
    }
    return '在 ${_list(c.hour.values)} 时的 ${_list(c.minute.values)} 分';
  }

  static String _dateDesc(CronExpr c) {
    final b = StringBuffer();
    // 星期
    if (!c.weekday.wildcard) {
      final days = c.weekday.values.toList()..sort();
      final names = days.map((d) => _weekdays[d]).join('、');
      b.write('每逢 $names');
    }
    // 日
    if (!c.day.wildcard) {
      if (b.isNotEmpty) b.write(' 且 ');
      b.write('每月 ${_list(c.day.values)} 日');
    }
    // 月
    if (!c.month.wildcard) {
      if (b.isNotEmpty) b.write(' ');
      b.write('（限 ${_list(c.month.values)} 月）');
    }
    if (b.isEmpty) return '每天';
    return b.toString();
  }

  static int? _detectStep(Set<int> values, int min, int max) {
    if (values.length < 2) return null;
    final sorted = values.toList()..sort();
    final step = sorted[1] - sorted[0];
    if (step <= 0) return null;
    for (var i = 1; i < sorted.length; i++) {
      if (sorted[i] - sorted[i - 1] != step) return null;
    }
    // 必须从 min 开始且覆盖到接近 max，才算规律步长
    if (sorted.first != min) return null;
    return step;
  }

  static String _list(Set<int> values) {
    final sorted = values.toList()..sort();
    return sorted.join('、');
  }
}

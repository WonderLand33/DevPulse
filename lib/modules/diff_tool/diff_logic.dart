import 'package:diff_match_patch/diff_match_patch.dart' as dmp;

enum DOp { equal, delete, insert, replace }

/// 一行的行级操作。
class DiffLineOp {
  final DOp op;
  final String? left;
  final String? right;
  const DiffLineOp(this.op, this.left, this.right);
}

/// 行内字符片段。
class InlineSeg {
  final int op; // -1 删除, 0 相等, 1 新增
  final String text;
  const InlineSeg(this.op, this.text);
}

class DiffStats {
  final int added;
  final int removed;
  final int modified;
  const DiffStats(this.added, this.removed, this.modified);
}

class DiffLogic {
  static String _norm(String s, bool ignoreWs, bool ignoreCase) {
    var r = s;
    if (ignoreWs) r = r.replaceAll(RegExp(r'\s+'), '');
    if (ignoreCase) r = r.toLowerCase();
    return r;
  }

  /// 行级 diff（基于 LCS）。返回按顺序的行操作，delete/insert 已配对为 replace。
  static List<DiffLineOp> lineDiff(
    String a,
    String b, {
    bool ignoreWhitespace = false,
    bool ignoreCase = false,
  }) {
    final A = a.split('\n');
    final B = b.split('\n');
    bool eq(String x, String y) =>
        _norm(x, ignoreWhitespace, ignoreCase) ==
        _norm(y, ignoreWhitespace, ignoreCase);

    final n = A.length, m = B.length;
    // LCS 长度表
    final dp = List.generate(n + 1, (_) => List<int>.filled(m + 1, 0));
    for (var i = n - 1; i >= 0; i--) {
      for (var j = m - 1; j >= 0; j--) {
        dp[i][j] = eq(A[i], B[j])
            ? dp[i + 1][j + 1] + 1
            : (dp[i + 1][j] >= dp[i][j + 1] ? dp[i + 1][j] : dp[i][j + 1]);
      }
    }

    // 回溯，生成原始 del/ins/equal 序列
    final raw = <DiffLineOp>[];
    var i = 0, j = 0;
    while (i < n && j < m) {
      if (eq(A[i], B[j])) {
        raw.add(DiffLineOp(DOp.equal, A[i], B[j]));
        i++;
        j++;
      } else if (dp[i + 1][j] >= dp[i][j + 1]) {
        raw.add(DiffLineOp(DOp.delete, A[i], null));
        i++;
      } else {
        raw.add(DiffLineOp(DOp.insert, null, B[j]));
        j++;
      }
    }
    while (i < n) {
      raw.add(DiffLineOp(DOp.delete, A[i++], null));
    }
    while (j < m) {
      raw.add(DiffLineOp(DOp.insert, null, B[j++]));
    }

    // 把相邻的 delete 段与 insert 段配对为 replace
    final out = <DiffLineOp>[];
    var k = 0;
    while (k < raw.length) {
      if (raw[k].op == DOp.delete) {
        final dels = <DiffLineOp>[];
        while (k < raw.length && raw[k].op == DOp.delete) {
          dels.add(raw[k++]);
        }
        final ins = <DiffLineOp>[];
        while (k < raw.length && raw[k].op == DOp.insert) {
          ins.add(raw[k++]);
        }
        final pair = dels.length < ins.length ? dels.length : ins.length;
        for (var p = 0; p < pair; p++) {
          out.add(DiffLineOp(DOp.replace, dels[p].left, ins[p].right));
        }
        for (var p = pair; p < dels.length; p++) {
          out.add(dels[p]);
        }
        for (var p = pair; p < ins.length; p++) {
          out.add(ins[p]);
        }
      } else {
        out.add(raw[k++]);
      }
    }
    return out;
  }

  /// 单行的字符级差异（用于 replace 行的行内高亮）。
  static List<InlineSeg> inlineDiff(String a, String b) {
    final diffs = dmp.diff(a, b);
    dmp.cleanupSemantic(diffs);
    return diffs
        .map((d) => InlineSeg(d.operation, d.text))
        .toList(growable: false);
  }

  static DiffStats stats(List<DiffLineOp> ops) {
    var added = 0, removed = 0, modified = 0;
    for (final o in ops) {
      switch (o.op) {
        case DOp.insert:
          added++;
        case DOp.delete:
          removed++;
        case DOp.replace:
          modified++;
        case DOp.equal:
          break;
      }
    }
    return DiffStats(added, removed, modified);
  }
}

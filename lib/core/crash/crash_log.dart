import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// 崩溃/异常日志：纯本地写入 `<系统文档目录>/devpulse/crash_log.txt`，
/// 与 Hive 数据同目录，不联网、不上报。
class CrashLog {
  CrashLog._();
  static final CrashLog instance = CrashLog._();

  /// 单个日志文件封顶大小，超出后从尾部保留最近的一半，避免无限增长。
  static const _maxBytes = 1024 * 1024;

  File? _file;

  Future<File> _ensureFile() async {
    final cached = _file;
    if (cached != null) return cached;
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/devpulse');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    final file = File('${dir.path}/crash_log.txt');
    _file = file;
    return file;
  }

  Future<String> get filePath async => (await _ensureFile()).path;

  /// 记录一条异常，返回格式化后的条目文本（供弹窗直接展示）。
  /// 写入失败时静默吞掉——错误处理路径本身不应再抛出新的异常。
  Future<String> record(Object error, StackTrace stack,
      {String source = 'unknown'}) async {
    final entry = _format(error, stack, source);
    try {
      final file = await _ensureFile();
      await file.writeAsString('$entry\n${'-' * 60}\n',
          mode: FileMode.append, flush: true);
      await _trimIfTooLarge(file);
    } catch (_) {
      // ignore
    }
    return entry;
  }

  String _format(Object error, StackTrace stack, String source) {
    final ts = DateTime.now().toIso8601String();
    return '[$ts] ($source)\n$error\n$stack';
  }

  Future<void> _trimIfTooLarge(File file) async {
    final len = await file.length();
    if (len <= _maxBytes) return;
    final bytes = await file.readAsBytes();
    final tail = bytes.sublist(bytes.length - _maxBytes ~/ 2);
    await file.writeAsBytes(tail, flush: true);
  }

  /// 读取完整日志内容（用于设置页展示/复制）。文件不存在时返回空串。
  Future<String> readAll() async {
    try {
      final file = await _ensureFile();
      if (!await file.exists()) return '';
      return await file.readAsString();
    } catch (_) {
      return '';
    }
  }
}

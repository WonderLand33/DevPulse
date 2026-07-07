import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/crash/crash_dialog.dart';
import 'core/storage/kv_store.dart';
import 'core/window/window_service.dart';

Future<void> main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // 捕获组件构建期间抛出的异常：记录日志的同时仍走 Flutter 默认的
    // presentError（保留调试期的红屏/控制台输出）。
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      reportCrash(details.exception, details.stack ?? StackTrace.current,
          source: 'Flutter');
    };

    // 捕获异步回调、Future 链路中未被 try/catch 接住的异常。
    PlatformDispatcher.instance.onError = (error, stack) {
      reportCrash(error, stack, source: 'Platform');
      return true;
    };

    await KvStore.instance.init();
    await WindowService.init();
    runApp(const ProviderScope(child: DevPulseApp()));
  }, (error, stack) {
    // 兜底：极少数情况下连上面两个钩子都没接住的异常。
    reportCrash(error, stack, source: 'Zone');
  });
}

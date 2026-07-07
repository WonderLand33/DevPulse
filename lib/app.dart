import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/crash/crash_dialog.dart';
import 'core/layout/app_shell.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';

class DevPulseApp extends ConsumerWidget {
  const DevPulseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final scale = ref.watch(fontScaleProvider);
    final uiFont = ref.watch(uiFontProvider);
    // 等宽字体通过全局变量供 context.mono 读取。
    kUserMonoFamily = ref.watch(monoFontProvider);

    return MaterialApp(
      navigatorKey: crashNavigatorKey,
      title: 'DevPulse',
      debugShowCheckedModeBanner: false,
      themeMode: mode,
      theme: buildAppTheme(AppPalette.light, Brightness.light, uiFont: uiFont),
      darkTheme:
          buildAppTheme(AppPalette.dark, Brightness.dark, uiFont: uiFont),
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        );
      },
      home: const AppShell(),
    );
  }
}

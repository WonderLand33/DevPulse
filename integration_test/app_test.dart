import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:devpulse/app.dart';
import 'package:devpulse/core/storage/kv_store.dart';
import 'package:devpulse/modules/registry.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('每个模块都能正常构建且无异常', (tester) async {
    await KvStore.instance.init();

    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const DevPulseApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    for (final module in kModules) {
      container.read(selectedModuleProvider.notifier).select(module.id);
      // 避免 pumpAndSettle 在含周期计时器的页面上超时
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(tester.takeException(), isNull,
          reason: '模块 ${module.id} 构建抛出异常');
      // 标题应出现在工具外壳里
      expect(find.text(module.title), findsWidgets,
          reason: '模块 ${module.id} 标题未渲染');
    }
  });

  testWidgets('主题切换不崩溃', (tester) async {
    await KvStore.instance.init();
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const DevPulseApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    container.read(selectedModuleProvider.notifier).select('settings');
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Base64 切换 文本/图片 tab 不清空已输入内容', (tester) async {
    await KvStore.instance.init();
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const DevPulseApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    container.read(selectedModuleProvider.notifier).select('base64');
    await tester.pump(const Duration(milliseconds: 200));

    const sample = 'DevPulse tab-switch regression 中文';
    await tester.enterText(find.byType(TextField).first, sample);
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text(sample), findsWidgets,
        reason: '输入后应立即在文本 tab 中看到内容');

    // 切到「图片」tab。
    await tester.tap(find.text('图片'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.takeException(), isNull);

    // 切回「文本」tab——之前的输入不应被清空。
    await tester.tap(find.text('文本'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text(sample), findsWidgets,
        reason: '切回文本 tab 后，之前输入的内容应仍然存在');
  });
}

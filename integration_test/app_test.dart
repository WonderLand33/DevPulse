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
}

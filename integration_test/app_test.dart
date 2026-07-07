import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:devpulse/app.dart';
import 'package:devpulse/core/storage/kv_store.dart';
import 'package:devpulse/modules/base64_tool/base64_page.dart';
import 'package:devpulse/modules/json_tool/json_page.dart';
import 'package:devpulse/modules/markdown_tool/markdown_page.dart';
import 'package:devpulse/modules/radix_tool/radix_page.dart';
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

    // AppShell 现在让全部模块永久挂载，全应用范围内会有多个同类
    // TextField/按钮标签重复出现，因此把查找范围限定在 Base64Page 子树内，
    // 避免误中其它模块的同名控件。
    final scope = find.byType(Base64Page);

    const sample = 'DevPulse tab-switch regression 中文';
    await tester.enterText(
        find.descendant(of: scope, matching: find.byType(TextField)).first,
        sample);
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.descendant(of: scope, matching: find.text(sample)),
        findsWidgets,
        reason: '输入后应立即在文本 tab 中看到内容');

    // 切到「图片」tab。
    await tester.tap(find.descendant(of: scope, matching: find.text('图片')));
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.takeException(), isNull);

    // 切回「文本」tab——之前的输入不应被清空。
    await tester.tap(find.descendant(of: scope, matching: find.text('文本')));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.descendant(of: scope, matching: find.text(sample)),
        findsWidgets,
        reason: '切回文本 tab 后，之前输入的内容应仍然存在');
  });

  testWidgets('切换到其它侧栏模块再切回，Markdown 编辑内容不被清空', (tester) async {
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

    container.read(selectedModuleProvider.notifier).select('markdown');
    await tester.pump(const Duration(milliseconds: 200));

    // 同上：限定在 MarkdownPage 子树内查找，避免误中其它常驻模块
    // （如 base64/jwt/x509/diff）里同样存在的 TextField。
    final scope = find.byType(MarkdownPage);

    const marker = '# 模块切换回归测试标记 DevPulse';
    await tester.enterText(
        find.descendant(of: scope, matching: find.byType(TextField)).first,
        marker);
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.descendant(of: scope, matching: find.text(marker)),
        findsWidgets,
        reason: '编辑后应立即在编辑框中看到内容');

    // 切到完全不同的侧栏模块（这才是本回归测试的关键——之前的修复只覆盖了
    // 模块内部的子 tab，没有覆盖侧栏顶层模块切换会整页销毁重建的问题）。
    container.read(selectedModuleProvider.notifier).select('todo');
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.takeException(), isNull);

    // 切回 Markdown——之前编辑的内容不应被重置为默认示例文本。
    container.read(selectedModuleProvider.notifier).select('markdown');
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.descendant(of: scope, matching: find.text(marker)),
        findsWidgets,
        reason: '切回 Markdown 模块后，之前编辑的内容应仍然存在');
  });

  testWidgets('JSON 内容搜索（主线程实现，非 re_editor 的 isolate 查找）不崩溃',
      (tester) async {
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

    container.read(selectedModuleProvider.notifier).select('json');
    await tester.pump(const Duration(milliseconds: 200));

    // 「粘贴」「搜索」等按钮标签在其它常驻模块里也存在同名控件，
    // 统一限定在 JsonPage 子树内查找。
    final scope = find.byType(JsonPage);

    // 粘贴一段含重复关键字的 JSON，作为查找目标。
    await Clipboard.setData(
        const ClipboardData(text: '{"hello": "world", "hello2": "again"}'));
    await tester.tap(find.descendant(of: scope, matching: find.text('粘贴')));
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.takeException(), isNull, reason: '粘贴 JSON 后不应抛出异常');

    // 点击「搜索」，唤出自研的主线程查找条。
    await tester.tap(find.descendant(of: scope, matching: find.text('搜索')));
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.takeException(), isNull, reason: '点击搜索不应抛出异常');
    expect(
        find.descendant(of: scope, matching: find.text('在 JSON 中查找…')),
        findsOneWidget,
        reason: '应显示自研的极简查找条');

    // 输入查询词，触发主线程同步匹配 + 跳转到高亮位置。
    await tester.enterText(
        find.descendant(of: scope, matching: find.byType(TextField)).last,
        'hello');
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.takeException(), isNull, reason: '输入查询词不应抛出异常');
    expect(find.descendant(of: scope, matching: find.text('1/2')),
        findsOneWidget,
        reason: '应正确统计到 2 处匹配，当前定位第 1 个');

    // 跳到下一个匹配、关闭查找条，全程不应崩溃。
    await tester
        .tap(find.descendant(of: scope, matching: find.byTooltip('下一个')));
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.takeException(), isNull, reason: '跳转到下一个匹配不应抛出异常');

    await tester
        .tap(find.descendant(of: scope, matching: find.byTooltip('关闭')));
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.takeException(), isNull, reason: '关闭查找条不应抛出异常');
    expect(
        find.descendant(of: scope, matching: find.text('在 JSON 中查找…')),
        findsNothing,
        reason: '关闭后查找条应隐藏');
  });

  testWidgets('多进制转换器：输入二进制自动联动十/十六进制', (tester) async {
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

    container.read(selectedModuleProvider.notifier).select('radix');
    await tester.pump(const Duration(milliseconds: 200));

    final scope = find.byType(RadixPage);
    final fields = find.descendant(of: scope, matching: find.byType(TextField));

    // 顺序：二进制(0) / 八进制(1) / 十进制(2) / 十六进制(3) / 自定义(4)。
    await tester.enterText(fields.at(0), '11111100101'); // 2021
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.takeException(), isNull, reason: '输入二进制不应抛出异常');

    expect(
        tester.widget<TextField>(fields.at(2)).controller!.text, '2021',
        reason: '十进制应自动联动更新为 2021');
    expect(
        tester.widget<TextField>(fields.at(3)).controller!.text, '7e5',
        reason: '十六进制应自动联动更新为 7e5');

    // 非法字符（十进制框输入字母）应报错，且不应污染其它已同步的框。
    await tester.enterText(fields.at(2), '12a');
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.takeException(), isNull, reason: '输入非法字符不应抛出异常');
    expect(find.descendant(of: scope, matching: find.textContaining('无效')),
        findsOneWidget,
        reason: '应显示错误提示');
  });
}

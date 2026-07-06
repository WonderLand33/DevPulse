import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/storage/kv_store.dart';
import 'core/window/window_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await KvStore.instance.init();
  await WindowService.init();
  runApp(const ProviderScope(child: DevPulseApp()));
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 请求切换到某个模块（命令面板 / 智能剪贴板推荐用）。
class NavRequest {
  final int seq;
  final String? moduleId;
  const NavRequest(this.seq, this.moduleId);
}

class NavController extends Notifier<NavRequest> {
  @override
  NavRequest build() => const NavRequest(0, null);

  void goto(String moduleId) => state = NavRequest(state.seq + 1, moduleId);
}

final navRequestProvider =
    NotifierProvider<NavController, NavRequest>(NavController.new);

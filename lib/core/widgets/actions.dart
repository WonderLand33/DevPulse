import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_feedback.dart';
import 'common.dart';

/// 从剪贴板粘贴文本到给定 controller。
class PasteButton extends StatelessWidget {
  final TextEditingController controller;
  final bool dense;
  final VoidCallback? onPasted;
  const PasteButton(
      {super.key, required this.controller, this.dense = false, this.onPasted});

  @override
  Widget build(BuildContext context) {
    return ToolbarButton(
      icon: Icons.content_paste_outlined,
      label: '粘贴',
      dense: dense,
      onTap: () async {
        final data = await Clipboard.getData(Clipboard.kTextPlain);
        final t = data?.text;
        if (t == null || t.isEmpty) {
          if (context.mounted) showToast(context, '剪贴板为空', error: true);
          return;
        }
        controller.text = t;
        onPasted?.call();
      },
    );
  }
}

/// 清空按钮。
class ClearButton extends StatelessWidget {
  final VoidCallback onClear;
  final bool dense;
  const ClearButton({super.key, required this.onClear, this.dense = false});
  @override
  Widget build(BuildContext context) {
    return ToolbarButton(
      icon: Icons.clear_all,
      label: '清空',
      dense: dense,
      onTap: onClear,
    );
  }
}


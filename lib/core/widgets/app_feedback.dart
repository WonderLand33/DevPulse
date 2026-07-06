import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// 轻量 toast（基于 ScaffoldMessenger，主题化）。
void showToast(BuildContext context, String message, {bool error = false}) {
  final p = context.palette;
  final messenger = ScaffoldMessenger.of(context);
  messenger.clearSnackBars();
  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: p.surfaceAlt,
      duration: const Duration(milliseconds: 1600),
      width: 320,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: error ? p.danger : p.border),
        borderRadius: BorderRadius.circular(Dims.radiusSm),
      ),
      content: Row(
        children: [
          Icon(
            error ? Icons.error_outline : Icons.check_circle_outline,
            size: 18,
            color: error ? p.danger : p.success,
          ),
          const SizedBox(width: Dims.gapSm),
          Expanded(
            child: Text(message,
                style: TextStyle(color: p.textPrimary, fontSize: 13)),
          ),
        ],
      ),
    ),
  );
}

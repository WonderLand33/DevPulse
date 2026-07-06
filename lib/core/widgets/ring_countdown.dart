import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// 环形倒计时：progress 0..1，中间显示剩余秒数。
class RingCountdown extends StatelessWidget {
  final double progress; // 剩余比例 1..0
  final int remainingSeconds;
  final double size;
  final Color? color;
  const RingCountdown({
    super.key,
    required this.progress,
    required this.remainingSeconds,
    this.size = 34,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final c = color ??
        (remainingSeconds <= 5 ? p.warning : p.accent);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: progress, end: progress),
              duration: const Duration(milliseconds: 250),
              builder: (context, value, _) => CircularProgressIndicator(
                value: value,
                strokeWidth: 3,
                backgroundColor: p.border,
                valueColor: AlwaysStoppedAnimation(c),
              ),
            ),
          ),
          Text('$remainingSeconds',
              style: TextStyle(
                  fontSize: size * 0.34,
                  fontWeight: FontWeight.w600,
                  color: c)),
        ],
      ),
    );
  }
}

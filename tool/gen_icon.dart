import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:image/src/formats/ico_encoder.dart';

/// 依据首页左上角的 graphic_eq 均衡器波形，程序化生成 DevPulse 应用图标。
///
/// 输出一个包含 Windows 全部常用尺寸的多分辨率 .ico：
///   16 / 20 / 24 / 32 / 40 / 48 / 64 / 96 / 128 / 256
/// 覆盖任务栏（100%~200% DPI 缩放）、标题栏、Alt-Tab、资源管理器各视图。
///
/// 每个尺寸都按该尺寸的比例重新计算圆角/间距/条宽（而不是从 256px 图缩小），
/// 并以 4x 超采样再用三次插值降采样，避免直接栅格填充在小尺寸下的锯齿。
const List<int> kIconSizes = [16, 20, 24, 32, 40, 48, 64, 96, 128, 256];

/// 按给定像素尺寸绘制一张图标（内部以 4x 超采样渲染再降采样抗锯齿）。
img.Image renderIcon(int size) {
  const supersample = 4;
  final s = size * supersample;

  final image = img.Image(width: s, height: s, numChannels: 4);
  img.fill(image, color: img.ColorRgba8(0, 0, 0, 0));

  // 圆角方形背景（品牌蓝），留白比例与 256px 版本一致。
  final pad = (s * 0.047).round(); // 12/256
  final bgRadius = s * 0.211; // 54/256
  final bg = img.ColorRgb8(0x3B, 0x82, 0xF6);
  img.fillRect(image,
      x1: pad,
      y1: pad,
      x2: s - 1 - pad,
      y2: s - 1 - pad,
      color: bg,
      radius: bgRadius);

  // 均衡器竖条（白色，对称脉冲），比例与 256px 版本一致。
  final white = img.ColorRgb8(255, 255, 255);
  const heights = [0.42, 0.72, 1.0, 0.72, 0.42];
  final barW = (s * 0.078).round(); // 20/256
  final gap = (s * 0.070).round(); // 18/256
  final totalW = heights.length * barW + (heights.length - 1) * gap;
  final startX = (s - totalW) ~/ 2;
  final cy = s ~/ 2;
  final maxH = s * 0.461; // 118/256
  for (var i = 0; i < heights.length; i++) {
    final h = (maxH * heights[i]).round().clamp(barW, s);
    final x1 = startX + i * (barW + gap);
    img.fillRect(image,
        x1: x1,
        y1: cy - h ~/ 2,
        x2: x1 + barW,
        y2: cy + h ~/ 2,
        color: white,
        radius: barW / 2);
  }

  // 超采样降采样：三次插值天然产生抗锯齿边缘。
  return img.copyResize(image,
      width: size, height: size, interpolation: img.Interpolation.cubic);
}

void main() {
  Directory('dist').createSync(recursive: true);

  final images = kIconSizes.map(renderIcon).toList();

  // 多分辨率 ICO：直接用底层编码器写入全部尺寸帧。
  final icoBytes = IcoEncoder().encodeImages(images);
  File('windows/runner/resources/app_icon.ico').writeAsBytesSync(icoBytes);

  // 预览：最大尺寸 + 实际任务栏常见尺寸，便于肉眼核对清晰度。
  final bySize = {for (final img in images) img.width: img};
  File('dist/devpulse_icon_256.png')
      .writeAsBytesSync(img.encodePng(bySize[256]!));
  File('dist/devpulse_icon_48.png')
      .writeAsBytesSync(img.encodePng(bySize[48]!));
  File('dist/devpulse_icon_32.png')
      .writeAsBytesSync(img.encodePng(bySize[32]!));
  File('dist/devpulse_icon_16.png')
      .writeAsBytesSync(img.encodePng(bySize[16]!));

  stdout.writeln(
      '已生成多分辨率图标（${kIconSizes.join("/")}px）：windows/runner/resources/app_icon.ico');
}

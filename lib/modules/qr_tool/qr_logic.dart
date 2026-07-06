import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:zxing2/qrcode.dart';

class QrLogic {
  /// 从图片字节解码二维码，返回文本；失败返回 null。
  static String? decode(Uint8List bytes) {
    final image = img.decodeImage(bytes);
    if (image == null) return null;

    final w = image.width;
    final h = image.height;
    final pixels = Int32List(w * h);
    var i = 0;
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        final px = image.getPixel(x, y);
        final r = px.r.toInt();
        final g = px.g.toInt();
        final b = px.b.toInt();
        pixels[i++] = (0xFF << 24) | (r << 16) | (g << 8) | b;
      }
    }

    try {
      final source = RGBLuminanceSource(w, h, pixels);
      final bitmap = BinaryBitmap(HybridBinarizer(source));
      final reader = QRCodeReader();
      final result = reader.decode(bitmap);
      return result.text;
    } catch (_) {
      // 尝试放大后再解一次（小图容错）
      try {
        final scaled = img.copyResize(image, width: w * 2);
        return _decodeImage(scaled);
      } catch (_) {
        return null;
      }
    }
  }

  static String? _decodeImage(img.Image image) {
    final w = image.width;
    final h = image.height;
    final pixels = Int32List(w * h);
    var i = 0;
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        final px = image.getPixel(x, y);
        pixels[i++] = (0xFF << 24) |
            (px.r.toInt() << 16) |
            (px.g.toInt() << 8) |
            px.b.toInt();
      }
    }
    final source = RGBLuminanceSource(w, h, pixels);
    final bitmap = BinaryBitmap(HybridBinarizer(source));
    return QRCodeReader().decode(bitmap).text;
  }
}

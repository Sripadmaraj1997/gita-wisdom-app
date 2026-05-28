import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

void main() {
  final outputDir = Directory('assets/branding')..createSync(recursive: true);
  _writeIcon('${outputDir.path}/app_icon.png');
  _writeSplash('${outputDir.path}/splash_logo.png');
}

void _writeIcon(String path) {
  const size = 1024;
  final image = img.Image(width: size, height: size);
  _fillGradient(image);
  _drawHalo(image, size ~/ 2, size ~/ 2, 340);
  _drawBook(image, size ~/ 2, 555, 420);
  _drawLotus(image, size ~/ 2, 438, 300);
  _drawSun(image, size ~/ 2, 315, 76);
  File(path).writeAsBytesSync(img.encodePng(image));
}

void _writeSplash(String path) {
  const size = 1152;
  final image = img.Image(width: size, height: size);
  _fillGradient(image);
  _drawHalo(image, size ~/ 2, 510, 360);
  _drawBook(image, size ~/ 2, 650, 440);
  _drawLotus(image, size ~/ 2, 510, 330);
  _drawSun(image, size ~/ 2, 365, 82);
  File(path).writeAsBytesSync(img.encodePng(image));
}

void _fillGradient(img.Image image) {
  final navy = img.ColorRgb8(7, 18, 33);
  final purple = img.ColorRgb8(48, 25, 85);
  for (var y = 0; y < image.height; y++) {
    final t = y / image.height;
    final r = _lerp(purple.r, navy.r, t);
    final g = _lerp(purple.g, navy.g, t);
    final b = _lerp(purple.b, navy.b, t);
    img.drawLine(
      image,
      x1: 0,
      y1: y,
      x2: image.width,
      y2: y,
      color: img.ColorRgb8(r, g, b),
    );
  }
}

void _drawHalo(img.Image image, int cx, int cy, int radius) {
  for (var i = radius; i > 0; i -= 8) {
    final alpha = (22 * (i / radius)).round();
    img.drawCircle(
      image,
      x: cx,
      y: cy,
      radius: i,
      color: img.ColorRgba8(246, 211, 101, alpha),
    );
  }
  img.drawCircle(
    image,
    x: cx,
    y: cy,
    radius: radius,
    color: img.ColorRgba8(246, 211, 101, 80),
  );
}

void _drawSun(img.Image image, int cx, int cy, int radius) {
  final gold = img.ColorRgb8(246, 211, 101);
  img.drawCircle(image, x: cx, y: cy, radius: radius, color: gold);
  img.drawCircle(
    image,
    x: cx,
    y: cy,
    radius: radius - 18,
    color: img.ColorRgb8(245, 158, 11),
  );
}

void _drawLotus(img.Image image, int cx, int cy, int width) {
  final gold = img.ColorRgb8(246, 211, 101);
  final saffron = img.ColorRgb8(245, 158, 11);
  final points = <math.Point<int>>[
    math.Point(cx, cy - width ~/ 2),
    math.Point(cx - width ~/ 7, cy - width ~/ 10),
    math.Point(cx, cy + width ~/ 5),
    math.Point(cx + width ~/ 7, cy - width ~/ 10),
  ];
  _fillPolygon(image, points, gold);
  _fillPolygon(
      image,
      [
        math.Point(cx - width ~/ 2, cy - width ~/ 4),
        math.Point(cx - width ~/ 7, cy - width ~/ 16),
        math.Point(cx - width ~/ 12, cy + width ~/ 4),
        math.Point(cx - width ~/ 3, cy + width ~/ 8),
      ],
      saffron);
  _fillPolygon(
      image,
      [
        math.Point(cx + width ~/ 2, cy - width ~/ 4),
        math.Point(cx + width ~/ 7, cy - width ~/ 16),
        math.Point(cx + width ~/ 12, cy + width ~/ 4),
        math.Point(cx + width ~/ 3, cy + width ~/ 8),
      ],
      saffron);
  _fillPolygon(
      image,
      [
        math.Point(cx - width ~/ 3, cy + width ~/ 16),
        math.Point(cx, cy + width ~/ 3),
        math.Point(cx + width ~/ 3, cy + width ~/ 16),
        math.Point(cx, cy + width ~/ 5),
      ],
      gold);
}

void _drawBook(img.Image image, int cx, int cy, int width) {
  final ivory = img.ColorRgb8(255, 248, 231);
  final gold = img.ColorRgb8(246, 211, 101);
  final left = cx - width ~/ 2;
  final right = cx + width ~/ 2;
  final top = cy - width ~/ 6;
  final bottom = cy + width ~/ 5;
  _fillPolygon(
      image,
      [
        math.Point(cx, top + 30),
        math.Point(left, top),
        math.Point(left + 30, bottom),
        math.Point(cx, bottom + 26),
      ],
      ivory);
  _fillPolygon(
      image,
      [
        math.Point(cx, top + 30),
        math.Point(right, top),
        math.Point(right - 30, bottom),
        math.Point(cx, bottom + 26),
      ],
      ivory);
  img.drawLine(image,
      x1: cx,
      y1: top + 38,
      x2: cx,
      y2: bottom + 16,
      color: gold,
      thickness: 10);
  img.drawLine(image,
      x1: left + 70,
      y1: top + 70,
      x2: cx - 42,
      y2: top + 98,
      color: gold,
      thickness: 7);
  img.drawLine(image,
      x1: right - 70,
      y1: top + 70,
      x2: cx + 42,
      y2: top + 98,
      color: gold,
      thickness: 7);
}

void _fillPolygon(
    img.Image image, List<math.Point<int>> points, img.Color color) {
  img.fillPolygon(image,
      vertices: points.map((p) => img.Point(p.x, p.y)).toList(), color: color);
}

int _lerp(num a, num b, double t) => (a + (b - a) * t).round();

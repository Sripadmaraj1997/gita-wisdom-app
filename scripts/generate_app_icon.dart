import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

const _size = 1024;

void main() {
  final canvas = img.Image(width: _size, height: _size, numChannels: 4);

  _paintBackground(canvas);
  _paintLotusGlow(canvas);
  _paintFluteGlow(canvas);
  _paintFlute(canvas);
  _paintPeacockFeather(canvas);
  _paintWordmark(canvas);
  _paintVignette(canvas);

  final output = File('assets/icon/app_icon.png')..createSync(recursive: true);
  output.writeAsBytesSync(img.encodePng(canvas, level: 9));

  File('assets/branding/app_icon.png')
    ..createSync(recursive: true)
    ..writeAsBytesSync(img.encodePng(canvas, level: 9));

  stdout.writeln('Generated assets/icon/app_icon.png');
}

void _paintBackground(img.Image canvas) {
  const top = _Rgb(7, 30, 61);
  const middle = _Rgb(6, 26, 46);
  const bottom = _Rgb(7, 30, 61);

  for (var y = 0; y < _size; y++) {
    final t = y / (_size - 1);
    final base = t < 0.52
        ? _lerpRgb(top, middle, t / 0.52)
        : _lerpRgb(middle, bottom, (t - 0.52) / 0.48);

    for (var x = 0; x < _size; x++) {
      final dx = (x - _size * 0.52) / _size;
      final dy = (y - _size * 0.42) / _size;
      final glow = math.max(0.0, 1.0 - math.sqrt(dx * dx + dy * dy) / 0.48);
      const gold = _Rgb(212, 175, 55);
      final color = _lerpRgb(base, gold, glow * glow * 0.18);
      canvas.setPixelRgba(x, y, color.r, color.g, color.b, 255);
    }
  }
}

void _paintLotusGlow(img.Image canvas) {
  _radialGlow(canvas, 512, 675, 360, const _Rgb(244, 231, 178), 0.34);
  _radialGlow(canvas, 512, 720, 220, const _Rgb(212, 175, 55), 0.22);

  final petals = [
    (512.0, 690.0, 92.0, 180.0, 0.0),
    (420.0, 704.0, 80.0, 158.0, -0.52),
    (604.0, 704.0, 80.0, 158.0, 0.52),
    (348.0, 744.0, 68.0, 138.0, -0.95),
    (676.0, 744.0, 68.0, 138.0, 0.95),
  ];

  for (final petal in petals) {
    _fillRotatedEllipse(
      canvas,
      petal.$1,
      petal.$2,
      petal.$3,
      petal.$4,
      petal.$5,
      const _Rgb(230, 199, 106),
      0.28,
    );
  }
}

void _paintFluteGlow(img.Image canvas) {
  _capsule(canvas, 202, 555, 822, 404, 88, const _Rgb(244, 231, 178), 0.16);
  _capsule(canvas, 222, 548, 802, 408, 64, const _Rgb(212, 175, 55), 0.18);
}

void _paintFlute(img.Image canvas) {
  _capsule(canvas, 222, 548, 802, 408, 54, const _Rgb(157, 111, 28), 1.0);
  _capsule(canvas, 232, 538, 792, 413, 42, const _Rgb(230, 199, 106), 1.0);
  _capsule(canvas, 242, 530, 782, 416, 23, const _Rgb(244, 231, 178), 0.48);

  for (final t in [0.10, 0.88]) {
    final p = _pointOnLine(222, 548, 802, 408, t);
    _band(canvas, p.x, p.y, -0.247, 44, 74, const _Rgb(212, 175, 55));
    _band(canvas, p.x, p.y, -0.247, 22, 82, const _Rgb(244, 231, 178));
  }

  for (final t in [0.32, 0.43, 0.54, 0.65, 0.76]) {
    final p = _pointOnLine(222, 548, 802, 408, t);
    _fillCircle(canvas, p.x, p.y, 22, const _Rgb(244, 231, 178), 0.9);
    _fillCircle(canvas, p.x, p.y, 14, const _Rgb(7, 30, 61), 0.95);
  }

  final mouth = _pointOnLine(222, 548, 802, 408, 0.19);
  _fillCircle(canvas, mouth.x, mouth.y, 18, const _Rgb(7, 30, 61), 0.9);
}

void _paintPeacockFeather(img.Image canvas) {
  _radialGlow(canvas, 783, 342, 170, const _Rgb(47, 111, 115), 0.18);
  _fillRotatedEllipse(
    canvas,
    786,
    346,
    58,
    122,
    0.62,
    const _Rgb(47, 111, 115),
    0.62,
  );
  _fillRotatedEllipse(
    canvas,
    785,
    345,
    38,
    88,
    0.62,
    const _Rgb(212, 175, 55),
    0.54,
  );
  _fillRotatedEllipse(
    canvas,
    785,
    345,
    24,
    56,
    0.62,
    const _Rgb(7, 30, 61),
    0.82,
  );
  _fillRotatedEllipse(
    canvas,
    785,
    345,
    12,
    28,
    0.62,
    const _Rgb(244, 231, 178),
    0.86,
  );
  _capsule(canvas, 720, 412, 794, 344, 7, const _Rgb(230, 199, 106), 0.72);
}

void _paintWordmark(img.Image canvas) {
  final text = img.Image(width: 220, height: 76, numChannels: 4);
  _clear(text);

  for (final offset in [
    (-3, 0),
    (3, 0),
    (0, -3),
    (0, 3),
    (-2, -2),
    (2, 2),
  ]) {
    img.drawString(
      text,
      'Gita',
      font: img.arial48,
      x: 47 + offset.$1,
      y: 12 + offset.$2,
      color: img.ColorRgba8(244, 231, 178, 70),
    );
  }

  img.drawString(
    text,
    'Gita',
    font: img.arial48,
    x: 47,
    y: 12,
    color: img.ColorRgba8(230, 199, 106, 255),
  );

  final scaled = img.copyResize(
    text,
    width: 392,
    height: 135,
    interpolation: img.Interpolation.average,
  );
  img.compositeImage(canvas, scaled, dstX: 316, dstY: 170);
}

void _paintVignette(img.Image canvas) {
  for (var y = 0; y < _size; y++) {
    for (var x = 0; x < _size; x++) {
      final dx = (x - _size / 2) / (_size / 2);
      final dy = (y - _size / 2) / (_size / 2);
      final edge = math.min(1.0, math.sqrt(dx * dx + dy * dy));
      final alpha = math.pow(edge, 2.4).toDouble() * 0.32;
      _blendPixel(canvas, x, y, const _Rgb(0, 8, 18), alpha);
    }
  }
}

void _radialGlow(
  img.Image canvas,
  double cx,
  double cy,
  double radius,
  _Rgb color,
  double opacity,
) {
  final x0 = math.max(0, (cx - radius).floor());
  final x1 = math.min(_size - 1, (cx + radius).ceil());
  final y0 = math.max(0, (cy - radius).floor());
  final y1 = math.min(_size - 1, (cy + radius).ceil());

  for (var y = y0; y <= y1; y++) {
    for (var x = x0; x <= x1; x++) {
      final d = math.sqrt(math.pow(x - cx, 2) + math.pow(y - cy, 2));
      if (d > radius) continue;
      final falloff = math.pow(1 - d / radius, 2.2).toDouble();
      _blendPixel(canvas, x, y, color, opacity * falloff);
    }
  }
}

void _fillRotatedEllipse(
  img.Image canvas,
  double cx,
  double cy,
  double rx,
  double ry,
  double angle,
  _Rgb color,
  double opacity,
) {
  final cosA = math.cos(angle);
  final sinA = math.sin(angle);
  final bounds = math.max(rx, ry).ceil();
  for (var y = (cy - bounds).floor(); y <= (cy + bounds).ceil(); y++) {
    if (y < 0 || y >= _size) continue;
    for (var x = (cx - bounds).floor(); x <= (cx + bounds).ceil(); x++) {
      if (x < 0 || x >= _size) continue;
      final dx = x - cx;
      final dy = y - cy;
      final px = dx * cosA + dy * sinA;
      final py = -dx * sinA + dy * cosA;
      final v = (px * px) / (rx * rx) + (py * py) / (ry * ry);
      if (v <= 1) {
        final edge = math.pow(1 - v, 0.8).toDouble();
        _blendPixel(canvas, x, y, color, opacity * edge);
      }
    }
  }
}

void _capsule(
  img.Image canvas,
  double x1,
  double y1,
  double x2,
  double y2,
  double radius,
  _Rgb color,
  double opacity,
) {
  final minX = math.max(0, (math.min(x1, x2) - radius - 2).floor());
  final maxX = math.min(_size - 1, (math.max(x1, x2) + radius + 2).ceil());
  final minY = math.max(0, (math.min(y1, y2) - radius - 2).floor());
  final maxY = math.min(_size - 1, (math.max(y1, y2) + radius + 2).ceil());

  for (var y = minY; y <= maxY; y++) {
    for (var x = minX; x <= maxX; x++) {
      final d = _distanceToSegment(x + 0.5, y + 0.5, x1, y1, x2, y2);
      if (d <= radius + 1) {
        final edge = (radius + 1 - d).clamp(0.0, 1.0);
        _blendPixel(canvas, x, y, color, opacity * edge);
      }
    }
  }
}

void _band(
  img.Image canvas,
  double cx,
  double cy,
  double angle,
  double width,
  double height,
  _Rgb color,
) {
  _fillRotatedEllipse(canvas, cx, cy, width, height, angle, color, 0.85);
}

void _fillCircle(
  img.Image canvas,
  double cx,
  double cy,
  double radius,
  _Rgb color,
  double opacity,
) {
  final minX = math.max(0, (cx - radius - 1).floor());
  final maxX = math.min(_size - 1, (cx + radius + 1).ceil());
  final minY = math.max(0, (cy - radius - 1).floor());
  final maxY = math.min(_size - 1, (cy + radius + 1).ceil());
  for (var y = minY; y <= maxY; y++) {
    for (var x = minX; x <= maxX; x++) {
      final d =
          math.sqrt(math.pow(x + 0.5 - cx, 2) + math.pow(y + 0.5 - cy, 2));
      if (d <= radius + 1) {
        final edge = (radius + 1 - d).clamp(0.0, 1.0);
        _blendPixel(canvas, x, y, color, opacity * edge);
      }
    }
  }
}

void _clear(img.Image image) {
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      image.setPixelRgba(x, y, 0, 0, 0, 0);
    }
  }
}

_Point _pointOnLine(double x1, double y1, double x2, double y2, double t) {
  return _Point(x1 + (x2 - x1) * t, y1 + (y2 - y1) * t);
}

double _distanceToSegment(
  double px,
  double py,
  double x1,
  double y1,
  double x2,
  double y2,
) {
  final vx = x2 - x1;
  final vy = y2 - y1;
  final wx = px - x1;
  final wy = py - y1;
  final lenSq = vx * vx + vy * vy;
  final t = lenSq == 0 ? 0.0 : ((wx * vx + wy * vy) / lenSq).clamp(0.0, 1.0);
  final cx = x1 + t * vx;
  final cy = y1 + t * vy;
  return math.sqrt(math.pow(px - cx, 2) + math.pow(py - cy, 2));
}

void _blendPixel(img.Image canvas, int x, int y, _Rgb color, double opacity) {
  if (opacity <= 0) return;
  final pixel = canvas.getPixel(x, y);
  final inv = 1 - opacity.clamp(0.0, 1.0);
  canvas.setPixelRgba(
    x,
    y,
    (pixel.r * inv + color.r * opacity).round(),
    (pixel.g * inv + color.g * opacity).round(),
    (pixel.b * inv + color.b * opacity).round(),
    255,
  );
}

_Rgb _lerpRgb(_Rgb a, _Rgb b, double t) {
  return _Rgb(
    (a.r + (b.r - a.r) * t).round(),
    (a.g + (b.g - a.g) * t).round(),
    (a.b + (b.b - a.b) * t).round(),
  );
}

class _Rgb {
  const _Rgb(this.r, this.g, this.b);

  final int r;
  final int g;
  final int b;
}

class _Point {
  const _Point(this.x, this.y);

  final double x;
  final double y;
}

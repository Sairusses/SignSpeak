import 'package:flutter/material.dart';

class DoubleOutlineBorder extends ShapeBorder {
  final double spacing;
  final double innerStrokeWidth;
  final double outerStrokeWidth;
  final Color innerColor;
  final Color outerColor;

  const DoubleOutlineBorder({
    this.spacing = 4.0,
    this.innerStrokeWidth = 2.0,
    this.outerStrokeWidth = 2.0,
    this.innerColor = Colors.black,
    this.outerColor = Colors.black,
  });

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(spacing + outerStrokeWidth);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()..addRect(rect.deflate(innerStrokeWidth / 2));
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return Path()..addRect(rect.inflate(spacing + outerStrokeWidth / 2));
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final innerRect = rect.deflate(innerStrokeWidth / 2);
    final outerRect = rect.inflate(spacing + outerStrokeWidth / 2);

    final innerPaint = Paint()
      ..color = innerColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = innerStrokeWidth;

    final outerPaint = Paint()
      ..color = outerColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = outerStrokeWidth;

    canvas.drawRect(innerRect, innerPaint);
    canvas.drawRect(outerRect, outerPaint);
  }

  @override
  ShapeBorder scale(double t) => this;
}

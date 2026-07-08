import 'dart:math';
import 'package:flutter/material.dart';
import 'package:watersortapp/models/bottle_style.dart';

/// Small live preview of a bottle style using the same glass rendering
/// language as the in-game BottleComponent (gradient glass body, rim
/// light, liquid layers with a gentle meniscus wave, specular shine) — so
/// the Settings picker shows what players will actually see in-game,
/// instead of a flat icon.
class BottleGlassPreview extends StatefulWidget {
  final BottleStyle style;
  final List<Color> liquidColors;
  final double width;
  final double height;

  const BottleGlassPreview({
    super.key,
    required this.style,
    this.liquidColors = const [Color(0xFFE53935), Color(0xFF1E88E5)],
    this.width = 44,
    this.height = 108,
  });

  @override
  State<BottleGlassPreview> createState() => _BottleGlassPreviewState();
}

class _BottleGlassPreviewState extends State<BottleGlassPreview>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          size: Size(widget.width, widget.height),
          painter: _BottleGlassPainter(
            style: widget.style,
            colors: widget.liquidColors,
            waveTime: _controller.value * 2 * pi,
          ),
        );
      },
    );
  }
}

class _BottleGlassPainter extends CustomPainter {
  final BottleStyle style;
  final List<Color> colors;
  final double waveTime;

  static const int maxCapacity = 4;

  /// Curve heights in [bottleStyleInfo] are authored against this design
  /// height (matches BottleComponent.bottleHeight) — scaled from there to
  /// whatever size this preview actually draws at.
  static const double _designHeight = 145;

  _BottleGlassPainter({
    required this.style,
    required this.colors,
    required this.waveTime,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double scale = h / _designHeight;

    final info = bottleStyleInfo[style]!;
    final Color glassTint = info.tint;
    final double bottomCurveHeight = info.bottomCurveHeight * scale;
    final double innerBottomCurveHeight = info.innerBottomCurveHeight * scale;
    final double neckWidthRatio = info.neckWidthRatio;
    final double bellyBulgeRatio = info.bellyBulgeRatio;

    final double bodyLeft = w * 0.09;
    final double bodyTop = h * 0.07;
    final double bodyRight = w - bodyLeft;
    final double bodyBottom = h - 1;
    final double bodyWidth = bodyRight - bodyLeft;
    final double centerX = w / 2;
    final double halfWidth = bodyWidth / 2;

    final Path tubeFillPath = buildVesselPath(
      centerX: centerX,
      halfWidth: halfWidth,
      top: bodyTop,
      bottom: bodyBottom,
      bottomCurveHeight: bottomCurveHeight,
      neckWidthRatio: neckWidthRatio,
      bellyBulgeRatio: bellyBulgeRatio,
    );

    final double innerLeft = bodyLeft + w * 0.05;
    final double innerTop = h * 0.12;
    final double innerRight = bodyRight - w * 0.05;
    final double innerBottom = bodyBottom - h * 0.012;
    final double innerWidth = innerRight - innerLeft;
    final double innerHeight = innerBottom - innerTop;

    final Path innerLiquidPath = buildVesselPath(
      centerX: centerX,
      halfWidth: innerWidth / 2,
      top: innerTop,
      bottom: innerBottom,
      bottomCurveHeight: innerBottomCurveHeight,
      neckWidthRatio: neckWidthRatio,
      bellyBulgeRatio: bellyBulgeRatio,
    );

    // Glass body fill.
    final glassFillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          glassTint.withOpacity(0.20),
          glassTint.withOpacity(0.06),
          glassTint.withOpacity(0.12),
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(tubeFillPath, glassFillPaint);

    // Rim light along the left edge — same directional-light trick used
    // on the in-game bottle so it reads as curved glass, not a flat shape.
    canvas.save();
    canvas.clipPath(tubeFillPath);
    final rimLightPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [Colors.white.withOpacity(0.22), Colors.white.withOpacity(0.0)],
        stops: const [0.0, 0.55],
      ).createShader(Rect.fromLTWH(bodyLeft, bodyTop, bodyWidth, h));
    canvas.drawRect(
      Rect.fromLTWH(bodyLeft, bodyTop, bodyWidth * 0.55, h),
      rimLightPaint,
    );
    canvas.restore();

    // Liquid layers with a live meniscus wave on the top layer.
    canvas.save();
    canvas.clipPath(innerLiquidPath);

    final double liquidBottomY = innerBottom + 1;
    final double layerHeight = innerHeight / maxCapacity;
    final int filled = colors.length.clamp(0, maxCapacity);

    for (int i = 0; i < filled; i++) {
      final double bottomY = liquidBottomY - i * layerHeight;
      final double topY = bottomY - layerHeight;
      final bool isTopLayer = i == filled - 1;

      final colorPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [colors[i].withOpacity(0.85), colors[i]],
        ).createShader(
          Rect.fromLTWH(innerLeft, topY, innerWidth, max(layerHeight, 1.0)),
        );

      final path = Path();
      if (isTopLayer) {
        final double wavePower = 2.4 * scale;
        final double wave1 = sin(waveTime) * wavePower;
        final double wave2 = sin(waveTime + 1.8) * wavePower;
        final double meniscus = 2.4 * scale;

        path.moveTo(innerLeft, topY + wave1 - meniscus);
        path.quadraticBezierTo(
          innerLeft + innerWidth * 0.5,
          topY - wavePower,
          innerRight,
          topY + wave2 - meniscus,
        );
        path.lineTo(innerRight, bottomY + 2);
        path.lineTo(innerLeft, bottomY + 2);
        path.close();
      } else {
        path.addRect(
          Rect.fromLTWH(innerLeft, topY, innerWidth, layerHeight + 2),
        );
      }

      canvas.drawPath(path, colorPaint);

      if (!isTopLayer) {
        final interfacePaint = Paint()
          ..color = Colors.white.withOpacity(0.18)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;
        canvas.drawLine(
          Offset(innerLeft, topY),
          Offset(innerRight, topY),
          interfacePaint,
        );
      }
    }
    canvas.restore();

    // Glass specular streak — a soft angled highlight over the whole tube,
    // drawn on top of the liquid so the glass reads as being in front.
    canvas.save();
    canvas.clipPath(tubeFillPath);
    final specularPaint = Paint()
      ..color = Colors.white.withOpacity(0.16)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3 * scale);
    canvas.save();
    canvas.translate(w * 0.32, h * 0.45);
    canvas.rotate(-0.16);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: 4 * scale, height: h * 0.55),
        Radius.circular(4 * scale),
      ),
      specularPaint,
    );
    canvas.restore();
    canvas.restore();

    // Glass border.
    final glassBorderPaint = Paint()
      ..color = Colors.white.withOpacity(0.60)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 * scale
      ..strokeCap = StrokeCap.round;
    final borderPath = buildVesselPath(
      centerX: centerX,
      halfWidth: halfWidth,
      top: bodyTop,
      bottom: bodyBottom,
      bottomCurveHeight: bottomCurveHeight,
      neckWidthRatio: neckWidthRatio,
      bellyBulgeRatio: bellyBulgeRatio,
      topInset: 2,
      closeTop: false,
    );
    canvas.drawPath(borderPath, glassBorderPaint);

    // Mouth (neck opening), matching the in-game bottle's ellipse rim.
    final double neckHalfWidth = halfWidth * neckWidthRatio;
    final double mouthWidth = neckHalfWidth * 2;
    final mouthOuterRect = Rect.fromLTWH(
        centerX - neckHalfWidth, bodyTop - 4 * scale, mouthWidth, 9 * scale);
    final mouthInnerRect = Rect.fromLTWH(centerX - neckHalfWidth + 3.5 * scale,
        bodyTop - 2 * scale, mouthWidth - 7 * scale, 5 * scale);

    canvas.drawOval(mouthInnerRect, Paint()..color = Colors.black.withOpacity(0.28));
    canvas.drawOval(
      mouthOuterRect,
      Paint()
        ..color = Colors.white.withOpacity(0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3 * scale,
    );
  }

  @override
  bool shouldRepaint(covariant _BottleGlassPainter oldDelegate) =>
      oldDelegate.waveTime != waveTime ||
      oldDelegate.style != style ||
      oldDelegate.colors != colors;
}

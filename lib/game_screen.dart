import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:confetti/confetti.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:watersortapp/controllers/achievement_controller.dart';
import 'package:watersortapp/controllers/coin_controller.dart';
import 'package:watersortapp/controllers/level_controller.dart';
import 'package:watersortapp/controllers/settings_controller.dart';
import 'package:watersortapp/controllers/shop_controller.dart';
import 'package:watersortapp/data/worlds.dart';
import 'package:watersortapp/models/bottle_style.dart';
import 'package:watersortapp/shop_screen.dart';
import 'package:watersortapp/theme/app_theme.dart';
import 'package:watersortapp/widgets/animated_water_background.dart';

// ---------------------------------------------------------------------------
// Sparkle particle for the bottle-sorted celebration
// ---------------------------------------------------------------------------
class SparkleParticle extends PositionComponent {
  final Color color;
  final double sparkleAngle;
  final double speed;
  final bool isDroplet;
  double _life = 1.0;
  final double _size;

  SparkleParticle({
    required this.color,
    required this.sparkleAngle,
    required this.speed,
    required Vector2 position,
    double size = 5.0,
    this.isDroplet = false,
  })  : _size = size,
        super(position: position);

  @override
  void update(double dt) {
    super.update(dt);
    _life -= dt * 1.8;
    position.x += cos(sparkleAngle) * speed * dt;
    position.y += sin(sparkleAngle) * speed * dt + 60 * dt; // gravity
    if (_life <= 0) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    if (_life <= 0) return;
    final paint = Paint()
      ..color = color.withOpacity(_life.clamp(0.0, 1.0))
      ..style = PaintingStyle.fill;

    final s = _size * _life;

    if (isDroplet) {
      canvas.drawCircle(Offset.zero, s * 0.6, paint);
      return;
    }

    final path = Path()
      ..moveTo(0, -s)
      ..lineTo(s * 0.35, -s * 0.35)
      ..lineTo(s, 0)
      ..lineTo(s * 0.35, s * 0.35)
      ..lineTo(0, s)
      ..lineTo(-s * 0.35, s * 0.35)
      ..lineTo(-s, 0)
      ..lineTo(-s * 0.35, -s * 0.35)
      ..close();
    canvas.drawPath(path, paint);
  }
}

// ---------------------------------------------------------------------------
// Celebration burst: spawns sparkles around a bottle mouth
// ---------------------------------------------------------------------------
class CelebrationBurst extends PositionComponent {
  final Color bottleColor;
  final double intensity;
  final _rng = Random();

  CelebrationBurst({
    required this.bottleColor,
    required Vector2 position,
    this.intensity = 1.0,
  }) : super(position: position);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _spawnParticles();
  }

  void _spawnParticles() {
    final int count = (22 * intensity).round();
    final List<Color> palette = [
      bottleColor,
      Colors.white,
      Colors.yellow.shade300,
      Colors.amber,
      bottleColor.withOpacity(0.7),
    ];

    for (int i = 0; i < count; i++) {
      final angle = (2 * pi / count) * i + _rng.nextDouble() * 0.4;
      final speed = (60.0 + _rng.nextDouble() * 90.0) * intensity;
      final color = palette[_rng.nextInt(palette.length)];
      final size = (3.5 + _rng.nextDouble() * 4.0) * (1 + (intensity - 1) * 0.35);

      add(SparkleParticle(
        color: color,
        sparkleAngle: angle,
        speed: speed,
        position: Vector2.zero(),
        size: size,
        isDroplet: _rng.nextDouble() < 0.35,
      ));
    }

    Future.delayed(const Duration(milliseconds: 900), () {
      if (isMounted) removeFromParent();
    });
  }
}

// ---------------------------------------------------------------------------
// CelebrationShockwave: expanding ring pulse from the completed bottle
// ---------------------------------------------------------------------------
class CelebrationShockwave extends PositionComponent {
  final Color color;
  final double intensity;
  double _time = 0;
  static const double _duration = 0.5;

  CelebrationShockwave({
    required Vector2 position,
    required this.color,
    this.intensity = 1.0,
  }) : super(position: position);

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    if (_time >= _duration) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final double t = (_time / _duration).clamp(0.0, 1.0);
    final double maxRadius = 34 * intensity;
    final double radius = maxRadius * Curves.easeOut.transform(t);
    final double opacity = (1 - t) * 0.55;

    final ringPaint = Paint()
      ..color = color.withOpacity(opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0 * (1 - t * 0.6);
    canvas.drawCircle(Offset.zero, radius, ringPaint);

    final innerGlowPaint = Paint()
      ..color = Colors.white.withOpacity(opacity * 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(Offset.zero, radius * 0.7, innerGlowPaint);
  }
}

// ---------------------------------------------------------------------------
// CelebrationBadge: small checkmark badge that pops above a completed bottle
// ---------------------------------------------------------------------------
class CelebrationBadge extends PositionComponent {
  double _time = 0;
  static const double _duration = 0.9;

  CelebrationBadge({required Vector2 position}) : super(position: position);

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    if (_time >= _duration) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final double t = (_time / _duration).clamp(0.0, 1.0);
    final double scale =
        t < 0.4 ? Curves.easeOutBack.transform(t / 0.4) : 1.0;
    final double opacity =
        t < 0.65 ? 1.0 : (1 - (t - 0.65) / 0.35).clamp(0.0, 1.0);
    final double floatY = -16 * t;

    canvas.save();
    canvas.translate(0, floatY);
    canvas.scale(scale);

    final bgPaint = Paint()..color = Colors.amber.shade400.withOpacity(opacity);
    canvas.drawCircle(Offset.zero, 13, bgPaint);

    final ringPaint = Paint()
      ..color = Colors.white.withOpacity(opacity * 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    canvas.drawCircle(Offset.zero, 13, ringPaint);

    final checkPaint = Paint()
      ..color = Colors.white.withOpacity(opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final checkPath = Path()
      ..moveTo(-5, 0)
      ..lineTo(-1.5, 4.5)
      ..lineTo(6, -5);
    canvas.drawPath(checkPath, checkPaint);

    canvas.restore();
  }
}

// ---------------------------------------------------------------------------
// Hint highlight overlay component
// ---------------------------------------------------------------------------
class HintHighlightComponent extends PositionComponent {
  final Color glowColor;
  double _time = 0;

  HintHighlightComponent({
    required Vector2 position,
    required Vector2 size,
    required this.glowColor,
  }) : super(position: position, size: size);

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt * 4;
  }

  @override
  void render(Canvas canvas) {
    final alpha = (sin(_time) * 0.5 + 0.5) * 0.6 + 0.2;
    final paint = Paint()
      ..color = glowColor.withOpacity(alpha.clamp(0.0, 1.0))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.x, size.y),
        const Radius.circular(22),
      ),
      paint,
    );
  }
}

// ---------------------------------------------------------------------------
// BottleComponent
// ---------------------------------------------------------------------------
class BottleComponent extends PositionComponent with TapCallbacks {
  final int index;
  List<Color> colors;
  bool isSelected = false;
  bool isHinted = false;
  bool isHintTarget = false;
  final Function(int) onTap;
  final BottleStyle style;
  late Vector2 initialPosition;

  double waveTime = 0;
  bool isPouringWave = false;

  /// Brief splash "kick" added to the surface wave right after a drop
  /// lands, decaying back to the idle wave — gives the liquid a moment
  /// of real impact instead of just continuously sloshing.
  double _impactKick = 0;

  bool _isCelebrating = false;
  double _celebrateTime = 0;

  // Continuous fill-level animation: instead of the liquid level jumping
  // straight to its new height the instant a color unit transfers, it
  // rises/recedes smoothly like a real stream filling or draining a glass.
  late double _displayedFillLevel;
  late List<Color> _renderColors;
  static const double _fillAnimSpeed = 3.3; // capacity-units per second

  static const double bottleWidth = 58;
  static const double bottleHeight = 145;
  static const int maxCapacity = 4;
  static const double borderRadius = 22;

  static const double _innerTop = 15;
  static const double _innerBottom = bottleHeight - 2;

  BottleComponent({
    required this.index,
    required this.colors,
    required this.onTap,
    required Vector2 position,
    this.style = BottleStyle.classicTube,
  }) : super(
          position: position,
          size: Vector2(bottleWidth, bottleHeight),
          anchor: Anchor.topLeft,
        ) {
    initialPosition = position.clone();
    _displayedFillLevel = colors.length.toDouble();
    _renderColors = List<Color>.from(colors);
  }

  /// Instantly syncs the displayed liquid to the underlying data —
  /// used for undo/restart where the change should be immediate, not
  /// animated like a normal pour.
  void snapToData() {
    _renderColors = List<Color>.from(colors);
    _displayedFillLevel = colors.length.toDouble();
  }

  Vector2 get centerPosition => position + size / 2;
  Vector2 get mouthCenter => position + Vector2(width / 2, 0);

  /// World position of the mouth opening accounting for the bottle's
  /// current tilt. [position] is the anchor (top-left) that stays fixed
  /// under [RotateEffect] — the mouth itself is offset from that anchor
  /// by half the bottle width, so it swings out to a different world
  /// point as the bottle rotates during a pour. Using the untilted
  /// [mouthCenter] here would place the pour stream's start point back
  /// near the anchor, mostly hidden inside the tilted glass body instead
  /// of at the visible spout.
  Vector2 get tiltedMouthWorld =>
      position + Vector2(width / 2 * cos(angle), width / 2 * sin(angle));

  /// Local-space Y of the current liquid surface, used so splash effects
  /// land exactly on top of the liquid rather than always at the mouth.
  double get liquidSurfaceLocalY {
    const double innerHeight = _innerBottom - _innerTop;
    const double layerHeight = innerHeight / maxCapacity;
    const double liquidBottomY = _innerBottom + 1;
    return liquidBottomY - colors.length * layerHeight;
  }

  Vector2 get liquidSurfaceWorld =>
      position + Vector2(width / 2, liquidSurfaceLocalY);

  void triggerImpact() {
    _impactKick = 1.0;
  }

  void celebrate() {
    if (_isCelebrating) return;
    _isCelebrating = true;
    _celebrateTime = 0;

    add(
      MoveEffect.by(
        Vector2(0, -18),
        EffectController(duration: 0.18, curve: Curves.easeOut),
        onComplete: () {
          add(
            MoveEffect.by(
              Vector2(0, 18),
              EffectController(duration: 0.14, curve: Curves.easeIn),
              onComplete: () {
                add(
                  MoveEffect.by(
                    Vector2(0, -10),
                    EffectController(duration: 0.12, curve: Curves.easeOut),
                    onComplete: () {
                      add(
                        MoveEffect.by(
                          Vector2(0, 10),
                          EffectController(
                              duration: 0.10, curve: Curves.easeIn),
                          onComplete: () {
                            _isCelebrating = false;
                          },
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    debugMode = false;
  }

  @override
  void update(double dt) {
    super.update(dt);
    waveTime += dt * 4.0;
    if (_isCelebrating) _celebrateTime += dt;
    if (_impactKick > 0) {
      _impactKick = (_impactKick - dt * 3.2).clamp(0.0, 1.0);
    }

    // Filling: sync new colors in immediately so their hue is known,
    // then let the fill level animate up to reveal them.
    if (colors.length > _renderColors.length) {
      _renderColors = List<Color>.from(colors);
    }

    final double target = colors.length.toDouble();
    if (_displayedFillLevel < target) {
      _displayedFillLevel =
          (_displayedFillLevel + dt * _fillAnimSpeed).clamp(0.0, target);
    } else if (_displayedFillLevel > target) {
      _displayedFillLevel =
          (_displayedFillLevel - dt * _fillAnimSpeed).clamp(target, maxCapacity.toDouble());
      // Draining: only trim the remembered top color once the level has
      // visually receded down to the new (shorter) data length.
      if (_displayedFillLevel <= target && _renderColors.length > colors.length) {
        _renderColors = List<Color>.from(colors);
      }
    }
  }

  @override
  bool containsPoint(Vector2 point) {
    final localPoint = absoluteToLocal(point);
    final rect = Rect.fromLTWH(0, 0, width, height);
    return rect.contains(localPoint.toOffset());
  }

  @override
  void onTapDown(TapDownEvent event) {
    onTap(index);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Ambient ground shadow so the bottle feels grounded rather than floating
    final groundShadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.32)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7);
    canvas.drawOval(
      Rect.fromLTWH(width * 0.14, height - 5, width * 0.72, 11),
      groundShadowPaint,
    );

    // Celebration glow overlay
    if (_isCelebrating) {
      final glowAlpha = (sin(_celebrateTime * 12) * 0.5 + 0.5) * 0.35;
      final glowPaint = Paint()
        ..color = (colors.isNotEmpty ? colors.last : Colors.white)
            .withOpacity(glowAlpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, width, height),
          const Radius.circular(22),
        ),
        glowPaint,
      );
    }

    // Hint source glow (green)
    if (isHinted) {
      final hintPaint = Paint()
        ..color = Colors.greenAccent.withOpacity(0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, width, height),
          const Radius.circular(22),
        ),
        hintPaint,
      );
    }

    // Hint target glow (orange)
    if (isHintTarget) {
      final hintPaint = Paint()
        ..color = Colors.orangeAccent.withOpacity(0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, width, height),
          const Radius.circular(22),
        ),
        hintPaint,
      );
    }

    final BottleStyleInfo styleInfo = bottleStyleInfo[style]!;
    final Color glassTint = styleInfo.tint;

    final glassFillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          glassTint.withOpacity(0.18),
          glassTint.withOpacity(0.05),
          glassTint.withOpacity(0.11),
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, width, height))
      ..style = PaintingStyle.fill;

    Color borderColor;
    double borderWidth;
    if (_isCelebrating) {
      borderColor = Colors.amber.shade300;
      borderWidth = 2.8;
    } else if (isHinted) {
      borderColor = Colors.greenAccent.shade400;
      borderWidth = 2.5;
    } else if (isHintTarget) {
      borderColor = Colors.orangeAccent;
      borderWidth = 2.5;
    } else if (isSelected) {
      borderColor = Colors.blue.shade400;
      borderWidth = 2.8;
    } else {
      borderColor = Colors.white.withOpacity(0.48);
      borderWidth = 1.9;
    }

    final glassBorderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..strokeCap = StrokeCap.round;

    final sideHighlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.13)
      ..style = PaintingStyle.fill;

    final sideShadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.10)
      ..style = PaintingStyle.fill;

    final double bodyLeft = 4;
    final double bodyTop = 8;
    final double bodyRight = width - 4;
    final double bodyBottom = height;
    final double bodyWidth = bodyRight - bodyLeft;
    final double bottomCurveHeight = styleInfo.bottomCurveHeight;
    final double centerX = width / 2;
    final double halfWidth = bodyWidth / 2;
    final double neckWidthRatio = styleInfo.neckWidthRatio;
    final double bellyBulgeRatio = styleInfo.bellyBulgeRatio;

    final tubeFillPath = buildVesselPath(
      centerX: centerX,
      halfWidth: halfWidth,
      top: bodyTop,
      bottom: bodyBottom,
      bottomCurveHeight: bottomCurveHeight,
      neckWidthRatio: neckWidthRatio,
      bellyBulgeRatio: bellyBulgeRatio,
    );

    final double innerLeft = 7;
    final double innerTop = 15;
    final double innerRight = width - 7;
    final double innerBottom = height - 2;
    final double innerBottomCurveHeight = styleInfo.innerBottomCurveHeight;
    final double innerWidth = innerRight - innerLeft;
    final double innerHeight = innerBottom - innerTop;

    final innerLiquidPath = buildVesselPath(
      centerX: centerX,
      halfWidth: innerWidth / 2,
      top: innerTop,
      bottom: innerBottom,
      bottomCurveHeight: innerBottomCurveHeight,
      neckWidthRatio: neckWidthRatio,
      bellyBulgeRatio: bellyBulgeRatio,
    );

    canvas.drawPath(tubeFillPath, glassFillPaint);

    // Broad soft rim-light down the left side of the tube, like a
    // directional light source catching the curve of real glass.
    canvas.save();
    canvas.clipPath(tubeFillPath);
    final rimLightPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.white.withOpacity(0.16),
          Colors.white.withOpacity(0.0),
        ],
        stops: const [0.0, 0.55],
      ).createShader(Rect.fromLTWH(bodyLeft, bodyTop, bodyWidth, height));
    canvas.drawRect(
      Rect.fromLTWH(bodyLeft, bodyTop, bodyWidth * 0.55, height),
      rimLightPaint,
    );
    canvas.restore();

    // Inner wall-thickness contour, inset from the outer silhouette, so
    // the glass reads as having real thickness along its whole body.
    final wallContourPaint = Paint()
      ..color = Colors.white.withOpacity(0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawPath(
      buildVesselPath(
        centerX: centerX,
        halfWidth: halfWidth - 3.5,
        top: bodyTop,
        bottom: bodyBottom - 3,
        bottomCurveHeight: bottomCurveHeight,
        neckWidthRatio: neckWidthRatio,
        bellyBulgeRatio: bellyBulgeRatio,
        topInset: 3,
        closeTop: false,
      ),
      wallContourPaint,
    );

    canvas.save();
    canvas.clipPath(innerLiquidPath);

    final double liquidBottomY = innerBottom + 1;
    final double layerHeight = innerHeight / maxCapacity;

    // Liquid is drawn from the animated _displayedFillLevel rather than
    // the raw data length, so a rising/draining layer grows or shrinks
    // smoothly instead of popping to full height in one frame.
    final int fullLayers =
        _displayedFillLevel.floor().clamp(0, _renderColors.length);
    final double partialFraction = (_displayedFillLevel - fullLayers).clamp(0.0, 1.0);
    final bool hasPartial =
        partialFraction > 0.001 && fullLayers < _renderColors.length;
    final int topIndex = hasPartial ? fullLayers : fullLayers - 1;

    for (int i = 0; i < _renderColors.length; i++) {
      double layerFraction;
      if (i < fullLayers) {
        layerFraction = 1.0;
      } else if (i == fullLayers && hasPartial) {
        layerFraction = partialFraction;
      } else {
        continue;
      }

      final double effectiveHeight = layerHeight * layerFraction;
      final double bottomY = liquidBottomY - i * layerHeight;
      final double topY = bottomY - effectiveHeight;

      final colorPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _renderColors[i].withOpacity(0.84),
            _renderColors[i],
          ],
        ).createShader(
          Rect.fromLTWH(innerLeft, topY, innerWidth, max(effectiveHeight, 1.0)),
        );

      final bool isTopLayer = i == topIndex;
      final path = Path();

      if (isTopLayer) {
        final double wavePower =
            (isPouringWave ? 6.0 : 2.0) + _impactKick * 7.0;
        final double wave1 = sin(waveTime) * wavePower +
            sin(waveTime * 2.3) * wavePower * 0.2;
        final double wave2 = sin(waveTime + 1.8) * wavePower +
            sin(waveTime * 2.1 + 0.6) * wavePower * 0.2;
        // Meniscus: water always climbs slightly at the glass walls,
        // even at rest, instead of presenting a perfectly flat surface.
        const double meniscus = 3.0;

        path.moveTo(innerLeft, topY + wave1 - meniscus);
        path.quadraticBezierTo(
          innerLeft + innerWidth * 0.16,
          topY + wave1 - meniscus * 0.3,
          innerLeft + innerWidth * 0.16,
          topY + wave1 * 0.6,
        );
        path.quadraticBezierTo(
          innerLeft + innerWidth * 0.50,
          topY - wavePower,
          innerRight - innerWidth * 0.16,
          topY + wave2 * 0.6,
        );
        path.quadraticBezierTo(
          innerRight - innerWidth * 0.16,
          topY + wave2 - meniscus * 0.3,
          innerRight,
          topY + wave2 - meniscus,
        );
        path.lineTo(innerRight, bottomY + 2);
        path.lineTo(innerLeft, bottomY + 2);
        path.close();
      } else {
        path.addRect(
          Rect.fromLTWH(innerLeft, topY, innerWidth, effectiveHeight + 2),
        );
      }

      canvas.drawPath(path, colorPaint);

      // Subtle bright interface line where this layer meets the one above,
      // so stacked colors read as distinct liquid bodies, not flat paint.
      if (!isTopLayer) {
        final interfacePaint = Paint()
          ..color = Colors.white.withOpacity(0.16)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;
        canvas.drawLine(
          Offset(innerLeft, topY),
          Offset(innerRight, topY),
          interfacePaint,
        );
      }
    }

    // Slow-drifting caustic sheen inside the liquid for a subtle shimmer.
    if (_renderColors.isNotEmpty) {
      final double causticX =
          innerLeft + innerWidth * 0.5 + sin(waveTime * 0.28) * innerWidth * 0.32;
      final causticPaint = Paint()
        ..color = Colors.white.withOpacity(0.05)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9);
      canvas.save();
      canvas.translate(causticX, innerTop + innerHeight * 0.5);
      canvas.rotate(0.3);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: 9,
            height: innerHeight * 1.2,
          ),
          const Radius.circular(8),
        ),
        causticPaint,
      );
      canvas.restore();
    }

    if (_renderColors.isNotEmpty) {
      final bottomDepthPaint = Paint()
        ..color = _renderColors.first.withOpacity(0.24)
        ..style = PaintingStyle.fill;

      canvas.drawOval(
        Rect.fromLTWH(innerLeft + 3, height - 29, innerWidth - 6, 23),
        bottomDepthPaint,
      );
    }

    canvas.restore();

    // Clipped to the vessel silhouette so these decorative bars stay
    // inside the glass even on narrow-necked styles like the round flask.
    canvas.save();
    canvas.clipPath(tubeFillPath);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(11, 27, 4, height - 52),
        const Radius.circular(4),
      ),
      sideHighlightPaint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(width - 10, 27, 2.5, height - 52),
        const Radius.circular(4),
      ),
      sideShadowPaint,
    );
    canvas.restore();

    // Glass specular streaks — soft angled light reflections over the
    // whole tube (glass in front of the liquid), so it reads as glass
    // rather than a flat painted outline.
    canvas.save();
    canvas.clipPath(tubeFillPath);

    final specular1Paint = Paint()
      ..color = Colors.white.withOpacity(0.11)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.save();
    canvas.translate(width * 0.30, height * 0.42);
    canvas.rotate(-0.16);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: 7, height: height * 0.6),
        const Radius.circular(6),
      ),
      specular1Paint,
    );
    canvas.restore();

    final specular2Paint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.save();
    canvas.translate(width * 0.70, height * 0.5);
    canvas.rotate(0.12);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: 5, height: height * 0.42),
        const Radius.circular(5),
      ),
      specular2Paint,
    );
    canvas.restore();

    canvas.restore();

    final borderPath = buildVesselPath(
      centerX: centerX,
      halfWidth: halfWidth,
      top: bodyTop,
      bottom: bodyBottom,
      bottomCurveHeight: bottomCurveHeight,
      neckWidthRatio: neckWidthRatio,
      bellyBulgeRatio: bellyBulgeRatio,
      topInset: 3,
      closeTop: false,
    );

    canvas.drawPath(borderPath, glassBorderPaint);

    final double neckHalfWidth = halfWidth * neckWidthRatio;
    final double mouthWidth = neckHalfWidth * 2;
    final mouthOuterRect =
        Rect.fromLTWH(centerX - neckHalfWidth, bodyTop - 6, mouthWidth, 13);
    final mouthInnerRect = Rect.fromLTWH(
        centerX - neckHalfWidth + 5, bodyTop - 3, mouthWidth - 10, 7);

    final mouthInnerPaint = Paint()
      ..color = Colors.black.withOpacity(0.30)
      ..style = PaintingStyle.fill;

    Color mouthBorderColor;
    if (_isCelebrating) {
      mouthBorderColor = Colors.amber.shade300;
    } else if (isHinted) {
      mouthBorderColor = Colors.greenAccent.shade400;
    } else if (isHintTarget) {
      mouthBorderColor = Colors.orangeAccent;
    } else if (isSelected) {
      mouthBorderColor = Colors.blue.shade400;
    } else {
      mouthBorderColor = Colors.white.withOpacity(0.50);
    }

    final mouthBorderPaint = Paint()
      ..color = mouthBorderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = (_isCelebrating || isHinted || isHintTarget || isSelected)
          ? 2.5
          : 1.7;

    final mouthShinePaint = Paint()
      ..color = Colors.white.withOpacity(0.30)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    canvas.drawOval(mouthInnerRect, mouthInnerPaint);
    canvas.drawOval(mouthOuterRect, mouthBorderPaint);

    // Inner rim stroke to suggest the glass has real thickness at the neck.
    final mouthInnerRimPaint = Paint()
      ..color = Colors.white.withOpacity(0.20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawOval(mouthInnerRect.deflate(1.6), mouthInnerRimPaint);

    canvas.drawArc(
      Rect.fromLTWH(
          centerX - neckHalfWidth + 4, bodyTop - 5, mouthWidth - 8, 11),
      pi * 1.03,
      pi * 0.42,
      false,
      mouthShinePaint,
    );

    final bottomShinePaint = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromLTWH(9, height - 32, width - 18, 28),
      0.18,
      pi - 0.36,
      false,
      bottomShinePaint,
    );
  }
}

// ---------------------------------------------------------------------------
// WaterStreamComponent
// ---------------------------------------------------------------------------
class WaterStreamComponent extends PositionComponent {
  final Color color;
  final Vector2 target;
  double time = 0;

  static const List<double> _bubbleOffsets = [0.0, 0.25, 0.5, 0.75];

  WaterStreamComponent({
    required this.color,
    required Vector2 position,
    required this.target,
  }) : super(position: position);

  @override
  void update(double dt) {
    super.update(dt);
    time += dt * 8;
  }

  Offset _quadPoint(Offset p0, Offset p1, Offset p2, double t) {
    final double mt = 1 - t;
    return Offset(
      mt * mt * p0.dx + 2 * mt * t * p1.dx + t * t * p2.dx,
      mt * mt * p0.dy + 2 * mt * t * p1.dy + t * t * p2.dy,
    );
  }

  @override
  void render(Canvas canvas) {
    final diff = target - position;
    final waveOffset = sin(time) * 3;

    final Offset p0 = Offset.zero;
    final Offset control = Offset(diff.x * 0.45 + waveOffset, diff.y * -0.08);
    final Offset p2 = Offset(diff.x, diff.y);

    // Sample the pour curve so we can build a tapering ribbon instead of
    // a single thin wire-like stroke — reads much closer to real water.
    const int steps = 10;
    final List<Offset> samples = [
      for (int i = 0; i <= steps; i++) _quadPoint(p0, control, p2, i / steps),
    ];

    final List<Offset> left = [];
    final List<Offset> right = [];
    for (int i = 0; i < samples.length; i++) {
      final double t = i / (samples.length - 1);
      final double halfWidth = 4.6 - t * 2.0;
      final Offset dir = i < samples.length - 1
          ? samples[i + 1] - samples[i]
          : samples[i] - samples[i - 1];
      final double len = dir.distance == 0 ? 1 : dir.distance;
      final Offset normal = Offset(-dir.dy / len, dir.dx / len);
      left.add(samples[i] + normal * halfWidth);
      right.add(samples[i] - normal * halfWidth);
    }

    final ribbonPath = Path()..moveTo(left.first.dx, left.first.dy);
    for (final p in left.skip(1)) {
      ribbonPath.lineTo(p.dx, p.dy);
    }
    for (final p in right.reversed) {
      ribbonPath.lineTo(p.dx, p.dy);
    }
    ribbonPath.close();

    final ribbonPaint = Paint()
      ..shader = LinearGradient(
        colors: [color.withOpacity(0.55), color.withOpacity(0.92)],
      ).createShader(Rect.fromPoints(p0, p2));
    canvas.drawPath(ribbonPath, ribbonPaint);

    // Glossy highlight running down the center of the stream.
    final glossPath = Path()..moveTo(0, 0);
    glossPath.quadraticBezierTo(control.dx, control.dy, p2.dx, p2.dy);
    final glossPaint = Paint()
      ..color = Colors.white.withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(glossPath, glossPaint);

    // Small bubbles riding the stream toward the target bottle.
    for (final offset in _bubbleOffsets) {
      final double t = (time * 0.12 + offset) % 1.0;
      final Offset p = _quadPoint(p0, control, p2, t);
      final double fade = sin(t * pi).clamp(0.0, 1.0);
      final bubblePaint = Paint()..color = Colors.white.withOpacity(0.55 * fade);
      canvas.drawCircle(p, 1.0 + fade * 1.3, bubblePaint);
    }
  }
}

// ---------------------------------------------------------------------------
// SplashRipple — brief expanding ring where poured liquid lands
// ---------------------------------------------------------------------------
class SplashRipple extends PositionComponent {
  final Color color;
  double _time = 0;

  SplashRipple({required Vector2 position, required this.color})
      : super(position: position);

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt * 2.6;
    if (_time >= 1) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final double t = _time.clamp(0.0, 1.0);
    final double radiusX = 4 + t * 13;
    final double radiusY = radiusX * 0.4;
    final paint = Paint()
      ..color = color.withOpacity((1 - t) * 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: radiusX * 2, height: radiusY * 2),
      paint,
    );
  }
}

// ---------------------------------------------------------------------------
// SplashDroplets — a few tiny droplets that pop up and fall back at the
// moment poured liquid hits the surface, like a real splash.
// ---------------------------------------------------------------------------
class SplashDroplets extends PositionComponent {
  final Color color;
  double _time = 0;
  final _rng = Random();
  late final List<Offset> _launchVelocity;

  SplashDroplets({required Vector2 position, required this.color})
      : super(position: position) {
    _launchVelocity = List.generate(4, (i) {
      final double angle = -pi / 2 + (_rng.nextDouble() - 0.5) * 1.6;
      final double speed = 30 + _rng.nextDouble() * 30;
      return Offset(cos(angle) * speed, sin(angle) * speed);
    });
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    if (_time >= 0.45) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = color.withOpacity((1 - _time / 0.45) * 0.85);
    for (final v in _launchVelocity) {
      final double x = v.dx * _time;
      final double y = v.dy * _time + 220 * _time * _time; // gravity fall
      canvas.drawCircle(Offset(x, y), 1.6, paint);
    }
  }
}

// ---------------------------------------------------------------------------
// WaterSortGame
// ---------------------------------------------------------------------------

/// Snapshot of game state for undo
class _GameSnapshot {
  final List<List<Color>> bottlesData;
  _GameSnapshot(List<List<Color>> data)
      : bottlesData = data.map((b) => List<Color>.from(b)).toList();
}

class WaterSortGame extends FlameGame {
  final int level;
  final Function(int) onMoveUpdate;
  final VoidCallback onWin;
  final VoidCallback? onHintUsed;
  final VoidCallback? onNoMoves;

  late List<List<Color>> bottlesData;
  List<BottleComponent> bottleComponents = [];

  int? selectedIndex;
  bool _isAnimating = false;

  // Undo stack
  final List<_GameSnapshot> _undoStack = [];

  // Hint state
  int? _hintFrom;
  int? _hintTo;

  final AudioPlayer _audioPlayer = AudioPlayer();

  // Transparent so the AnimatedWaterBackground behind the GameWidget shows
  // through instead of Flame's default opaque black canvas.
  @override
  Color backgroundColor() => const Color(0x00000000);

  WaterSortGame({
    required this.level,
    required this.onMoveUpdate,
    required this.onWin,
    this.onHintUsed,
    this.onNoMoves,
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await _audioPlayer.setSource(AssetSource('audio/water_sound.mp3'));
    _initializeGameData();
    _createBottleComponents();
    Future.delayed(const Duration(milliseconds: 300), _checkDeadlock);
  }

  @override
  void onRemove() {
    _audioPlayer.dispose();
    super.onRemove();
  }

  Future<void> _playWaterSound() async {
    if (!Get.find<SettingsController>().soundEnabled.value) return;
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('audio/water_sound.mp3'));
    } catch (_) {}
  }

  void _haptic(void Function() trigger) {
    if (Get.find<SettingsController>().hapticsEnabled.value) trigger();
  }

  /// Shared color palette — also used by the home screen to render the
  /// per-level difficulty dots, so keep this the single source of truth.
  static const List<MaterialColor> palette = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.yellow,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
  ];

  /// Number of liquid colors for a given level — ramps up every 20 levels
  /// (two "worlds" worth) so the curve lines up with the world groupings
  /// on the home screen: 4 colors through level 20, up to 8 by level 81+.
  static int numColorsForLevel(int level) {
    final int tier = ((level - 1) ~/ 20).clamp(0, 4);
    return 4 + tier;
  }

  /// Empty bottles available to sort into. Instead of staying fixed for
  /// all 100 levels, it steps down from 3 to 1 across each 20-level color
  /// tier so difficulty still climbs between the coarser color-count
  /// jumps, not just at the tier boundaries.
  static int numEmptyBottlesForLevel(int level) {
    final int withinTier = (level - 1) % 20;
    if (withinTier < 7) return 3;
    if (withinTier < 14) return 2;
    return 1;
  }

  /// Star rating for a completed level. Thresholds scale with how many
  /// colors that level uses — a fixed 15-move bar for 3 stars was unfair
  /// once levels ramped up to 7-8 colors, which inherently need more moves.
  static int starRating(int level, int moves) {
    if (moves <= 0) return 0;
    final int numColors = numColorsForLevel(level);
    final int threshold3 = 15 + (numColors - 4) * 4;
    final int threshold2 = 25 + (numColors - 4) * 6;
    if (moves <= threshold3) return 3;
    if (moves <= threshold2) return 2;
    return 1;
  }

  void _initializeGameData() {
    final int numColors = numColorsForLevel(level);
    final List<Color> gameColors =
        palette.sublist(0, numColors).map((c) => c.shade600).toList();
    final int totalBottles = numColors + numEmptyBottlesForLevel(level);

    final List<Color> allColors = [];
    for (final color in gameColors) {
      for (int i = 0; i < BottleComponent.maxCapacity; i++) {
        allColors.add(color);
      }
    }

    allColors.shuffle();

    bottlesData = List.generate(totalBottles, (i) => []);

    for (int i = 0; i < numColors; i++) {
      bottlesData[i] = allColors.sublist(
        i * BottleComponent.maxCapacity,
        (i + 1) * BottleComponent.maxCapacity,
      );
    }

    _undoStack.clear();
  }

  /// Splits [n] bottles into visually balanced rows (max 3 per row up to
  /// 6 bottles, max 4 per row beyond that) so higher levels with more
  /// colors still lay out cleanly.
  List<int> _computeRowLayout(int n) {
    final int maxPerRow = n <= 6 ? 3 : 4;
    final int numRows = (n / maxPerRow).ceil();
    final int base = n ~/ numRows;
    final int extra = n % numRows;
    return List.generate(numRows, (i) => base + (i < extra ? 1 : 0));
  }

  /// Shrinks bottle spacing when a row would otherwise overflow the
  /// available canvas width (levels with 4+ bottles per row on narrow
  /// screens).
  double _computeSpacingX(int rowSize) {
    const double defaultSpacing = 38;
    const double sideMargin = 24;
    final double available = size.x - sideMargin * 2;
    final double neededWidth = rowSize * BottleComponent.bottleWidth +
        (rowSize - 1) * defaultSpacing;

    if (neededWidth <= available || rowSize <= 1) return defaultSpacing;

    final double fitted =
        (available - rowSize * BottleComponent.bottleWidth) / (rowSize - 1);
    return fitted.clamp(10.0, defaultSpacing);
  }

  void _createBottleComponents() {
    const double spacingY = 50;

    final BottleStyle style = Get.find<SettingsController>().bottleStyle.value;
    final layout = _computeRowLayout(bottlesData.length);
    int bottleIdx = 0;

    double currentCenterY = BottleComponent.bottleHeight / 2 + 50;

    for (final rowSize in layout) {
      final double spacingX = _computeSpacingX(rowSize);
      final double rowWidth =
          (rowSize * BottleComponent.bottleWidth) + ((rowSize - 1) * spacingX);

      double currentCenterX =
          (size.x - rowWidth) / 2 + BottleComponent.bottleWidth / 2;

      for (int i = 0; i < rowSize; i++) {
        final topLeftPosition = Vector2(
          currentCenterX - BottleComponent.bottleWidth / 2,
          currentCenterY - BottleComponent.bottleHeight / 2,
        );

        final bottle = BottleComponent(
          index: bottleIdx,
          colors: bottlesData[bottleIdx],
          position: topLeftPosition,
          onTap: _handleBottleTap,
          style: style,
        );

        bottleComponents.add(bottle);
        add(bottle);

        currentCenterX += BottleComponent.bottleWidth + spacingX;
        bottleIdx++;
      }

      currentCenterY += BottleComponent.bottleHeight + spacingY;
    }
  }

  bool _isCompletedBottle(int index) {
    final bottle = bottlesData[index];
    return bottle.length == BottleComponent.maxCapacity &&
        bottle.every((color) => color == bottle.first);
  }

  // ---- Hint logic ----
  void showHint() {
    if (_isAnimating) return;
    _clearHint();

    // Find first valid move
    for (int from = 0; from < bottlesData.length; from++) {
      if (bottlesData[from].isEmpty) continue;
      if (_isCompletedBottle(from)) continue;
      for (int to = 0; to < bottlesData.length; to++) {
        if (from == to) continue;
        if (_isCompletedBottle(to)) continue;
        if (_isValidMove(from, to)) {
          _hintFrom = from;
          _hintTo = to;
          bottleComponents[from].isHinted = true;
          bottleComponents[to].isHintTarget = true;
          onHintUsed?.call();

          // Auto-clear hint after 2.5 seconds
          Future.delayed(const Duration(milliseconds: 2500), _clearHint);
          return;
        }
      }
    }
  }

  bool _hasAnyValidMove() {
    for (int from = 0; from < bottlesData.length; from++) {
      if (bottlesData[from].isEmpty) continue;
      if (_isCompletedBottle(from)) continue;
      for (int to = 0; to < bottlesData.length; to++) {
        if (from == to) continue;
        if (_isCompletedBottle(to)) continue;
        if (_isValidMove(from, to)) return true;
      }
    }
    return false;
  }

  void _checkDeadlock() {
    if (_checkWin()) return;
    if (!_hasAnyValidMove()) {
      onNoMoves?.call();
    }
  }

  void _clearHint() {
    if (_hintFrom != null && _hintFrom! < bottleComponents.length) {
      bottleComponents[_hintFrom!].isHinted = false;
    }
    if (_hintTo != null && _hintTo! < bottleComponents.length) {
      bottleComponents[_hintTo!].isHintTarget = false;
    }
    _hintFrom = null;
    _hintTo = null;
  }

  // ---- Undo logic ----
  bool get canUndo => _undoStack.isNotEmpty && !_isAnimating;

  void undo() {
    if (!canUndo) return;
    _clearHint();

    final snapshot = _undoStack.removeLast();
    for (int i = 0; i < bottlesData.length; i++) {
      bottlesData[i] = snapshot.bottlesData[i];
      // IMPORTANT: also update the BottleComponent's colors reference
      // so the Flame render picks up the restored state immediately
      if (i < bottleComponents.length) {
        bottleComponents[i].colors = bottlesData[i];
        bottleComponents[i].snapToData();
      }
    }
    onMoveUpdate(-1); // decrement move count
  }

  void _handleBottleTap(int index) {
    if (_isAnimating) return;
    _clearHint();

    if (_isCompletedBottle(index)) return;

    if (selectedIndex == null) {
      if (bottlesData[index].isNotEmpty) {
        _haptic(HapticFeedback.selectionClick);
        _isAnimating = true;
        selectedIndex = index;

        final bottle = bottleComponents[index];
        bottle.isSelected = true;

        bottle.add(
          MoveEffect.to(
            bottle.initialPosition - Vector2(0, 25),
            EffectController(duration: 0.20, curve: Curves.easeOut),
            onComplete: () {
              _isAnimating = false;
            },
          ),
        );
      }
    } else {
      if (selectedIndex == index) {
        _deselect();
      } else {
        if (_isCompletedBottle(selectedIndex!) || _isCompletedBottle(index)) {
          _deselect();
        } else if (_isValidMove(selectedIndex!, index)) {
          _tryPour(selectedIndex!, index);
        } else {
          _shakeBottle(index);
          _deselect();
        }
      }
    }
  }

  void _shakeBottle(int index) {
    _haptic(HapticFeedback.mediumImpact);
    final bottle = bottleComponents[index];
    final Vector2 basePos = bottle.position.clone();

    bottle.add(
      MoveEffect.by(
        Vector2(8, 0),
        EffectController(duration: 0.05, curve: Curves.easeInOut),
        onComplete: () {
          bottle.add(
            MoveEffect.by(
              Vector2(-16, 0),
              EffectController(duration: 0.08, curve: Curves.easeInOut),
              onComplete: () {
                bottle.add(
                  MoveEffect.by(
                    Vector2(16, 0),
                    EffectController(duration: 0.08, curve: Curves.easeInOut),
                    onComplete: () {
                      bottle.add(
                        MoveEffect.to(
                          basePos,
                          EffectController(
                              duration: 0.05, curve: Curves.easeInOut),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  bool _isValidMove(int from, int to) {
    if (bottlesData[from].isEmpty) return false;
    if (bottlesData[to].length >= BottleComponent.maxCapacity) return false;

    if (bottlesData[to].isNotEmpty &&
        bottlesData[to].last != bottlesData[from].last) {
      return false;
    }

    return true;
  }

  void _deselect() {
    if (selectedIndex == null) return;

    _isAnimating = true;

    final bottle = bottleComponents[selectedIndex!];
    bottle.isSelected = false;

    bottle.add(
      MoveEffect.to(
        bottle.initialPosition,
        EffectController(duration: 0.22, curve: Curves.easeInOut),
        onComplete: () {
          selectedIndex = null;
          _isAnimating = false;
        },
      ),
    );
  }

  // ---- Combo tracking: back-to-back bottle completions escalate the
  // celebration intensity, rewarding chained clears within one pour. ----
  int _comboStreak = 0;
  int _comboGeneration = 0;

  double _registerCombo() {
    _comboStreak++;
    final double intensity = (1 + (_comboStreak - 1) * 0.28).clamp(1.0, 2.2);
    final int myGeneration = ++_comboGeneration;
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (_comboGeneration == myGeneration) _comboStreak = 0;
    });
    return intensity;
  }

  void _celebrateBottle(int index) {
    final double intensity = _registerCombo();

    final bottle = bottleComponents[index];
    bottle.celebrate();

    final burstPosition = bottle.initialPosition +
        Vector2(BottleComponent.bottleWidth / 2, 0);
    final bottleColor = bottlesData[index].first;

    add(CelebrationBurst(
      bottleColor: bottleColor,
      position: burstPosition,
      intensity: intensity,
    ));
    add(CelebrationShockwave(
      position: burstPosition,
      color: bottleColor,
      intensity: intensity,
    ));
    add(CelebrationBadge(position: burstPosition + Vector2(0, -10)));
  }

  Future<void> _tryPour(int from, int to) async {
    final Color colorToPour = bottlesData[from].last;

    int pourAmount = 0;
    for (int i = bottlesData[from].length - 1; i >= 0; i--) {
      if (bottlesData[from][i] == colorToPour &&
          (bottlesData[to].length + pourAmount) < BottleComponent.maxCapacity) {
        pourAmount++;
      } else {
        break;
      }
    }

    // Save undo snapshot before modifying state
    _undoStack.add(_GameSnapshot(bottlesData));

    _isAnimating = true;

    final fromBottle = bottleComponents[from];
    final toBottle = bottleComponents[to];

    const double pourDirection = 1.0;

    final double liftY = min(
          fromBottle.initialPosition.y,
          toBottle.initialPosition.y,
        ) -
        BottleComponent.bottleHeight * 0.72;

    fromBottle.add(
      MoveEffect.to(
        Vector2(fromBottle.position.x, liftY),
        EffectController(duration: 0.35, curve: Curves.easeOutCubic),
        onComplete: () {
          final Vector2 closePourPosition =
              toBottle.mouthCenter + Vector2(-6, -18);

          fromBottle.add(
            MoveEffect.to(
              closePourPosition,
              EffectController(duration: 0.60, curve: Curves.easeInOutCubic),
              onComplete: () {
                fromBottle.add(
                  RotateEffect.to(
                    -pourDirection * 1.28,
                    EffectController(
                      duration: 0.60,
                      curve: Curves.easeInOutCubic,
                    ),
                    onComplete: () async {
                      fromBottle.isPouringWave = true;
                      toBottle.isPouringWave = true;

                      final streamStart = fromBottle.tiltedMouthWorld;
                      final streamTarget =
                          toBottle.mouthCenter + Vector2(0, 7);

                      final stream = WaterStreamComponent(
                        color: colorToPour,
                        position: streamStart,
                        target: streamTarget,
                      );

                      add(stream);
                      _playWaterSound();

                      for (int i = 0; i < pourAmount; i++) {
                        await Future.delayed(
                          const Duration(milliseconds: 420),
                        );
                        if (bottlesData[from].isNotEmpty) {
                          final pouredColor = bottlesData[from].removeLast();
                          bottlesData[to].add(pouredColor);
                          toBottle.triggerImpact();
                          final landingSpot = toBottle.liquidSurfaceWorld;
                          add(SplashRipple(
                            position: landingSpot,
                            color: pouredColor,
                          ));
                          add(SplashDroplets(
                            position: landingSpot,
                            color: pouredColor,
                          ));
                        }
                      }

                      await Future.delayed(
                        const Duration(milliseconds: 220),
                      );

                      onMoveUpdate(1);
                      remove(stream);

                      fromBottle.isPouringWave = false;
                      toBottle.isPouringWave = false;

                      fromBottle.add(
                        RotateEffect.to(
                          0,
                          EffectController(
                            duration: 0.45,
                            curve: Curves.easeInOutCubic,
                          ),
                          onComplete: () {
                            fromBottle.add(
                              MoveEffect.to(
                                Vector2(fromBottle.initialPosition.x, liftY),
                                EffectController(
                                  duration: 0.35,
                                  curve: Curves.easeInOutCubic,
                                ),
                                onComplete: () {
                                  fromBottle.add(
                                    MoveEffect.to(
                                      fromBottle.initialPosition,
                                      EffectController(
                                        duration: 0.35,
                                        curve: Curves.easeInCubic,
                                      ),
                                      onComplete: () {
                                        fromBottle.isSelected = false;
                                        selectedIndex = null;
                                        _isAnimating = false;

                                        if (_isCompletedBottle(to)) {
                                          _celebrateBottle(to);
                                        }
                                        if (_isCompletedBottle(from)) {
                                          _celebrateBottle(from);
                                        }

                                        if (_checkWin()) {
                                          _haptic(HapticFeedback.heavyImpact);
                                          Future.delayed(
                                            const Duration(milliseconds: 700),
                                            onWin,
                                          );
                                        } else {
                                          _checkDeadlock();
                                        }
                                      },
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  bool _checkWin() {
    return bottlesData.every(
      (bottle) =>
          bottle.isEmpty ||
          (bottle.length == BottleComponent.maxCapacity &&
              bottle.every((color) => color == bottle[0])),
    );
  }

  void reset() {
    removeAll(bottleComponents);
    bottleComponents.clear();
    _clearHint();

    _initializeGameData();
    _createBottleComponents();

    selectedIndex = null;
    _isAnimating = false;

    Future.delayed(const Duration(milliseconds: 300), _checkDeadlock);
  }
}

// ---------------------------------------------------------------------------
// GameScreen widget
// ---------------------------------------------------------------------------
class GameScreen extends StatefulWidget {
  final int level;

  const GameScreen({
    super.key,
    required this.level,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  late WaterSortGame _game;
  int _moveCount = 0;

  // Timer
  late Stopwatch _stopwatch;
  late AnimationController _timerTick;
  bool _isPaused = false;

  late ConfettiController _confettiController;
  int _coinsEarned = 0;

  @override
  void initState() {
    super.initState();

    _stopwatch = Stopwatch()..start();

    // Tick every second to rebuild timer display
    _timerTick = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
    _timerTick.addListener(() {
      if (mounted && !_isPaused) setState(() {});
    });

    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));

    _game = WaterSortGame(
      level: widget.level,
      onMoveUpdate: (delta) {
        setState(() {
          _moveCount = (_moveCount + delta).clamp(0, 9999);
        });
      },
      onWin: _handleWin,
      onNoMoves: _handleNoMoves,
      onHintUsed: () => Get.find<ShopController>().useHint(),
    );
  }

  void _useHint() {
    final shop = Get.find<ShopController>();
    if (shop.hintTokens.value <= 0) {
      _showOutOfTokensDialog('hints');
      return;
    }
    _game.showHint();
  }

  void _useUndo() {
    if (!_game.canUndo) return;
    final shop = Get.find<ShopController>();
    if (!shop.canUndo) {
      _showOutOfTokensDialog('undos');
      return;
    }
    shop.useUndo();
    _game.undo();
  }

  void _showOutOfTokensDialog(String tokenName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Out of $tokenName'),
        content: Text('Visit the Shop to get more $tokenName using coins.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Get.to(
                () => const ShopScreen(),
                transition: Transition.rightToLeftWithFade,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Go to Shop'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timerTick.dispose();
    _stopwatch.stop();
    _confettiController.dispose();
    super.dispose();
  }

  String get _timerText {
    final elapsed = _stopwatch.elapsed;
    final m = elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _handleWin() {
    _stopwatch.stop();
    _timerTick.stop();
    _confettiController.play();

    // Save best score
    final levelController = Get.find<LevelController>();
    levelController.saveBestScore(widget.level, _moveCount);

    final stars = WaterSortGame.starRating(widget.level, _moveCount);
    _coinsEarned = CoinController.rewardForStars(stars);
    Get.find<CoinController>().addCoins(_coinsEarned);
    Get.find<AchievementController>().checkAll();

    _showSuccessDialog();
  }

  void _handleNoMoves() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.sentiment_dissatisfied_rounded,
                  color: Colors.orange.shade600, size: 48),
              const SizedBox(height: 8),
              const Text(
                'No Moves Left',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
              ),
            ],
          ),
          content: const Text(
            "There's no valid pour left on the board. Undo your last move or restart the level.",
            textAlign: TextAlign.center,
          ),
          actions: [
            Row(
              children: [
                if (_game.canUndo)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _game.undo();
                      },
                      icon: const Icon(Icons.undo_rounded),
                      label: const Text('Undo'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue.shade700,
                        side: BorderSide(color: Colors.blue.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                if (_game.canUndo) const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      setState(() {
                        _moveCount = 0;
                        _stopwatch.reset();
                        _stopwatch.start();
                        _isPaused = false;
                        _game.reset();
                      });
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Restart'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
      if (_isPaused) {
        _stopwatch.stop();
      } else {
        _stopwatch.start();
      }
    });
  }

  void _showSuccessDialog() {
    final stars = WaterSortGame.starRating(widget.level, _moveCount);
    final levelController = Get.find<LevelController>();
    final best = levelController.getBestScore(widget.level);
    final world = gameWorlds.firstWhere((w) => w.containsLevel(widget.level));
    final bool isWorldComplete = widget.level == world.endLevel;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Column(
            children: [
              // Animated stars
              _AnimatedStars(stars: stars),
              const SizedBox(height: 10),
              Text(
                isWorldComplete
                    ? '🏆 World Complete!'
                    : stars == 3
                        ? '🎉 Perfect!'
                        : stars == 2
                            ? '👏 Well Done!'
                            : '✅ Level Clear!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Level ${widget.level} Completed!',
                style: TextStyle(
                  fontSize: 17,
                  color: Colors.blue[700],
                ),
              ),
              if (isWorldComplete) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.shade400),
                  ),
                  child: Text(
                    'You cleared "${world.name}"!',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade800,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 14),
              _StatRow(
                icon: Icons.swap_horiz_rounded,
                label: 'Moves',
                value: '$_moveCount',
                color: Colors.blue,
              ),
              const SizedBox(height: 6),
              _StatRow(
                icon: Icons.timer_outlined,
                label: 'Time',
                value: _timerText,
                color: Colors.teal,
              ),
              if (best > 0) ...[
                const SizedBox(height: 6),
                _StatRow(
                  icon: Icons.emoji_events_outlined,
                  label: 'Best',
                  value: '$best moves',
                  color: Colors.amber.shade700,
                ),
              ],
              const SizedBox(height: 12),
              _CoinReward(amount: _coinsEarned),
            ],
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      setState(() {
                        _moveCount = 0;
                        _stopwatch.reset();
                        _stopwatch.start();
                        _timerTick.repeat();
                        _game.reset();
                      });
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue.shade700,
                      side: BorderSide(color: Colors.blue.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop(true);
                    },
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: const Text('Continue'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gameBackground,
      appBar: AppBar(
        // Default back button stays (automaticallyImplyLeading: true by default)
        title: Text(
          'Level ${widget.level}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Timer display
          Center(
            child: Container(
              margin: const EdgeInsets.only(right: 4),
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.shade900.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.timer_outlined, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    _timerText,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Pause button — right side, next to timer
          IconButton(
            icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
            tooltip: _isPaused ? 'Resume' : 'Pause',
            onPressed: _togglePause,
          ),
          // Reset button
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Restart',
            onPressed: () {
              setState(() {
                _moveCount = 0;
                _stopwatch.reset();
                _stopwatch.start();
                _isPaused = false;
                _game.reset();
              });
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Stats bar: Moves (left) | Stars (center) | Hint + Undo (right)
                Container(
                  color: Colors.blue.shade800,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Move counter — left
                      _InfoChip(
                        icon: Icons.swap_horiz_rounded,
                        label: 'Moves: $_moveCount',
                        color: Colors.white,
                      ),
                      // Star rating — center
                      Row(
                        children: List.generate(3, (i) {
                          final filled =
                              i < WaterSortGame.starRating(widget.level, _moveCount);
                          return Icon(
                            filled ? Icons.star : Icons.star_border,
                            color: filled
                                ? Colors.amber
                                : Colors.white.withOpacity(0.4),
                            size: 20,
                          );
                        }),
                      ),
                      // Hint + Undo — right
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Obx(
                            () => _TokenActionChip(
                              icon: Icons.lightbulb_rounded,
                              label: 'Hint',
                              count: Get.find<ShopController>()
                                  .hintTokens
                                  .value,
                              onTap: _useHint,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Obx(
                            () => _TokenActionChip(
                              icon: Icons.undo_rounded,
                              label: 'Undo',
                              count: Get.find<ShopController>()
                                  .undoTokens
                                  .value,
                              onTap: _useUndo,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: AnimatedWaterBackground(
                    gradientColors: AppColors.gameBackgroundGradient,
                    bubbleColor: Colors.lightBlueAccent,
                    bubbleCount: 12,
                    maxBubbleOpacity: 0.12,
                    child: GameWidget(game: _game),
                  ),
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8, top: 4),
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'Powered By ',
                            style: TextStyle(color: Colors.grey.shade500),
                          ),
                          const TextSpan(
                            text: 'Kingkar',
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Pause overlay
            if (_isPaused)
              Container(
                color: Colors.black.withOpacity(0.75),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.pause_circle_filled,
                          color: Colors.white, size: 72),
                      const SizedBox(height: 16),
                      const Text(
                        'PAUSED',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _togglePause,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Resume'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            // Win celebration confetti
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                numberOfParticles: 28,
                maxBlastForce: 22,
                minBlastForce: 8,
                gravity: 0.35,
                colors: const [
                  Colors.blue,
                  Colors.red,
                  Colors.green,
                  Colors.orange,
                  Colors.purple,
                  Colors.amber,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helper widgets
// ---------------------------------------------------------------------------

/// Hint/Undo button in the in-game stats bar, showing the remaining token
/// count as a small badge. Tapping when [count] is 0 still fires [onTap] —
/// the handler is responsible for nudging the player to the Shop instead
/// of performing the action.
class _TokenActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final VoidCallback onTap;

  const _TokenActionChip({
    required this.icon,
    required this.label,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool depleted = count <= 0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.blue.shade300.withOpacity(depleted ? 0.08 : 0.2),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.blue.shade200.withOpacity(depleted ? 0.5 : 1.0),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                color: Colors.blue.shade100.withOpacity(depleted ? 0.6 : 1.0),
                size: 18),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.blue.shade100.withOpacity(depleted ? 0.6 : 1.0),
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: depleted ? Colors.red.shade300 : Colors.amber.shade400,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Pill showing coins earned for the level, with a small pop-in so it reads
/// as a reward rather than just another stat line.
class _CoinReward extends StatefulWidget {
  final int amount;
  const _CoinReward({required this.amount});

  @override
  State<_CoinReward> createState() => _CoinRewardState();
}

class _CoinRewardState extends State<_CoinReward>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scale = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.amber.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.amber.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.monetization_on_rounded,
                color: Colors.amber.shade700, size: 20),
            const SizedBox(width: 6),
            Text(
              '+${widget.amount} Coins',
              style: TextStyle(
                color: Colors.amber.shade800,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

/// Animated star row for win dialog
class _AnimatedStars extends StatefulWidget {
  final int stars;
  const _AnimatedStars({required this.stars});

  @override
  State<_AnimatedStars> createState() => _AnimatedStarsState();
}

class _AnimatedStarsState extends State<_AnimatedStars>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _scales;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400),
      ),
    );
    _scales = _controllers
        .map(
          (c) => Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(parent: c, curve: Curves.elasticOut),
          ),
        )
        .toList();

    // Stagger the star animations
    for (int i = 0; i < widget.stars; i++) {
      Future.delayed(Duration(milliseconds: 200 + i * 180), () {
        if (mounted) _controllers[i].forward();
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        final filled = i < widget.stars;
        return ScaleTransition(
          scale: filled ? _scales[i] : const AlwaysStoppedAnimation(1.0),
          child: Icon(
            filled ? Icons.star_rounded : Icons.star_border_rounded,
            color: filled ? Colors.amber : Colors.grey.shade300,
            size: 44,
          ),
        );
      }),
    );
  }
}

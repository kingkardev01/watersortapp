import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:watersortapp/controllers/level_controller.dart';

// ---------------------------------------------------------------------------
// Sparkle particle for the bottle-sorted celebration
// ---------------------------------------------------------------------------
class SparkleParticle extends PositionComponent {
  final Color color;
  final double sparkleAngle;
  final double speed;
  double _life = 1.0;
  final double _size;

  SparkleParticle({
    required this.color,
    required this.sparkleAngle,
    required this.speed,
    required Vector2 position,
    double size = 5.0,
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
  final _rng = Random();

  CelebrationBurst({
    required this.bottleColor,
    required Vector2 position,
  }) : super(position: position);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _spawnParticles();
  }

  void _spawnParticles() {
    const int count = 22;
    final List<Color> palette = [
      bottleColor,
      Colors.white,
      Colors.yellow.shade300,
      Colors.amber,
      bottleColor.withOpacity(0.7),
    ];

    for (int i = 0; i < count; i++) {
      final angle = (2 * pi / count) * i + _rng.nextDouble() * 0.4;
      final speed = 60.0 + _rng.nextDouble() * 90.0;
      final color = palette[_rng.nextInt(palette.length)];
      final size = 3.5 + _rng.nextDouble() * 4.0;

      add(SparkleParticle(
        color: color,
        sparkleAngle: angle,
        speed: speed,
        position: Vector2.zero(),
        size: size,
      ));
    }

    Future.delayed(const Duration(milliseconds: 900), () {
      if (isMounted) removeFromParent();
    });
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
  late Vector2 initialPosition;

  double waveTime = 0;
  bool isPouringWave = false;

  bool _isCelebrating = false;
  double _celebrateTime = 0;

  static const double bottleWidth = 58;
  static const double bottleHeight = 145;
  static const int maxCapacity = 4;
  static const double borderRadius = 22;

  BottleComponent({
    required this.index,
    required this.colors,
    required this.onTap,
    required Vector2 position,
  }) : super(
          position: position,
          size: Vector2(bottleWidth, bottleHeight),
          anchor: Anchor.topLeft,
        ) {
    initialPosition = position.clone();
  }

  Vector2 get centerPosition => position + size / 2;
  Vector2 get mouthCenter => position + Vector2(width / 2, 0);

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

    final glassFillPaint = Paint()
      ..color = Colors.white.withOpacity(0.09)
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
    final double bottomCurveHeight = 36;

    final tubeFillPath = Path()
      ..moveTo(bodyLeft, bodyTop)
      ..lineTo(bodyLeft, bodyBottom - bottomCurveHeight)
      ..quadraticBezierTo(bodyLeft, bodyBottom, width / 2, bodyBottom)
      ..quadraticBezierTo(
          bodyRight, bodyBottom, bodyRight, bodyBottom - bottomCurveHeight)
      ..lineTo(bodyRight, bodyTop)
      ..close();

    final double innerLeft = 7;
    final double innerTop = 15;
    final double innerRight = width - 7;
    final double innerBottom = height - 2;
    final double innerBottomCurveHeight = 31;
    final double innerWidth = innerRight - innerLeft;
    final double innerHeight = innerBottom - innerTop;

    final innerLiquidPath = Path()
      ..moveTo(innerLeft, innerTop)
      ..lineTo(innerLeft, innerBottom - innerBottomCurveHeight)
      ..quadraticBezierTo(innerLeft, innerBottom, width / 2, innerBottom)
      ..quadraticBezierTo(
          innerRight, innerBottom, innerRight, innerBottom - innerBottomCurveHeight)
      ..lineTo(innerRight, innerTop)
      ..close();

    canvas.drawPath(tubeFillPath, glassFillPaint);

    canvas.save();
    canvas.clipPath(innerLiquidPath);

    final double liquidBottomY = innerBottom + 1;
    final double layerHeight = innerHeight / maxCapacity;

    for (int i = 0; i < colors.length; i++) {
      final double topY = liquidBottomY - (i + 1) * layerHeight;
      final double bottomY = liquidBottomY - i * layerHeight;

      final colorPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colors[i].withOpacity(0.84),
            colors[i],
          ],
        ).createShader(
          Rect.fromLTWH(innerLeft, topY, innerWidth, layerHeight),
        );

      final bool isTopLayer = i == colors.length - 1;
      final path = Path();

      if (isTopLayer) {
        final double wavePower = isPouringWave ? 6.0 : 2.0;
        final double wave1 = sin(waveTime) * wavePower;
        final double wave2 = sin(waveTime + 1.8) * wavePower;

        path.moveTo(innerLeft, topY + wave1);
        path.quadraticBezierTo(
          innerLeft + innerWidth * 0.50,
          topY - wavePower,
          innerRight,
          topY + wave2,
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
    }

    if (colors.isNotEmpty) {
      final bottomDepthPaint = Paint()
        ..color = colors.first.withOpacity(0.24)
        ..style = PaintingStyle.fill;

      canvas.drawOval(
        Rect.fromLTWH(innerLeft + 3, height - 29, innerWidth - 6, 23),
        bottomDepthPaint,
      );
    }

    canvas.restore();

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

    final borderPath = Path()
      ..moveTo(bodyLeft, bodyTop + 3)
      ..lineTo(bodyLeft, bodyBottom - bottomCurveHeight)
      ..quadraticBezierTo(bodyLeft, bodyBottom, width / 2, bodyBottom)
      ..quadraticBezierTo(
          bodyRight, bodyBottom, bodyRight, bodyBottom - bottomCurveHeight)
      ..lineTo(bodyRight, bodyTop + 3);

    canvas.drawPath(borderPath, glassBorderPaint);

    final mouthOuterRect =
        Rect.fromLTWH(bodyLeft, bodyTop - 6, bodyWidth, 13);
    final mouthInnerRect =
        Rect.fromLTWH(bodyLeft + 5, bodyTop - 3, bodyWidth - 10, 7);

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

    canvas.drawArc(
      Rect.fromLTWH(bodyLeft + 4, bodyTop - 5, bodyWidth - 8, 11),
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

  @override
  void render(Canvas canvas) {
    final diff = target - position;

    final paint = Paint()
      ..color = color.withOpacity(0.9)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path()..moveTo(0, 0);
    final waveOffset = sin(time) * 3;

    path.quadraticBezierTo(
      diff.x * 0.45 + waveOffset,
      diff.y * -0.08,
      diff.x,
      diff.y,
    );

    canvas.drawPath(path, paint);

    final dropPaint = Paint()
      ..color = color.withOpacity(0.70)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(diff.x * 0.52 + sin(time) * 3, diff.y * 0.45),
      2.8,
      dropPaint,
    );

    canvas.drawCircle(
      Offset(diff.x * 0.77 + cos(time) * 3, diff.y * 0.72),
      2,
      dropPaint,
    );
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

  WaterSortGame({
    required this.level,
    required this.onMoveUpdate,
    required this.onWin,
    this.onHintUsed,
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await _audioPlayer.setSource(AssetSource('audio/water_sound.mp3'));
    _initializeGameData();
    _createBottleComponents();
  }

  @override
  void onRemove() {
    _audioPlayer.dispose();
    super.onRemove();
  }

  Future<void> _playWaterSound() async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('audio/water_sound.mp3'));
    } catch (_) {}
  }

  void _initializeGameData() {
    final List<Color> palette = [
      Colors.red.shade600,
      Colors.blue.shade600,
      Colors.green.shade600,
      Colors.yellow.shade600,
      Colors.orange.shade600,
      Colors.purple.shade600,
    ];

    const int numColors = 6;
    final List<Color> gameColors = palette.sublist(0, numColors);

    final List<Color> allColors = [];
    for (final color in gameColors) {
      for (int i = 0; i < BottleComponent.maxCapacity; i++) {
        allColors.add(color);
      }
    }

    allColors.shuffle();

    bottlesData = List.generate(8, (i) => []);

    for (int i = 0; i < numColors; i++) {
      bottlesData[i] = allColors.sublist(
        i * BottleComponent.maxCapacity,
        (i + 1) * BottleComponent.maxCapacity,
      );
    }

    _undoStack.clear();
  }

  void _createBottleComponents() {
    const double spacingX = 38;
    const double spacingY = 50;

    final layout = [3, 3, 2];
    int bottleIdx = 0;

    double currentCenterY = BottleComponent.bottleHeight / 2 + 50;

    for (final rowSize in layout) {
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
          _deselect();
        }
      }
    }
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

  void _celebrateBottle(int index) {
    final bottle = bottleComponents[index];
    bottle.celebrate();

    final burstPosition = bottle.initialPosition +
        Vector2(BottleComponent.bottleWidth / 2, 0);
    final burst = CelebrationBurst(
      bottleColor: bottlesData[index].first,
      position: burstPosition,
    );
    add(burst);
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

                      final streamStart =
                          fromBottle.position + Vector2(3, 4);
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
                          bottlesData[to].add(bottlesData[from].removeLast());
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
                                          Future.delayed(
                                            const Duration(milliseconds: 700),
                                            onWin,
                                          );
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

    _game = WaterSortGame(
      level: widget.level,
      onMoveUpdate: (delta) {
        setState(() {
          _moveCount = (_moveCount + delta).clamp(0, 9999);
        });
      },
      onWin: _handleWin,
    );
  }

  @override
  void dispose() {
    _timerTick.dispose();
    _stopwatch.stop();
    super.dispose();
  }

  String get _timerText {
    final elapsed = _stopwatch.elapsed;
    final m = elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  /// Star rating: 3 stars ≤ 15 moves, 2 stars ≤ 25, 1 star otherwise
  int _starRating(int moves) {
    if (moves <= 15) return 3;
    if (moves <= 25) return 2;
    return 1;
  }

  void _handleWin() {
    _stopwatch.stop();
    _timerTick.stop();

    // Save best score
    final levelController = Get.find<LevelController>();
    levelController.saveBestScore(widget.level, _moveCount);

    _showSuccessDialog();
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
    final stars = _starRating(_moveCount);
    final levelController = Get.find<LevelController>();
    final best = levelController.getBestScore(widget.level);

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
                stars == 3
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
      backgroundColor: Colors.black,
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
                // Stats bar: Moves (left) | Stars (center) | Undo (right)
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
                          final filled = i < _starRating(_moveCount);
                          return Icon(
                            filled ? Icons.star : Icons.star_border,
                            color: filled
                                ? Colors.amber
                                : Colors.white.withOpacity(0.4),
                            size: 20,
                          );
                        }),
                      ),
                      // Undo button — right
                      GestureDetector(
                        onTap: () => _game.undo(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade300.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: Colors.blue.shade200, width: 1.2),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.undo_rounded,
                                  color: Colors.blue.shade100, size: 18),
                              const SizedBox(width: 4),
                              Text(
                                'Undo',
                                style: TextStyle(
                                  color: Colors.blue.shade100,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: GameWidget(game: _game),
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
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helper widgets
// ---------------------------------------------------------------------------

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

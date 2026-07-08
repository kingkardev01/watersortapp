import 'package:flutter/material.dart';

/// Visual style for the bottle/tube glass — purely cosmetic, chosen by
/// the player in Settings. Each style reuses the same liquid/wave/glass
/// rendering logic in BottleComponent, just with different body curve
/// geometry and glass tint so they read as genuinely different vessels.
enum BottleStyle {
  classicTube,
  labTestTube,
  modernGlass,
  crystalDecanter,
  royalGoblet,
}

class BottleStyleInfo {
  final String label;
  final IconData icon;
  final double bottomCurveHeight;
  final double innerBottomCurveHeight;
  final Color tint;

  /// Fraction of the body's half-width that the neck/mouth opening uses.
  /// 1.0 = straight-sided tube (mouth as wide as the body). Below 1.0 the
  /// walls taper inward to a narrower neck like a real flask; above 1.0
  /// they flare outward like a tumbler rim.
  final double neckWidthRatio;

  /// Extra outward bulge (as a fraction of half-width) around the belly
  /// of the vessel. 0 = straight sides. >0 curves the walls outward past
  /// the body width and back in, like the round belly of a lab flask.
  final double bellyBulgeRatio;

  /// Coin price to unlock this style in the Shop. 0 = free/always owned.
  final int price;

  const BottleStyleInfo({
    required this.label,
    required this.icon,
    required this.bottomCurveHeight,
    required this.innerBottomCurveHeight,
    required this.tint,
    this.neckWidthRatio = 1.0,
    this.bellyBulgeRatio = 0.0,
    this.price = 0,
  });
}

const Map<BottleStyle, BottleStyleInfo> bottleStyleInfo = {
  BottleStyle.classicTube: BottleStyleInfo(
    label: 'Classic Tube',
    icon: Icons.crop_portrait_rounded,
    bottomCurveHeight: 40,
    innerBottomCurveHeight: 35,
    tint: Colors.white,
    neckWidthRatio: 1.0,
    bellyBulgeRatio: 0.0,
  ),
  BottleStyle.labTestTube: BottleStyleInfo(
    label: 'Lab Test Tube',
    icon: Icons.biotech_rounded,
    bottomCurveHeight: 58,
    innerBottomCurveHeight: 52,
    tint: Color(0xFFDCF2E3),
    neckWidthRatio: 1.0,
    bellyBulgeRatio: 0.0,
  ),
  BottleStyle.modernGlass: BottleStyleInfo(
    label: 'Modern Glass',
    icon: Icons.local_bar_rounded,
    bottomCurveHeight: 10,
    innerBottomCurveHeight: 7,
    tint: Color(0xFFCFE9FF),
    neckWidthRatio: 1.10,
    bellyBulgeRatio: 0.0,
  ),
  BottleStyle.crystalDecanter: BottleStyleInfo(
    label: 'Crystal Decanter',
    icon: Icons.diamond_rounded,
    bottomCurveHeight: 45,
    innerBottomCurveHeight: 40,
    tint: Color(0xFFEDE7F6),
    neckWidthRatio: 0.55,
    bellyBulgeRatio: 0.35,
    price: 150,
  ),
  BottleStyle.royalGoblet: BottleStyleInfo(
    label: 'Royal Goblet',
    icon: Icons.emoji_events_rounded,
    bottomCurveHeight: 20,
    innerBottomCurveHeight: 15,
    tint: Color(0xFFFFF3CD),
    neckWidthRatio: 1.35,
    bellyBulgeRatio: 0.0,
    price: 300,
  ),
};

/// Builds the outline of a lab-glass vessel body around a vertical
/// centerline. With [neckWidthRatio] == 1.0 and [bellyBulgeRatio] == 0 this
/// is a plain straight-sided tube with a rounded bottom (the original
/// shape); moving those ratios away from their defaults produces a
/// flask-like silhouette with a narrower/wider neck and/or a bulging
/// belly, so each [BottleStyle] reads as genuinely different glassware
/// rather than the same rectangle with a new tint.
///
/// [topInset] shifts the start/end points down from [top] (used to keep
/// the stroked border clear of the separately-drawn mouth ellipse).
/// [closeTop] controls whether the flat mouth edge is closed off — fill
/// paths want it closed, the stroked border path does not.
Path buildVesselPath({
  required double centerX,
  required double halfWidth,
  required double top,
  required double bottom,
  required double bottomCurveHeight,
  double neckWidthRatio = 1.0,
  double bellyBulgeRatio = 0.0,
  double topInset = 0,
  bool closeTop = true,
}) {
  final double effectiveTop = top + topInset;
  final double neckHalfWidth = halfWidth * neckWidthRatio;
  final double bodyHeight = bottom - effectiveTop;
  final bool hasNeck = (neckWidthRatio - 1.0).abs() > 0.001;
  final bool hasBulge = bellyBulgeRatio > 0.001;
  final double shoulderY =
      hasNeck ? effectiveTop + bodyHeight * 0.18 : effectiveTop;
  final double bulgeY = effectiveTop + bodyHeight * 0.62;
  final double bulgeHalfWidth = halfWidth * (1 + bellyBulgeRatio);
  final double bottomStartY = bottom - bottomCurveHeight;

  final path = Path()..moveTo(centerX - neckHalfWidth, effectiveTop);

  if (hasNeck) {
    path.quadraticBezierTo(
        centerX - halfWidth, effectiveTop, centerX - halfWidth, shoulderY);
  }
  if (hasBulge) {
    path.quadraticBezierTo(
        centerX - bulgeHalfWidth, bulgeY, centerX - halfWidth, bottomStartY);
  } else {
    path.lineTo(centerX - halfWidth, bottomStartY);
  }

  path.quadraticBezierTo(centerX - halfWidth, bottom, centerX, bottom);
  path.quadraticBezierTo(
      centerX + halfWidth, bottom, centerX + halfWidth, bottomStartY);

  if (hasBulge) {
    path.quadraticBezierTo(
        centerX + bulgeHalfWidth, bulgeY, centerX + halfWidth, shoulderY);
  } else {
    path.lineTo(centerX + halfWidth, shoulderY);
  }
  if (hasNeck) {
    path.quadraticBezierTo(
        centerX + halfWidth, effectiveTop, centerX + neckHalfWidth, effectiveTop);
  }
  if (closeTop) path.close();
  return path;
}

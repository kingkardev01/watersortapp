import 'package:flutter/material.dart';

/// Visual style for the bottle/tube glass — purely cosmetic, chosen by
/// the player in Settings. Each style reuses the same liquid/wave/glass
/// rendering logic in BottleComponent, just with different body curve
/// geometry and glass tint so they read as genuinely different vessels.
enum BottleStyle { classicTube, roundFlask, modernGlass }

class BottleStyleInfo {
  final String label;
  final IconData icon;
  final double bottomCurveHeight;
  final double innerBottomCurveHeight;
  final Color tint;

  const BottleStyleInfo({
    required this.label,
    required this.icon,
    required this.bottomCurveHeight,
    required this.innerBottomCurveHeight,
    required this.tint,
  });
}

const Map<BottleStyle, BottleStyleInfo> bottleStyleInfo = {
  BottleStyle.classicTube: BottleStyleInfo(
    label: 'Classic Tube',
    icon: Icons.crop_portrait_rounded,
    bottomCurveHeight: 36,
    innerBottomCurveHeight: 31,
    tint: Colors.white,
  ),
  BottleStyle.roundFlask: BottleStyleInfo(
    label: 'Round Flask',
    icon: Icons.science_rounded,
    bottomCurveHeight: 64,
    innerBottomCurveHeight: 57,
    tint: Color(0xFFEFE9C9),
  ),
  BottleStyle.modernGlass: BottleStyleInfo(
    label: 'Modern Glass',
    icon: Icons.local_bar_rounded,
    bottomCurveHeight: 10,
    innerBottomCurveHeight: 7,
    tint: Color(0xFFCFE9FF),
  ),
};

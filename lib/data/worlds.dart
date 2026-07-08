import 'package:flutter/material.dart';

/// A themed group of 10 levels shown as its own section on the home
/// screen. Purely presentational — the actual difficulty curve lives in
/// [WaterSortGame.numColorsForLevel] / [WaterSortGame.numEmptyBottlesForLevel]
/// and happens to step up every 2 worlds (20 levels).
class GameWorld {
  final String name;
  final int startLevel;
  final int endLevel;
  final IconData icon;
  final List<Color> gradient;
  final Color accent;

  const GameWorld({
    required this.name,
    required this.startLevel,
    required this.endLevel,
    required this.icon,
    required this.gradient,
    required this.accent,
  });

  int get levelCount => endLevel - startLevel + 1;

  bool containsLevel(int level) => level >= startLevel && level <= endLevel;
}

/// Ten worlds of 10 levels each, ramping visually from calm shallow water
/// to deep space as the puzzles get harder — gives players a sense of
/// journey/progression beyond just a flat "Level N" grid.
const List<GameWorld> gameWorlds = [
  GameWorld(
    name: 'Shallow Bay',
    startLevel: 1,
    endLevel: 10,
    icon: Icons.water_drop_rounded,
    gradient: [Color(0xFF6DD5FA), Color(0xFF2E86C1)],
    accent: Color(0xFF2E86C1),
  ),
  GameWorld(
    name: 'Coral Reef',
    startLevel: 11,
    endLevel: 20,
    icon: Icons.waves_rounded,
    gradient: [Color(0xFF36D1C4), Color(0xFF1B8E9A)],
    accent: Color(0xFF1B8E9A),
  ),
  GameWorld(
    name: 'Emerald Lagoon',
    startLevel: 21,
    endLevel: 30,
    icon: Icons.eco_rounded,
    gradient: [Color(0xFF56C596), Color(0xFF1E8A5F)],
    accent: Color(0xFF1E8A5F),
  ),
  GameWorld(
    name: 'Jungle Falls',
    startLevel: 31,
    endLevel: 40,
    icon: Icons.forest_rounded,
    gradient: [Color(0xFF8BC34A), Color(0xFF33691E)],
    accent: Color(0xFF33691E),
  ),
  GameWorld(
    name: 'Canyon Creek',
    startLevel: 41,
    endLevel: 50,
    icon: Icons.terrain_rounded,
    gradient: [Color(0xFFE59866), Color(0xFFA84300)],
    accent: Color(0xFFA84300),
  ),
  GameWorld(
    name: 'Desert Oasis',
    startLevel: 51,
    endLevel: 60,
    icon: Icons.wb_sunny_rounded,
    gradient: [Color(0xFFF6D365), Color(0xFFC98910)],
    accent: Color(0xFFC98910),
  ),
  GameWorld(
    name: 'Volcano Springs',
    startLevel: 61,
    endLevel: 70,
    icon: Icons.local_fire_department_rounded,
    gradient: [Color(0xFFFF8A65), Color(0xFFB71C1C)],
    accent: Color(0xFFB71C1C),
  ),
  GameWorld(
    name: 'Glacier Bay',
    startLevel: 71,
    endLevel: 80,
    icon: Icons.ac_unit_rounded,
    gradient: [Color(0xFFAEE7FF), Color(0xFF4A7FBF)],
    accent: Color(0xFF4A7FBF),
  ),
  GameWorld(
    name: 'Aurora Peaks',
    startLevel: 81,
    endLevel: 90,
    icon: Icons.nightlight_round,
    gradient: [Color(0xFFB39DDB), Color(0xFF512DA8)],
    accent: Color(0xFF512DA8),
  ),
  GameWorld(
    name: 'Galaxy Core',
    startLevel: 91,
    endLevel: 100,
    icon: Icons.auto_awesome_rounded,
    gradient: [Color(0xFF6A5ACD), Color(0xFF1A0F4D)],
    accent: Color(0xFF1A0F4D),
  ),
];

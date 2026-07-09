import 'package:flutter/material.dart';

/// What stat an [Achievement]'s [Achievement.target] is measured against.
/// Kept as data (not a closure) so the achievement list stays a plain
/// `const` table — [AchievementController] does the actual lookup against
/// the other controllers for whichever metric an achievement uses.
enum AchievementMetric {
  levelsCompleted,
  threeStarLevels,
  worldsCompleted,
  loginStreak,
  totalCoinsEarned,
  bottleStylesOwned,
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final AchievementMetric metric;
  final int target;
  final int coinReward;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.metric,
    required this.target,
    required this.coinReward,
  });
}

/// Every achievement in the game, roughly ordered by how soon a typical
/// player reaches it. IDs are persisted in storage, so treat them as
/// stable once shipped — rename [Achievement.title] freely, never [id].
const List<Achievement> allAchievements = [
  Achievement(
    id: 'first_splash',
    title: 'First Splash',
    description: 'Complete your first level',
    icon: Icons.water_drop_rounded,
    metric: AchievementMetric.levelsCompleted,
    target: 1,
    coinReward: 20,
  ),
  Achievement(
    id: 'getting_the_hang_of_it',
    title: 'Getting the Hang of It',
    description: 'Complete 10 levels',
    icon: Icons.checklist_rounded,
    metric: AchievementMetric.levelsCompleted,
    target: 10,
    coinReward: 40,
  ),
  Achievement(
    id: 'halfway_there',
    title: 'Halfway There',
    description: 'Complete 50 levels',
    icon: Icons.trending_up_rounded,
    metric: AchievementMetric.levelsCompleted,
    target: 50,
    coinReward: 100,
  ),
  Achievement(
    id: 'puzzle_master',
    title: 'Puzzle Master',
    description: 'Complete all 100 levels',
    icon: Icons.emoji_events_rounded,
    metric: AchievementMetric.levelsCompleted,
    target: 100,
    coinReward: 300,
  ),
  Achievement(
    id: 'sharp_mind',
    title: 'Sharp Mind',
    description: 'Earn 3 stars on 10 levels',
    icon: Icons.star_rounded,
    metric: AchievementMetric.threeStarLevels,
    target: 10,
    coinReward: 60,
  ),
  Achievement(
    id: 'flawless',
    title: 'Flawless',
    description: 'Earn 3 stars on 50 levels',
    icon: Icons.auto_awesome_rounded,
    metric: AchievementMetric.threeStarLevels,
    target: 50,
    coinReward: 150,
  ),
  Achievement(
    id: 'bay_explorer',
    title: 'Bay Explorer',
    description: 'Complete the Shallow Bay world',
    icon: Icons.explore_rounded,
    metric: AchievementMetric.worldsCompleted,
    target: 1,
    coinReward: 30,
  ),
  Achievement(
    id: 'world_conqueror',
    title: 'World Conqueror',
    description: 'Complete all 10 worlds',
    icon: Icons.public_rounded,
    metric: AchievementMetric.worldsCompleted,
    target: 10,
    coinReward: 400,
  ),
  Achievement(
    id: 'streak_starter',
    title: 'Streak Starter',
    description: 'Reach a 3-day login streak',
    icon: Icons.local_fire_department_rounded,
    metric: AchievementMetric.loginStreak,
    target: 3,
    coinReward: 30,
  ),
  Achievement(
    id: 'week_streak',
    title: 'Week Streak',
    description: 'Reach a 7-day login streak',
    icon: Icons.whatshot_rounded,
    metric: AchievementMetric.loginStreak,
    target: 7,
    coinReward: 100,
  ),
  Achievement(
    id: 'coin_collector',
    title: 'Coin Collector',
    description: 'Earn 500 coins in total',
    icon: Icons.monetization_on_rounded,
    metric: AchievementMetric.totalCoinsEarned,
    target: 500,
    coinReward: 50,
  ),
  Achievement(
    id: 'coin_hoarder',
    title: 'Coin Hoarder',
    description: 'Earn 2000 coins in total',
    icon: Icons.savings_rounded,
    metric: AchievementMetric.totalCoinsEarned,
    target: 2000,
    coinReward: 150,
  ),
  Achievement(
    id: 'fashionista',
    title: 'Fashionista',
    description: 'Own 3 bottle styles',
    icon: Icons.checkroom_rounded,
    metric: AchievementMetric.bottleStylesOwned,
    target: 3,
    coinReward: 50,
  ),
  Achievement(
    id: 'glassware_collector',
    title: 'Glassware Collector',
    description: 'Own every bottle style',
    icon: Icons.diamond_rounded,
    metric: AchievementMetric.bottleStylesOwned,
    target: 5, // BottleStyle.values.length — update if a style is added/removed
    coinReward: 100,
  ),
];

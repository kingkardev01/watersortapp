import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:watersortapp/controllers/coin_controller.dart';
import 'package:watersortapp/controllers/daily_reward_controller.dart';
import 'package:watersortapp/controllers/level_controller.dart';
import 'package:watersortapp/controllers/shop_controller.dart';
import 'package:watersortapp/data/worlds.dart';
import 'package:watersortapp/game_screen.dart';
import 'package:watersortapp/models/achievement.dart';

/// Tracks which achievements have been unlocked and grants their coin
/// reward the moment their criteria are met. Progress is derived live from
/// the other controllers (levels completed, streak, coins earned, styles
/// owned) rather than duplicated here — call [checkAll] after any
/// stat-changing event (level win, daily claim, style purchase); it's cheap
/// and safe to call as often as you like.
class AchievementController extends GetxController {
  final box = GetStorage();

  final RxSet<String> unlockedIds = <String>{}.obs;

  bool _toastShowing = false;
  final List<Achievement> _toastQueue = [];

  @override
  void onInit() {
    super.onInit();
    final List<dynamic>? stored = box.read('unlockedAchievements');
    if (stored != null) {
      unlockedIds.addAll(stored.map((e) => e.toString()));
    }
  }

  bool isUnlocked(String id) => unlockedIds.contains(id);

  /// Current progress toward [achievement], clamped to its target so UI
  /// progress bars never overshoot 100%.
  int progressFor(Achievement achievement) =>
      _progress(achievement).clamp(0, achievement.target);

  void checkAll() {
    final List<Achievement> newlyUnlocked = [];
    // Loop so a reward from one achievement (extra coins) can immediately
    // satisfy another (e.g. a coin-total milestone) in the same pass.
    bool changed = true;
    while (changed) {
      changed = false;
      for (final achievement in allAchievements) {
        if (unlockedIds.contains(achievement.id)) continue;
        if (_progress(achievement) >= achievement.target) {
          unlockedIds.add(achievement.id);
          newlyUnlocked.add(achievement);
          if (achievement.coinReward > 0) {
            Get.find<CoinController>().addCoins(achievement.coinReward);
          }
          changed = true;
        }
      }
    }
    if (newlyUnlocked.isNotEmpty) {
      box.write('unlockedAchievements', unlockedIds.toList());
      _toastQueue.addAll(newlyUnlocked);
      _showNextToast();
    }
  }

  void _showNextToast() {
    if (_toastShowing || _toastQueue.isEmpty) return;
    _toastShowing = true;
    final achievement = _toastQueue.removeAt(0);
    Get.snackbar(
      'Achievement Unlocked!',
      '${achievement.title} · +${achievement.coinReward} coins',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.amber.shade600,
      colorText: Colors.white,
      icon: Icon(achievement.icon, color: Colors.white),
      margin: const EdgeInsets.all(14),
      borderRadius: 16,
      duration: const Duration(seconds: 3),
      isDismissible: true,
    ).future.whenComplete(() {
      _toastShowing = false;
      _showNextToast();
    });
  }

  int _progress(Achievement achievement) {
    switch (achievement.metric) {
      case AchievementMetric.levelsCompleted:
        return _levelsCompleted();
      case AchievementMetric.threeStarLevels:
        return _threeStarLevels();
      case AchievementMetric.worldsCompleted:
        return _worldsCompleted();
      case AchievementMetric.loginStreak:
        return _loginStreak();
      case AchievementMetric.totalCoinsEarned:
        return Get.find<CoinController>().totalEarned.value;
      case AchievementMetric.bottleStylesOwned:
        return Get.find<ShopController>().ownedStyles.length;
    }
  }

  int _levelsCompleted() {
    final lc = Get.find<LevelController>();
    int count = 0;
    for (int level = 1; level <= 100; level++) {
      if (lc.isLevelCompleted(level)) count++;
    }
    return count;
  }

  int _threeStarLevels() {
    final lc = Get.find<LevelController>();
    int count = 0;
    for (int level = 1; level <= 100; level++) {
      if (!lc.isLevelCompleted(level)) continue;
      if (WaterSortGame.starRating(level, lc.getBestScore(level)) == 3) {
        count++;
      }
    }
    return count;
  }

  int _worldsCompleted() {
    final lc = Get.find<LevelController>();
    int count = 0;
    for (final world in gameWorlds) {
      bool complete = true;
      for (int level = world.startLevel; level <= world.endLevel; level++) {
        if (!lc.isLevelCompleted(level)) {
          complete = false;
          break;
        }
      }
      if (complete) count++;
    }
    return count;
  }

  /// The longest login streak currently held: [DailyRewardController.currentDay]
  /// once today's reward is claimed, or one less than that while today's
  /// claim is still outstanding (the streak so far only covers days already
  /// claimed).
  int _loginStreak() {
    final dr = Get.find<DailyRewardController>();
    return dr.claimedToday.value
        ? dr.currentDay.value
        : dr.currentDay.value - 1;
  }
}

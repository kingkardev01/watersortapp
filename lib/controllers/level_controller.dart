import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class LevelController extends GetxController {
  final box = GetStorage();
  final RxInt unlockedLevels = 1.obs;

  // Map of level -> best move count (0 = not completed)
  final RxMap<int, int> bestScores = <int, int>{}.obs;

  @override
  void onInit() {
    super.onInit();
    loadUnlockedLevels();
    _loadBestScores();
  }

  void loadUnlockedLevels() {
    unlockedLevels.value = box.read('unlockedLevels') ?? 1;
  }

  void saveUnlockedLevels(int levels) {
    unlockedLevels.value = levels;
    box.write('unlockedLevels', levels);
  }

  void unlockNextLevel() {
    if (unlockedLevels.value < 100) {
      saveUnlockedLevels(unlockedLevels.value + 1);
    }
  }

  bool isLevelUnlocked(int level) {
    return level <= unlockedLevels.value;
  }

  bool isLevelCompleted(int level) {
    return bestScores.containsKey(level) && bestScores[level]! > 0;
  }

  int getBestScore(int level) {
    return bestScores[level] ?? 0;
  }

  /// Save best score for a level (only if it's better than existing)
  void saveBestScore(int level, int moves) {
    final existing = bestScores[level] ?? 0;
    if (existing == 0 || moves < existing) {
      bestScores[level] = moves;
      final Map<String, dynamic> stored = Map<String, dynamic>.from(
        box.read('bestScores') ?? {},
      );
      stored[level.toString()] = moves;
      box.write('bestScores', stored);
    }
  }

  /// Wipes all saved progress — unlocked levels and best scores.
  void resetProgress() {
    unlockedLevels.value = 1;
    bestScores.clear();
    box.remove('unlockedLevels');
    box.remove('bestScores');
  }

  void _loadBestScores() {
    final Map<dynamic, dynamic>? stored = box.read('bestScores');
    if (stored != null) {
      for (final entry in stored.entries) {
        final level = int.tryParse(entry.key.toString());
        final score = entry.value as int?;
        if (level != null && score != null) {
          bestScores[level] = score;
        }
      }
    }
  }
}

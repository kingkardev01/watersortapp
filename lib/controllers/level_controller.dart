import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class LevelController extends GetxController {
  final box = GetStorage();
  final RxInt unlockedLevels = 1.obs;

  @override
  void onInit() {
    super.onInit();
    loadUnlockedLevels();
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
}
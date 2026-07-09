import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

/// Tracks the player's coin balance, earned by clearing levels. Coins are
/// credited automatically on level win (see [WaterSortGame.starRating]-based
/// reward in game_screen.dart) — there's no separate claim step.
class CoinController extends GetxController {
  final box = GetStorage();
  final RxInt coins = 0.obs;

  /// Lifetime coins earned, independent of [coins] (which drops on spend).
  /// Exists purely for "earn N coins total" achievements.
  final RxInt totalEarned = 0.obs;

  /// Coins awarded for a level clear, scaled by star rating so cleaner
  /// solves are worth more.
  static int rewardForStars(int stars) => 10 + stars * 10;

  @override
  void onInit() {
    super.onInit();
    coins.value = box.read('coins') ?? 0;
    totalEarned.value = box.read('totalCoinsEarned') ?? 0;
  }

  void addCoins(int amount) {
    if (amount <= 0) return;
    coins.value += amount;
    totalEarned.value += amount;
    box.write('coins', coins.value);
    box.write('totalCoinsEarned', totalEarned.value);
  }

  /// Deducts [amount] coins if the balance covers it. Returns whether the
  /// spend went through, so callers can gate a purchase on the result
  /// instead of checking the balance separately beforehand.
  bool spendCoins(int amount) {
    if (amount <= 0 || coins.value < amount) return false;
    coins.value -= amount;
    box.write('coins', coins.value);
    return true;
  }
}

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:watersortapp/controllers/coin_controller.dart';
import 'package:watersortapp/models/bottle_style.dart';

/// Gives the coin economy somewhere to spend: hint/undo consumables and
/// unlockable bottle styles. Coins themselves stay owned by
/// [CoinController]; this controller just knows the prices and inventory.
class ShopController extends GetxController {
  final box = GetStorage();

  static const int startingHints = 3;
  static const int startingUndos = 5;

  static const int hintPackSize = 5;
  static const int hintPackPrice = 60;
  static const int undoPackSize = 5;
  static const int undoPackPrice = 40;

  final RxInt hintTokens = startingHints.obs;
  final RxInt undoTokens = startingUndos.obs;
  final RxSet<BottleStyle> ownedStyles = <BottleStyle>{}.obs;

  @override
  void onInit() {
    super.onInit();
    hintTokens.value = box.read('hintTokens') ?? startingHints;
    undoTokens.value = box.read('undoTokens') ?? startingUndos;

    final List<dynamic>? storedOwned = box.read('ownedStyles');
    if (storedOwned != null) {
      ownedStyles.addAll(
        storedOwned
            .map((i) => BottleStyle.values[i as int])
            .where((s) => bottleStyleInfo[s] != null),
      );
    }
    // Free styles are always owned, regardless of what was persisted.
    ownedStyles.addAll(
      BottleStyle.values.where((s) => bottleStyleInfo[s]!.price == 0),
    );
  }

  bool isOwned(BottleStyle style) => ownedStyles.contains(style);

  void _persistOwned() {
    box.write('ownedStyles', ownedStyles.map((s) => s.index).toList());
  }

  /// Spends coins to unlock [style]. Returns true on success.
  bool unlockStyle(BottleStyle style) {
    if (isOwned(style)) return true;
    final int price = bottleStyleInfo[style]!.price;
    if (!Get.find<CoinController>().spendCoins(price)) return false;
    ownedStyles.add(style);
    _persistOwned();
    return true;
  }

  bool buyHintPack() {
    if (!Get.find<CoinController>().spendCoins(hintPackPrice)) return false;
    hintTokens.value += hintPackSize;
    box.write('hintTokens', hintTokens.value);
    return true;
  }

  bool buyUndoPack() {
    if (!Get.find<CoinController>().spendCoins(undoPackPrice)) return false;
    undoTokens.value += undoPackSize;
    box.write('undoTokens', undoTokens.value);
    return true;
  }

  /// Consumes one hint token. Call only once a hint has actually been
  /// shown (see [WaterSortGame.onHintUsed]) so a no-op tap never costs one.
  void useHint() {
    if (hintTokens.value <= 0) return;
    hintTokens.value -= 1;
    box.write('hintTokens', hintTokens.value);
  }

  bool get canUndo => undoTokens.value > 0;

  void useUndo() {
    if (undoTokens.value <= 0) return;
    undoTokens.value -= 1;
    box.write('undoTokens', undoTokens.value);
  }
}

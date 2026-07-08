import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:watersortapp/models/bottle_style.dart';

class SettingsController extends GetxController {
  final box = GetStorage();

  final RxBool soundEnabled = true.obs;
  final RxBool hapticsEnabled = true.obs;
  final RxBool largeText = false.obs;
  final Rx<BottleStyle> bottleStyle = BottleStyle.classicTube.obs;

  /// App-wide text scale applied via MediaQuery — larger for players who
  /// benefit from bigger, easier-to-read text (kids and seniors).
  double get textScaleFactor => largeText.value ? 1.2 : 1.0;

  @override
  void onInit() {
    super.onInit();
    soundEnabled.value = box.read('soundEnabled') ?? true;
    hapticsEnabled.value = box.read('hapticsEnabled') ?? true;
    largeText.value = box.read('largeText') ?? false;

    final int? savedStyleIndex = box.read('bottleStyle');
    if (savedStyleIndex != null &&
        savedStyleIndex >= 0 &&
        savedStyleIndex < BottleStyle.values.length) {
      bottleStyle.value = BottleStyle.values[savedStyleIndex];
    }
  }

  void toggleSound(bool value) {
    soundEnabled.value = value;
    box.write('soundEnabled', value);
  }

  void toggleHaptics(bool value) {
    hapticsEnabled.value = value;
    box.write('hapticsEnabled', value);
  }

  void toggleLargeText(bool value) {
    largeText.value = value;
    box.write('largeText', value);
  }

  void setBottleStyle(BottleStyle style) {
    bottleStyle.value = style;
    box.write('bottleStyle', style.index);
  }
}

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:watersortapp/models/bottle_style.dart';

class SettingsController extends GetxController {
  final box = GetStorage();

  final RxBool soundEnabled = true.obs;
  final RxBool hapticsEnabled = true.obs;
  final Rx<BottleStyle> bottleStyle = BottleStyle.classicTube.obs;

  @override
  void onInit() {
    super.onInit();
    soundEnabled.value = box.read('soundEnabled') ?? true;
    hapticsEnabled.value = box.read('hapticsEnabled') ?? true;

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

  void setBottleStyle(BottleStyle style) {
    bottleStyle.value = style;
    box.write('bottleStyle', style.index);
  }
}

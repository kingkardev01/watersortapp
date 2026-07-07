import 'dart:convert';
import 'dart:typed_data';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image_picker/image_picker.dart';

class ProfileController extends GetxController {
  final box = GetStorage();
  final ImagePicker _picker = ImagePicker();

  final RxString userName = 'Player'.obs;
  final Rx<Uint8List?> profileImageBytes = Rx<Uint8List?>(null);

  @override
  void onInit() {
    super.onInit();
    userName.value = box.read('userName') ?? 'Player';

    final String? storedImage = box.read('profileImageBase64');
    if (storedImage != null) {
      try {
        profileImageBytes.value = base64Decode(storedImage);
      } catch (_) {
        // Corrupt/legacy data — ignore and fall back to the default avatar.
      }
    }
  }

  void setUserName(String name) {
    final String trimmed = name.trim();
    userName.value = trimmed.isEmpty ? 'Player' : trimmed;
    box.write('userName', userName.value);
  }

  Future<void> pickProfileImage() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (picked == null) return;

    final Uint8List bytes = await picked.readAsBytes();
    profileImageBytes.value = bytes;
    box.write('profileImageBase64', base64Encode(bytes));
  }

  void removeProfileImage() {
    profileImageBytes.value = null;
    box.remove('profileImageBase64');
  }
}

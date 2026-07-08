import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:watersortapp/controllers/coin_controller.dart';
import 'package:watersortapp/controllers/profile_controller.dart';
import 'package:watersortapp/controllers/settings_controller.dart';
import 'package:watersortapp/controllers/shop_controller.dart';
import 'package:watersortapp/splash_screen.dart';
import 'package:watersortapp/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  Get.put(SettingsController());
  Get.put(ProfileController());
  Get.put(CoinController());
  Get.put(ShopController());
  runApp(const WaterSortApp());
}

class WaterSortApp extends StatelessWidget {
  const WaterSortApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Get.find<SettingsController>();
    return GetMaterialApp(
      title: 'SortPuz - Water Sort Puzzle',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.themeData,
      home: const SplashScreen(),
      builder: (context, child) {
        return Obx(
          () => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(settings.textScaleFactor),
            ),
            child: child!,
          ),
        );
      },
    );
  }
}


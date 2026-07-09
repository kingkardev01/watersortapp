import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:watersortapp/controllers/coin_controller.dart';

/// A repeating 7-day login streak. Claiming today advances tomorrow's day;
/// missing a day (no claim yesterday) resets the streak back to day 1.
class DailyRewardController extends GetxController {
  final box = GetStorage();

  static const List<int> dayRewards = [20, 30, 40, 50, 70, 90, 150];

  /// Which day (1..dayRewards.length) is currently up for grabs.
  final RxInt currentDay = 1.obs;
  final RxBool claimedToday = false.obs;

  @override
  void onInit() {
    super.onInit();
    final int savedDay = box.read('dailyCurrentDay') ?? 1;
    final String? lastClaimDate = box.read('dailyLastClaim');
    final String today = _dateKey(DateTime.now());
    final String yesterday =
        _dateKey(DateTime.now().subtract(const Duration(days: 1)));

    if (lastClaimDate == today) {
      currentDay.value = savedDay;
      claimedToday.value = true;
    } else if (lastClaimDate == yesterday) {
      currentDay.value = savedDay >= dayRewards.length ? 1 : savedDay + 1;
      claimedToday.value = false;
    } else {
      // First run, or a day (or more) was missed — restart the streak.
      currentDay.value = 1;
      claimedToday.value = false;
    }
    box.write('dailyCurrentDay', currentDay.value);
  }

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  int rewardForDay(int day) => dayRewards[day - 1];

  int get todaysReward => rewardForDay(currentDay.value);

  bool get canClaim => !claimedToday.value;

  /// Claims today's reward and credits coins. Returns the amount granted,
  /// or 0 if today's reward was already claimed.
  int claim() {
    if (claimedToday.value) return 0;
    final int reward = todaysReward;
    Get.find<CoinController>().addCoins(reward);
    claimedToday.value = true;
    box.write('dailyLastClaim', _dateKey(DateTime.now()));
    box.write('dailyCurrentDay', currentDay.value);
    return reward;
  }
}

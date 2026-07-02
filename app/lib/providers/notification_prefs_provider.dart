import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final notificationsEnabledProvider =
    AsyncNotifierProvider<NotificationsEnabledNotifier, bool>(
  NotificationsEnabledNotifier.new,
);

class NotificationsEnabledNotifier extends AsyncNotifier<bool> {
  static const _kKey = 'settings_notifications_enabled';

  @override
  Future<bool> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kKey) ?? true; // default: açık
  }

  Future<void> setEnabled(bool v) async {
    state = AsyncData(v);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kKey, v);
  }
}

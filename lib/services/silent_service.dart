import 'dart:async';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/prayer_time.dart';

class SilentService {
  static const MethodChannel _channel = MethodChannel('com.masjidsilentmode/silent');

  static const String _keyWasSilent = 'wasSilentActive';
  static const String _keyPreviousMode = 'previousRingerMode';

  static Future<bool> hasPolicyAccess() async {
    final result = await _channel.invokeMethod<bool>('checkPolicyAccess');
    return result ?? false;
  }

  static Future<void> openPolicySettings() async {
    await _channel.invokeMethod<void>('openPolicySettings');
  }

  static Future<int> _getCurrentRingerMode() async {
    final result = await _channel.invokeMethod<int>('getRingerMode');
    return result ?? 2; // Normal mode fallback.
  }

  static Future<void> _setRingerMode(int mode) async {
    await _channel.invokeMethod<void>('setRingerMode', {'mode': mode});
  }

  static Future<void> _setDndEnabled(bool enabled) async {
    await _channel.invokeMethod<void>('setDnd', {'enabled': enabled});
  }

  static bool _isWithinWindow(DateTime now, PrayerTime time) {
    final minutes = now.hour * 60 + now.minute;
    return minutes >= time.startMinutes && minutes <= time.endMinutes;
  }

  static Future<void> checkAndToggle(List<PrayerTime> prayerTimes) async {
    final now = DateTime.now();
    final shouldBeSilent = prayerTimes.any((time) => _isWithinWindow(now, time));

    final prefs = await SharedPreferences.getInstance();
    final wasSilent = prefs.getBool(_keyWasSilent) ?? false;

    if (shouldBeSilent && !wasSilent) {
      // Save previous state before switching to silent.
      final currentMode = await _getCurrentRingerMode();
      await prefs.setInt(_keyPreviousMode, currentMode);
      await _setDndEnabled(true);
      await prefs.setBool(_keyWasSilent, true);
    } else if (!shouldBeSilent && wasSilent) {
      final previousMode = prefs.getInt(_keyPreviousMode) ?? 2;
      await _setDndEnabled(false);
      await _setRingerMode(previousMode);
      await prefs.setBool(_keyWasSilent, false);
    }
  }

  // Optional in-app ticker for minute-by-minute updates while the UI is open.
  static Timer startForegroundTicker(List<PrayerTime> prayerTimes) {
    return Timer.periodic(const Duration(minutes: 1), (_) {
      checkAndToggle(prayerTimes);
    });
  }
}
